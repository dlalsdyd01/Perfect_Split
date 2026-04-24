import SwiftUI
import SceneKit
import UIKit

struct SceneKitView: UIViewRepresentable {
    let scene: SCNScene
    let allowsCameraControl: Bool
    let swipeEnabled: Bool
    let rotationEnabled: Bool
    let onSwipe: (CGPoint, CGPoint, SCNView) -> Void
    let onRotate: (CGPoint) -> Void

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.scene = scene
        view.backgroundColor = .clear
        view.autoenablesDefaultLighting = true
        view.rendersContinuously = true
        view.antialiasingMode = .multisampling4X
        view.allowsCameraControl = allowsCameraControl
        view.defaultCameraController.target = SCNVector3Zero

        let pan = UIPanGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handlePan(_:))
        )
        pan.delegate = context.coordinator
        view.addGestureRecognizer(pan)

        context.coordinator.attach(
            to: view,
            swipeEnabled: swipeEnabled,
            rotationEnabled: rotationEnabled,
            onSwipe: onSwipe,
            onRotate: onRotate
        )
        return view
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        uiView.allowsCameraControl = allowsCameraControl
        uiView.defaultCameraController.target = SCNVector3Zero
        context.coordinator.swipeEnabled = swipeEnabled
        context.coordinator.rotationEnabled = rotationEnabled
        context.coordinator.onSwipe = onSwipe
        context.coordinator.onRotate = onRotate
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject {
        weak var view: SCNView?
        var swipeEnabled: Bool = true
        var rotationEnabled: Bool = false
        var onSwipe: ((CGPoint, CGPoint, SCNView) -> Void)?
        var onRotate: ((CGPoint) -> Void)?

        private var start: CGPoint = .zero
        private var trail: [CGPoint] = []
        private let trailLayer = CAShapeLayer()

        func attach(
            to view: SCNView,
            swipeEnabled: Bool,
            rotationEnabled: Bool,
            onSwipe: @escaping (CGPoint, CGPoint, SCNView) -> Void,
            onRotate: @escaping (CGPoint) -> Void
        ) {
            self.view = view
            self.swipeEnabled = swipeEnabled
            self.rotationEnabled = rotationEnabled
            self.onSwipe = onSwipe
            self.onRotate = onRotate

            trailLayer.strokeColor = UIColor(red: 0.75, green: 0.90, blue: 1.0, alpha: 1.0).cgColor
            trailLayer.fillColor = UIColor.clear.cgColor
            trailLayer.lineWidth = 4
            trailLayer.lineCap = .round
            trailLayer.lineJoin = .round
            trailLayer.shadowColor = UIColor.cyan.cgColor
            trailLayer.shadowRadius = 10
            trailLayer.shadowOpacity = 0.9
            trailLayer.shadowOffset = .zero
            view.layer.addSublayer(trailLayer)
        }

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let view else { return }
            if rotationEnabled {
                let delta = gesture.translation(in: view)
                onRotate?(delta)
                gesture.setTranslation(.zero, in: view)
                return
            }
            guard swipeEnabled else { return }
            let p = gesture.location(in: view)
            switch gesture.state {
            case .began:
                start = p
                trail = [p]
                updateTrail()
            case .changed:
                trail.append(p)
                updateTrail()
            case .ended:
                onSwipe?(start, p, view)
                fadeTrail()
            case .cancelled, .failed:
                fadeTrail()
            default:
                break
            }
        }

        private func updateTrail() {
            guard let first = trail.first else {
                trailLayer.path = nil
                return
            }
            let path = UIBezierPath()
            path.move(to: first)
            for p in trail.dropFirst() { path.addLine(to: p) }
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            trailLayer.path = path.cgPath
            trailLayer.opacity = 1.0
            CATransaction.commit()
        }

        private func fadeTrail() {
            let fade = CABasicAnimation(keyPath: "opacity")
            fade.fromValue = 1.0
            fade.toValue = 0.0
            fade.duration = 0.3
            trailLayer.add(fade, forKey: "fade")
            trailLayer.opacity = 0
        }
    }
}

extension SceneKitView.Coordinator: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        swipeEnabled || rotationEnabled
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        true
    }
}
