import Foundation
import SceneKit
import UIKit
import simd

final class ShapeController {
    let scene: SCNScene
    private let cameraNode: SCNNode
    private var activeShape: ShapeInstance?
    private(set) var stage: Stage
    private(set) var mode: GameMode
    private let minimumPieceShareForCut = 0.25

    private struct ShapeInstance {
        let node: SCNNode
        let mesh: Mesh
    }

    private static let baseColor = UIColor(red: 0.78, green: 0.72, blue: 0.95, alpha: 1.0)
    private static let capColor = UIColor(red: 0.95, green: 0.90, blue: 1.00, alpha: 1.0)

    init(stage: Stage, mode: GameMode) {
        self.stage = stage
        self.mode = mode
        self.scene = SCNScene()
        scene.background.contents = UIColor.clear

        let camera = SCNNode()
        camera.camera = SCNCamera()
        camera.position = SCNVector3(0, 0, 4)
        scene.rootNode.addChildNode(camera)
        self.cameraNode = camera

        loadInitialShape()
    }

    func setStage(_ newStage: Stage, mode newMode: GameMode) {
        self.stage = newStage
        self.mode = newMode
        loadInitialShape()
    }

    func loadInitialShape() {
        for node in scene.rootNode.childNodes where node !== cameraNode {
            node.removeAllActions()
            node.removeFromParentNode()
        }

        let mesh = Self.mesh(for: stage.shapeType)
        let node = Self.makeBodyNode(from: mesh)
        if mode == .hard {
            node.simdEulerAngles = randomInitialEulerAngles()
        }
        if mode.rotatesShape {
            node.runAction(rotateAction(for: stage), forKey: "rotate")
        }
        scene.rootNode.addChildNode(node)
        activeShape = ShapeInstance(node: node, mesh: mesh)
    }

    func currentOrientation() -> simd_quatf? {
        guard let node = activeShape?.node else { return nil }
        return node.simdOrientation
    }

    func setOrientation(_ orientation: simd_quatf) {
        guard let node = activeShape?.node else { return }
        node.simdOrientation = orientation
    }

    func cut(along worldPlane: Plane) -> CutStats? {
        guard let shape = activeShape else { return nil }

        shape.node.removeAction(forKey: "rotate")
        let snapshot = shape.node.presentation.simdTransform
        shape.node.simdTransform = snapshot

        let inverse = simd_inverse(snapshot)
        let localPlane = worldPlane.transformed(by: inverse)

        let (pos, neg) = MeshCutter.cut(shape.mesh, with: localPlane)

        if pos.body.triangleCount == 0 || neg.body.triangleCount == 0 {
            if mode.rotatesShape {
                shape.node.runAction(rotateAction(for: stage), forKey: "rotate")
            }
            return nil
        }

        let posMesh = pos.closedMesh
        let negMesh = neg.closedMesh
        let posVol = Double(VolumeCalculator.volume(of: posMesh))
        let negVol = Double(VolumeCalculator.volume(of: negMesh))
        let total = posVol + negVol
        guard total > 0, min(posVol, negVol) / total >= minimumPieceShareForCut else {
            if mode.rotatesShape {
                shape.node.runAction(rotateAction(for: stage), forKey: "rotate")
            }
            return nil
        }

        let stats = CutStats(
            leftPercent: posVol / total * 100,
            rightPercent: negVol / total * 100
        )

        shape.node.removeFromParentNode()
        activeShape = nil

        let posNode = Self.makePieceNode(from: pos, grade: stats.grade)
        let negNode = Self.makePieceNode(from: neg, grade: stats.grade)
        posNode.simdTransform = snapshot
        negNode.simdTransform = snapshot
        scene.rootNode.addChildNode(posNode)
        scene.rootNode.addChildNode(negNode)

        playSeparation(posNode: posNode, negNode: negNode, plane: worldPlane, grade: stats.grade)
        playHaptic(for: stats)

        return stats
    }

    func canCut(from start: CGPoint, to end: CGPoint, in view: SCNView) -> Bool {
        guard let shape = activeShape else { return false }
        return SwipeToPlaneConverter.coversProjectedMesh(
            shape.mesh,
            node: shape.node.presentation,
            from: start,
            to: end,
            in: view
        )
    }

