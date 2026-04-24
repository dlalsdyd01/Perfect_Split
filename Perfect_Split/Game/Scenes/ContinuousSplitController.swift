import Foundation
import SceneKit
import UIKit
import simd

struct ContinuousCutResult {
    let stats: CutStats
    let passed: Bool
}

final class ContinuousSplitController {
    let scene: SCNScene
    private let cameraNode: SCNNode
    private var activeNode: SCNNode?
    private var activeMesh: Mesh?
    private var nextMesh: Mesh?
    private let minimumPieceShareForCut = 0.25

    private static let baseColor = UIColor(red: 0.70, green: 0.86, blue: 1.0, alpha: 1.0)
    private static let capColor = UIColor(red: 0.36, green: 1.0, blue: 0.66, alpha: 1.0)

    init() {
        scene = SCNScene()
        scene.background.contents = UIColor.clear

        let camera = SCNNode()
        camera.camera = SCNCamera()
        camera.position = SCNVector3(0, 0, 4.2)
        scene.rootNode.addChildNode(camera)
        cameraNode = camera

        reset()
    }

    func reset() {
        load(mesh: ShapeFactory.cube(size: 1.8))
    }

    func continueWithNextPiece() {
        guard let nextMesh else { return }
        load(mesh: centered(nextMesh))
    }

    func cut(along worldPlane: Plane, tolerance: Double = 10.0) -> ContinuousCutResult? {
        guard let node = activeNode, let mesh = activeMesh else { return nil }

        let snapshot = node.presentation.simdTransform
        node.simdTransform = snapshot
        let localPlane = worldPlane.transformed(by: simd_inverse(snapshot))

        let (pos, neg) = MeshCutter.cut(mesh, with: localPlane)
        if pos.body.triangleCount == 0 || neg.body.triangleCount == 0 {
            return nil
        }

        let posMesh = pos.closedMesh
        let negMesh = neg.closedMesh
        let posVol = Double(VolumeCalculator.volume(of: posMesh))
        let negVol = Double(VolumeCalculator.volume(of: negMesh))
        let total = posVol + negVol
        guard total > 0 else { return nil }
        guard min(posVol, negVol) / total >= minimumPieceShareForCut else { return nil }

        let stats = CutStats(
            leftPercent: posVol / total * 100,
            rightPercent: negVol / total * 100
        )
        let passed = stats.errorPercent <= tolerance
        nextMesh = weld(posVol >= negVol ? posMesh : negMesh)

        node.removeFromParentNode()
        activeNode = nil
        activeMesh = nil

        let posNode = pieceNode(from: pos)
        let negNode = pieceNode(from: neg)
        posNode.simdTransform = snapshot
        negNode.simdTransform = snapshot
        scene.rootNode.addChildNode(posNode)
        scene.rootNode.addChildNode(negNode)

        separate(posNode: posNode, negNode: negNode, normal: worldPlane.normal, passed: passed)
        if UserDefaults.standard.object(forKey: "perfect_split.settings.haptics") as? Bool ?? true {
            UIImpactFeedbackGenerator(style: passed ? .medium : .rigid).impactOccurred()
        }

        return ContinuousCutResult(stats: stats, passed: passed)
    }

    func canCut(from start: CGPoint, to end: CGPoint, in view: SCNView) -> Bool {
        guard let activeNode, let activeMesh else { return false }
        return SwipeToPlaneConverter.coversProjectedMesh(
            activeMesh,
            node: activeNode.presentation,
            from: start,
            to: end,
            in: view
        )
    }

    func rotateActiveShape(by delta: CGPoint) {
        guard let node = activeNode else { return }
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

    private func load(mesh: Mesh) {
        for node in scene.rootNode.childNodes where node !== cameraNode {
            node.removeAllActions()
            node.removeFromParentNode()
        }
        nextMesh = nil
        activeMesh = mesh

        let node = SCNNode(geometry: bodyGeometry(from: mesh))
        scene.rootNode.addChildNode(node)
        activeNode = node
    }

    private func separate(posNode: SCNNode, negNode: SCNNode, normal: SIMD3<Float>, passed: Bool) {
        let distance: Float = passed ? 0.55 : 0.8
        let offset = normal * distance
        let posMove = SCNAction.move(by: SCNVector3(offset.x, offset.y, offset.z), duration: 0.36)
        let negMove = SCNAction.move(by: SCNVector3(-offset.x, -offset.y, -offset.z), duration: 0.36)
        posMove.timingMode = .easeOut
        negMove.timingMode = .easeOut
        posNode.runAction(posMove)
        negNode.runAction(negMove)
    }

    private func pieceNode(from piece: CutPiece) -> SCNNode {
        let holder = SCNNode()
        holder.addChildNode(SCNNode(geometry: bodyGeometry(from: piece.body)))
        if piece.cap.triangleCount > 0 {
            holder.addChildNode(SCNNode(geometry: capGeometry(from: piece.cap)))
        }
        return holder
    }

    private func bodyGeometry(from mesh: Mesh) -> SCNGeometry {
        let geo = mesh.makeGeometry()
        let material = SCNMaterial()
        material.diffuse.contents = Self.baseColor
        material.lightingModel = .physicallyBased
        material.roughness.contents = 0.58
        material.isDoubleSided = true
        geo.materials = [material]
        return geo
    }

    private func capGeometry(from mesh: Mesh) -> SCNGeometry {
        let geo = mesh.makeGeometry()
        let material = SCNMaterial()
        material.diffuse.contents = Self.capColor
        material.emission.contents = Self.capColor.withAlphaComponent(0.42)
        material.lightingModel = .physicallyBased
        material.roughness.contents = 0.35
        material.isDoubleSided = true
        geo.materials = [material]
        return geo
    }

    private func centered(_ mesh: Mesh) -> Mesh {
        guard let first = mesh.vertices.first else { return mesh }
        var minPoint = first
        var maxPoint = first
        for vertex in mesh.vertices {
            minPoint = simd_min(minPoint, vertex)
            maxPoint = simd_max(maxPoint, vertex)
        }

        let center = (minPoint + maxPoint) * 0.5
        var centered = mesh
        centered.vertices = mesh.vertices.map { $0 - center }
        return centered
    }

    private func weld(_ mesh: Mesh, epsilon: Float = 1e-5) -> Mesh {
        var vertices: [SIMD3<Float>] = []
        var remap: [Int] = []

        for vertex in mesh.vertices {
            if let index = vertices.firstIndex(where: { simd_distance_squared($0, vertex) <= epsilon * epsilon }) {
                remap.append(index)
            } else {
                remap.append(vertices.count)
                vertices.append(vertex)
            }
        }

        var triangles: [Int] = []
        var i = 0
        while i + 2 < mesh.triangles.count {
            let a = remap[mesh.triangles[i]]
            let b = remap[mesh.triangles[i + 1]]
            let c = remap[mesh.triangles[i + 2]]
            if a != b && b != c && c != a {
                triangles += [a, b, c]
            }
            i += 3
        }

        return Mesh(vertices: vertices, triangles: triangles)
    }
}
