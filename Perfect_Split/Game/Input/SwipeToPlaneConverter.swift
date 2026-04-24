import Foundation
import SceneKit
import simd
import UIKit

enum SwipeToPlaneConverter {
    static func plane(from start: CGPoint, to end: CGPoint, in view: SCNView) -> Plane? {
        guard let camera = view.pointOfView else { return nil }

        let dx = end.x - start.x
        let dy = end.y - start.y
        guard dx * dx + dy * dy > 25 else { return nil }

        let startFar = view.unprojectPoint(SCNVector3(Float(start.x), Float(start.y), 0.95))
        let endFar = view.unprojectPoint(SCNVector3(Float(end.x), Float(end.y), 0.95))

        let cameraPos = camera.simdWorldPosition
        let p2 = SIMD3<Float>(startFar.x, startFar.y, startFar.z)
        let p3 = SIMD3<Float>(endFar.x, endFar.y, endFar.z)

        return Plane.fromThreePoints(cameraPos, p2, p3)
    }

    static func coversProjectedNode(
        _ node: SCNNode,
        from start: CGPoint,
        to end: CGPoint,
        in view: SCNView,
        minimumDiameterCoverage: CGFloat = 0.65
    ) -> Bool {
        let projectedCircle = projectedBoundingCircle(for: node.presentation, in: view)
        guard projectedCircle.radius > 8 else { return false }

        let swipe = CGPoint(x: end.x - start.x, y: end.y - start.y)
        let swipeLength = hypot(swipe.x, swipe.y)
        guard swipeLength > 0 else { return false }

        let relativeStart = CGPoint(
            x: start.x - projectedCircle.center.x,
            y: start.y - projectedCircle.center.y
        )
        let a = swipe.x * swipe.x + swipe.y * swipe.y
        let b = 2 * (relativeStart.x * swipe.x + relativeStart.y * swipe.y)
        let c = relativeStart.x * relativeStart.x
            + relativeStart.y * relativeStart.y
            - projectedCircle.radius * projectedCircle.radius
        let discriminant = b * b - 4 * a * c
        guard discriminant > 0 else { return false }

        let root = sqrt(discriminant)
        let t0 = max(0, (-b - root) / (2 * a))
        let t1 = min(1, (-b + root) / (2 * a))
        guard t1 > t0 else { return false }

        let coveredLength = (t1 - t0) * swipeLength
        return coveredLength >= projectedCircle.radius * 2 * minimumDiameterCoverage
    }

    static func coversProjectedMesh(
        _ mesh: Mesh,
        node: SCNNode,
        from start: CGPoint,
        to end: CGPoint,
        in view: SCNView,
        minimumDirectionalCoverage: CGFloat = 0.65
    ) -> Bool {
        let swipe = CGPoint(x: end.x - start.x, y: end.y - start.y)
        let swipeLength = hypot(swipe.x, swipe.y)
        guard swipeLength > 0 else { return false }

        let projectedPoints = mesh.vertices.map { vertex in
            let local = SCNVector3(vertex.x, vertex.y, vertex.z)
            let projected = view.projectPoint(node.convertPosition(local, to: nil))
            return CGPoint(x: CGFloat(projected.x), y: CGFloat(projected.y))
        }
        let hull = convexHull(projectedPoints)
        guard hull.count >= 3 else { return false }

        guard let coveredLength = segmentLengthInsideConvexPolygon(
            polygon: hull,
            start: start,
            end: end
        ) else {
            return false
        }

        let direction = CGPoint(x: swipe.x / swipeLength, y: swipe.y / swipeLength)
        let directionalWidth = width(of: hull, along: direction)
        guard directionalWidth > 8 else { return false }

        return coveredLength >= directionalWidth * minimumDirectionalCoverage
    }

    private static func projectedBoundingCircle(
        for node: SCNNode,
        in view: SCNView
    ) -> (center: CGPoint, radius: CGFloat) {
        let (minPoint, maxPoint) = node.boundingBox

        let localCenter = SCNVector3(
            (minPoint.x + maxPoint.x) * 0.5,
            (minPoint.y + maxPoint.y) * 0.5,
            (minPoint.z + maxPoint.z) * 0.5
        )
        let worldCenter = node.convertPosition(localCenter, to: nil)
        let projectedCenter = view.projectPoint(worldCenter)
        let center = CGPoint(x: CGFloat(projectedCenter.x), y: CGFloat(projectedCenter.y))

        let corners = [
            SCNVector3(minPoint.x, minPoint.y, minPoint.z),
            SCNVector3(minPoint.x, minPoint.y, maxPoint.z),
            SCNVector3(minPoint.x, maxPoint.y, minPoint.z),
            SCNVector3(minPoint.x, maxPoint.y, maxPoint.z),
            SCNVector3(maxPoint.x, minPoint.y, minPoint.z),
            SCNVector3(maxPoint.x, minPoint.y, maxPoint.z),
            SCNVector3(maxPoint.x, maxPoint.y, minPoint.z),
            SCNVector3(maxPoint.x, maxPoint.y, maxPoint.z)
        ]

        let radius = corners.reduce(CGFloat.zero) { current, corner in
            let projected = view.projectPoint(node.convertPosition(corner, to: nil))
            let point = CGPoint(x: CGFloat(projected.x), y: CGFloat(projected.y))
            return max(current, hypot(point.x - center.x, point.y - center.y))
        }
        return (center, radius)
    }

    private static func convexHull(_ points: [CGPoint]) -> [CGPoint] {
        let sorted = points.sorted {
            if $0.x == $1.x { return $0.y < $1.y }
            return $0.x < $1.x
        }
        guard sorted.count > 2 else { return sorted }

        var lower: [CGPoint] = []
        for point in sorted {
            while lower.count >= 2,
                  cross(lower[lower.count - 1] - lower[lower.count - 2], point - lower[lower.count - 1]) <= 0 {
                lower.removeLast()
            }
            lower.append(point)
        }

        var upper: [CGPoint] = []
        for point in sorted.reversed() {
            while upper.count >= 2,
                  cross(upper[upper.count - 1] - upper[upper.count - 2], point - upper[upper.count - 1]) <= 0 {
                upper.removeLast()
            }
            upper.append(point)
        }

        lower.removeLast()
        upper.removeLast()
        return lower + upper
    }

    private static func segmentLengthInsideConvexPolygon(
        polygon: [CGPoint],
        start: CGPoint,
        end: CGPoint
    ) -> CGFloat? {
        let delta = end - start
        let length = hypot(delta.x, delta.y)
        guard length > 0 else { return nil }

        var enter: CGFloat = 0
        var exit: CGFloat = 1

        for i in polygon.indices {
            let a = polygon[i]
            let b = polygon[(i + 1) % polygon.count]
            let edge = b - a
            let startOffset = start - a
            let numerator = cross(edge, startOffset)
            let denominator = cross(edge, delta)

            if abs(denominator) < 0.0001 {
                if numerator < 0 { return nil }
                continue
            }

            let t = -numerator / denominator
            if denominator > 0 {
                enter = max(enter, t)
            } else {
                exit = min(exit, t)
            }
            if enter > exit { return nil }
        }

        return max(0, exit - enter) * length
    }

    private static func width(of polygon: [CGPoint], along direction: CGPoint) -> CGFloat {
        let projections = polygon.map { $0.x * direction.x + $0.y * direction.y }
        guard let minProjection = projections.min(),
              let maxProjection = projections.max() else {
            return 0
        }
        return maxProjection - minProjection
    }

    private static func cross(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        a.x * b.y - a.y * b.x
    }
}

private func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
}