    func rotateActiveShape(by delta: CGPoint) {
        guard let node = activeShape?.node else { return }
        let sensitivity: Float = 0.008
        let cameraTransform = cameraNode.presentation.simdWorldTransform
        let cameraRight = simd_normalize(SIMD3<Float>(
            cameraTransform.columns.0.x,
            cameraTransform.columns.0.y,
            cameraTransform.columns.0.z
        ))
        let cameraUp = simd_normalize(SIMD3<Float>(
            cameraTransform.columns.1.x,
            cameraTransform.columns.1.y,
            cameraTransform.columns.1.z
        ))
        let horizontal = simd_quatf(angle: Float(delta.x) * sensitivity, axis: cameraUp)
        let vertical = simd_quatf(angle: Float(delta.y) * sensitivity, axis: cameraRight)
        node.simdOrientation = horizontal * vertical * node.simdOrientation
    }

    // MARK: - Effects

    private func playSeparation(posNode: SCNNode, negNode: SCNNode, plane: Plane, grade: Grade) {
        let separation: Float
        switch grade {
        case .divine:  separation = 1.3
        case .perfect: separation = 1.0
        default:       separation = 0.6
        }
        let offset = plane.normal * separation
        let posOffset = SCNVector3(offset.x, offset.y, offset.z)
        let negOffset = SCNVector3(-offset.x, -offset.y, -offset.z)

        switch grade {
        case .divine:
            // Phase 1: 더 긴 hitstop
            let pause = SCNAction.wait(duration: 0.3)
            // Phase 2-4: 3단 떨림 — 속삭임 → 울림 → 폭발
            let whisper = makeTremble(duration: 0.4, amplitude: 0.012)
            let rumble  = makeTremble(duration: 0.6, amplitude: 0.028)
            let violent = makeTremble(duration: 0.8, amplitude: 0.052)
            // Phase 5: 더블 펄스 — 작은 펄스 → 짧은 정적 → 큰 펄스
            let pulse1Up = SCNAction.scale(to: 1.08, duration: 0.12)
            pulse1Up.timingMode = .easeOut
            let pulse1Down = SCNAction.scale(to: 1.0, duration: 0.10)
            pulse1Down.timingMode = .easeIn
            let pulseGap = SCNAction.wait(duration: 0.08)
            let pulse2Up = SCNAction.scale(to: 1.16, duration: 0.13)
            pulse2Up.timingMode = .easeOut
            let pulse2Down = SCNAction.scale(to: 1.0, duration: 0.18)
            pulse2Down.timingMode = .easeIn
            let pulse = SCNAction.sequence([pulse1Up, pulse1Down, pulseGap, pulse2Up, pulse2Down])
            // Phase 6: 대서사 분리 + 회전
            let pushDuration: TimeInterval = 3.0
            let pushPos = SCNAction.move(by: posOffset, duration: pushDuration)
            let pushNeg = SCNAction.move(by: negOffset, duration: pushDuration)
            pushPos.timingMode = .easeInEaseOut
            pushNeg.timingMode = .easeInEaseOut
            let spinPos = SCNAction.rotateBy(x: 0.12, y: 0.25, z: 0.08, duration: pushDuration)
            let spinNeg = SCNAction.rotateBy(x: -0.12, y: -0.25, z: -0.08, duration: pushDuration)
            let pushGroupPos = SCNAction.group([pushPos, spinPos])
            let pushGroupNeg = SCNAction.group([pushNeg, spinNeg])

            let playDivine = Self.soundAction(.divine)
            posNode.runAction(.sequence([pause, whisper, rumble, violent, pulse, playDivine, pushGroupPos]))
            negNode.runAction(.sequence([pause, whisper, rumble, violent, pulse, pushGroupNeg]))

            // 카메라 줌: 절단 직후 안쪽으로 당겨지고 분리 구간에 다시 빠짐
            let zoomIn = SCNAction.moveBy(x: 0, y: 0, z: -0.4, duration: 2.1)
            zoomIn.timingMode = .easeInEaseOut
            let zoomHold = SCNAction.wait(duration: 0.4)
            let zoomOut = SCNAction.moveBy(x: 0, y: 0, z: 0.4, duration: 3.0)
            zoomOut.timingMode = .easeInEaseOut
            cameraNode.runAction(.sequence([zoomIn, zoomHold, zoomOut]))

        case .perfect:
            // 기존 DIVINE 시퀀스를 PERFECT로 승격
            let pause = SCNAction.wait(duration: 0.2)
            let gentle = makeTremble(duration: 0.5, amplitude: 0.014)
            let violent = makeTremble(duration: 0.7, amplitude: 0.038)
            let pulseUp = SCNAction.scale(to: 1.08, duration: 0.1)
            pulseUp.timingMode = .easeOut
            let pulseDown = SCNAction.scale(to: 1.0, duration: 0.2)
            pulseDown.timingMode = .easeIn
            let pulse = SCNAction.sequence([pulseUp, pulseDown])
            let pushPos = SCNAction.move(by: posOffset, duration: 2.5)
            let pushNeg = SCNAction.move(by: negOffset, duration: 2.5)
            pushPos.timingMode = .easeInEaseOut
            pushNeg.timingMode = .easeInEaseOut

            let playDivine = Self.soundAction(.divine)
            posNode.runAction(.sequence([pause, gentle, violent, pulse, playDivine, pushPos]))
            negNode.runAction(.sequence([pause, gentle, violent, pulse, pushNeg]))

        case .great, .good, .close, .miss:
            let pushPos = SCNAction.move(by: posOffset, duration: 0.5)
            let pushNeg = SCNAction.move(by: negOffset, duration: 0.5)
            pushPos.timingMode = .easeOut
            pushNeg.timingMode = .easeOut
            posNode.runAction(pushPos)
            negNode.runAction(pushNeg)
        }
    }

    private static func soundAction(_ effect: SoundEffect) -> SCNAction {
        SCNAction.run { _ in
            DispatchQueue.main.async {
                SoundManager.shared.playEffect(effect)
            }
        }
    }

    private func makeTremble(duration: TimeInterval, amplitude: Float) -> SCNAction {
        let stepCount = 14
        let stepDur = duration / Double(stepCount) / 2
        var steps: [SCNAction] = []
        for _ in 0..<stepCount {
            let dx = Float.random(in: -amplitude...amplitude)
            let dy = Float.random(in: -amplitude...amplitude)
            let dz = Float.random(in: -amplitude...amplitude)
            steps.append(SCNAction.move(by: SCNVector3(dx, dy, dz), duration: stepDur))
            steps.append(SCNAction.move(by: SCNVector3(-dx, -dy, -dz), duration: stepDur))
        }
        return SCNAction.sequence(steps)
    }

    private func playHaptic(for stats: CutStats) {
        guard UserDefaults.standard.object(forKey: "perfect_split.settings.haptics") as? Bool ?? true else {
            return
        }

        switch stats.grade {
        case .divine:
            // 첫 충격
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()

            // 1단 속삭임 (t=0.30 ~ 0.70): 아주 약한 럼블
            let whisper = UIImpactFeedbackGenerator(style: .soft)
            whisper.prepare()
            for i in 0..<6 {
                let delay = 0.30 + Double(i) * 0.067
                let intensity = CGFloat(0.2 + Double(i) / 5 * 0.2)
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    whisper.impactOccurred(intensity: intensity)
                }
            }

            // 2단 울림 (t=0.70 ~ 1.30): 부드러운 럼블 확장
            let rumble = UIImpactFeedbackGenerator(style: .soft)
            rumble.prepare()
            for i in 0..<9 {
                let delay = 0.70 + Double(i) * 0.067
                let intensity = CGFloat(0.45 + Double(i) / 8 * 0.35)
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    rumble.impactOccurred(intensity: intensity)
                }
            }

            // 3단 폭발 (t=1.30 ~ 2.10): 묵직한 럼블 최대치
            let violent = UIImpactFeedbackGenerator(style: .medium)
            violent.prepare()
            for i in 0..<12 {
                let delay = 1.30 + Double(i) * 0.067
                let intensity = CGFloat(0.7 + Double(i) / 11 * 0.3)
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    violent.impactOccurred(intensity: intensity)
                }
            }

            // 펄스 1 임팩트 (t=2.10)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.10) {
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            }
            // 펄스 2 임팩트 (t=2.40) — 더 큰 팽창
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.40) {
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            }
            // 분리 개시 (t=2.60)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.60) {
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            }
            return

        case .perfect:
            // 기존 DIVINE 햅틱을 PERFECT로 승격
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()

            let soft = UIImpactFeedbackGenerator(style: .soft)
            soft.prepare()
            for i in 0..<8 {
                let delay = 0.2 + Double(i) * 0.065
                let intensity = CGFloat(0.3 + Double(i) / 7 * 0.3)
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    soft.impactOccurred(intensity: intensity)
                }
            }

            let heavy = UIImpactFeedbackGenerator(style: .medium)
            heavy.prepare()
            for i in 0..<11 {
                let delay = 0.7 + Double(i) * 0.065
                let intensity = CGFloat(0.55 + Double(i) / 10 * 0.45)
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    heavy.impactOccurred(intensity: intensity)
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.7) {
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            }
            return

        case .great, .good, .close, .miss:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }

    // MARK: - Helpers

    private func rotateAction(for stage: Stage) -> SCNAction {
        let duration = 4.0 / stage.rotationSpeedMultiplier
        return .repeatForever(.rotateBy(x: 0.3, y: 0.8, z: 0.1, duration: duration))
    }

    private func randomInitialEulerAngles() -> SIMD3<Float> {
        SIMD3(
            Float.random(in: -Float.pi...Float.pi),
            Float.random(in: -Float.pi...Float.pi),
            Float.random(in: -Float.pi...Float.pi)
        )
    }

    private static func mesh(for type: ShapeType) -> Mesh {
        switch type {
        case .cube:            return ShapeFactory.cube()
        case .sphere:          return ShapeFactory.sphere()
        case .cylinder:        return ShapeFactory.cylinder()
        case .cone:            return ShapeFactory.cone()
        case .triangularPrism: return ShapeFactory.triangularPrism()
        case .hexagonalPrism:  return ShapeFactory.hexagonalPrism()
        case .diamond:         return ShapeFactory.diamond()
        case .octahedron:      return ShapeFactory.octahedron()
        case .icosahedron:     return ShapeFactory.icosahedron()
        case .pentagonalPrism: return ShapeFactory.pentagonalPrism()
        case .starPrism:       return ShapeFactory.starPrism()
        case .twistedPrism:    return ShapeFactory.twistedPrism()
        case .facetedCrystal:  return ShapeFactory.facetedCrystal()
        case .elongatedBipyramid:
            return ShapeFactory.elongatedBipyramid()
        case .asymmetricPrism: return ShapeFactory.asymmetricPrism()
        case .razorCrystal:    return ShapeFactory.razorCrystal()
        case .skewedTower:     return ShapeFactory.skewedTower()
        case .fracturedGem:    return ShapeFactory.fracturedGem()
        case .serratedBipyramid:
            return ShapeFactory.serratedBipyramid()
        case .chaosPolyhedron:
            return ShapeFactory.chaosPolyhedron()
        }
    }

    private static func makePieceNode(from piece: CutPiece, grade: Grade) -> SCNNode {
        let holder = SCNNode()
        holder.addChildNode(SCNNode(geometry: makeBodyGeometry(from: piece.body)))
        if piece.cap.triangleCount > 0 {
            holder.addChildNode(SCNNode(geometry: makeCapGeometry(from: piece.cap, grade: grade)))
        }
        return holder
    }

    private static func makeBodyNode(from mesh: Mesh) -> SCNNode {
        SCNNode(geometry: makeBodyGeometry(from: mesh))
    }

    private static func makeBodyGeometry(from mesh: Mesh) -> SCNGeometry {
        let geo = mesh.makeGeometry()
        let m = SCNMaterial()
        m.diffuse.contents = baseColor
        m.lightingModel = .physicallyBased
        m.roughness.contents = 0.6
        m.metalness.contents = 0.0
        m.isDoubleSided = true
        geo.materials = [m]
        return geo
    }

    private static func makeCapGeometry(from mesh: Mesh, grade: Grade) -> SCNGeometry {
        let geo = mesh.makeGeometry()
        let m = SCNMaterial()
        let color = capColor(for: grade)
        m.diffuse.contents = color.diffuse
        m.emission.contents = color.emission
        m.lightingModel = .physicallyBased
        m.roughness.contents = color.roughness
        m.metalness.contents = 0.0
        m.isDoubleSided = true
        geo.materials = [m]
        return geo
    }

    private static func capColor(for grade: Grade) -> (diffuse: UIColor, emission: UIColor, roughness: CGFloat) {
        switch grade {
        case .divine:
            return (
                UIColor(red: 1.0, green: 0.52, blue: 0.94, alpha: 1.0),
                UIColor(red: 1.0, green: 0.28, blue: 0.86, alpha: 0.85),
                0.18
            )
        case .perfect:
            return (
                UIColor(red: 1.0, green: 0.92, blue: 0.42, alpha: 1.0),
                UIColor(red: 1.0, green: 0.72, blue: 0.16, alpha: 0.7),
                0.22
            )
        case .great:
            return (
                UIColor(red: 0.48, green: 1.0, blue: 0.78, alpha: 1.0),
                UIColor(red: 0.22, green: 0.95, blue: 0.60, alpha: 0.45),
                0.32
            )
        case .good:
            return (
                UIColor(red: 0.48, green: 0.90, blue: 1.0, alpha: 1.0),
                UIColor(red: 0.18, green: 0.74, blue: 1.0, alpha: 0.35),
                0.38
            )
        case .close, .miss:
            return (
                UIColor(red: 0.95, green: 0.40, blue: 0.46, alpha: 1.0),
                UIColor(red: 0.75, green: 0.12, blue: 0.18, alpha: 0.22),
                0.55
            )
        }
    }
}
