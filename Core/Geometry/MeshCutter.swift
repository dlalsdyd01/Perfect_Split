import Foundation
import simd

enum MeshCutter {
    static func cut(
        _ mesh: Mesh,
        with plane: Plane,
        epsilon: Float = 1e-5
    ) -> (positive: Mesh, negative: Mesh) {
        var pos = Mesh()
        var neg = Mesh()
        var cutEdges: [(SIMD3<Float>, SIMD3<Float>)] = []

        for ti in 0..<mesh.triangleCount {
            let (a, b, c) = mesh.triangle(at: ti)
            splitTriangle(
                a: a, b: b, c: c,
                plane: plane, epsilon: epsilon,
                pos: &pos, neg: &neg, cutEdges: &cutEdges
            )
        }

        let loops = assembleLoops(edges: cutEdges, epsilon: epsilon * 10)
        for loop in loops {
            for (p0, p1, p2) in earClip(polygon: loop, normal: plane.normal) {
                neg.appendTriangle(p0, p1, p2)
                pos.appendTriangle(p0, p2, p1)
            }
        }

        return (pos, neg)
    }

    // MARK: - Per-triangle split

    private static func splitTriangle(
        a: SIMD3<Float>, b: SIMD3<Float>, c: SIMD3<Float>,
        plane: Plane, epsilon: Float,
        pos: inout Mesh, neg: inout Mesh,
        cutEdges: inout [(SIMD3<Float>, SIMD3<Float>)]
    ) {
        let verts = [a, b, c]
        let dists: [Float] = [
            biased(plane.signedDistance(to: a), epsilon: epsilon),
            biased(plane.signedDistance(to: b), epsilon: epsilon),
            biased(plane.signedDistance(to: c), epsilon: epsilon)
        ]

        var posPoly: [SIMD3<Float>] = []
        var negPoly: [SIMD3<Float>] = []
        var crossings: [SIMD3<Float>] = []

        for i in 0..<3 {
            let curr = verts[i]
            let next = verts[(i + 1) % 3]
            let dCurr = dists[i]
            let dNext = dists[(i + 1) % 3]
            let currPositive = dCurr >= 0
            let nextPositive = dNext >= 0

            if currPositive { posPoly.append(curr) } else { negPoly.append(curr) }

            if currPositive != nextPositive {
                let t = dCurr / (dCurr - dNext)
                let p = curr + (next - curr) * t
                posPoly.append(p)
                negPoly.append(p)
                crossings.append(p)
            }
        }

        fanTriangulate(posPoly, into: &pos)
        fanTriangulate(negPoly, into: &neg)

        if crossings.count == 2 {
            cutEdges.append((crossings[0], crossings[1]))
        }
    }

    private static func biased(_ d: Float, epsilon: Float) -> Float {
        if abs(d) < epsilon {
            return d >= 0 ? epsilon : -epsilon
        }
        return d
    }

    private static func fanTriangulate(_ poly: [SIMD3<Float>], into mesh: inout Mesh) {
        guard poly.count >= 3 else { return }
        for i in 1..<(poly.count - 1) {
            mesh.appendTriangle(poly[0], poly[i], poly[i + 1])
        }
    }

    // MARK: - Loop assembly

    private static func assembleLoops(
        edges: [(SIMD3<Float>, SIMD3<Float>)],
        epsilon: Float
    ) -> [[SIMD3<Float>]] {
        var remaining = edges
        var loops: [[SIMD3<Float>]] = []

        while !remaining.isEmpty {
            let first = remaining.removeFirst()
            var loop = [first.0, first.1]
            var current = first.1

            while true {
                if approxEqual(current, loop[0], epsilon) {
                    loop.removeLast()
                    break
                }
                if let idx = remaining.firstIndex(where: { approxEqual($0.0, current, epsilon) }) {
                    let edge = remaining.remove(at: idx)
                    loop.append(edge.1)
                    current = edge.1
                } else {
                    break
                }
            }

            if loop.count >= 3 {
                loops.append(loop)
            }
        }
        return loops
    }

    private static func approxEqual(_ a: SIMD3<Float>, _ b: SIMD3<Float>, _ epsilon: Float) -> Bool {
        simd_distance_squared(a, b) < epsilon * epsilon
    }

    // MARK: - Ear clipping in 3D (using the loop's plane normal)

    private static func earClip(
        polygon: [SIMD3<Float>],
        normal: SIMD3<Float>
    ) -> [(SIMD3<Float>, SIMD3<Float>, SIMD3<Float>)] {
        guard polygon.count >= 3 else { return [] }
        if polygon.count == 3 {
            return [(polygon[0], polygon[1], polygon[2])]
        }

        var indices = Array(0..<polygon.count)
        var result: [(SIMD3<Float>, SIMD3<Float>, SIMD3<Float>)] = []

        while indices.count > 3 {
            var foundEar = false
            for i in 0..<indices.count {
                let pi = (i - 1 + indices.count) % indices.count
                let ni = (i + 1) % indices.count
                let a = polygon[indices[pi]]
                let b = polygon[indices[i]]
                let c = polygon[indices[ni]]

                // Convex corner for CCW-viewed-from-+normal
                let cross = simd_cross(b - a, c - b)
                if simd_dot(cross, normal) <= 0 { continue }

                var contains = false
                for j in 0..<indices.count where j != pi && j != i && j != ni {
                    if pointInTriangle(polygon[indices[j]], a, b, c, normal) {
                        contains = true
                        break
                    }
                }
                if contains { continue }

                result.append((a, b, c))
                indices.remove(at: i)
                foundEar = true
                break
            }
            if !foundEar { break }
        }

        if indices.count == 3 {
            result.append((polygon[indices[0]], polygon[indices[1]], polygon[indices[2]]))
        }
        return result
    }

    private static func pointInTriangle(
        _ p: SIMD3<Float>,
        _ a: SIMD3<Float>, _ b: SIMD3<Float>, _ c: SIMD3<Float>,
        _ normal: SIMD3<Float>
    ) -> Bool {
        let ab = simd_cross(b - a, p - a)
        let bc = simd_cross(c - b, p - b)
        let ca = simd_cross(a - c, p - c)
        return simd_dot(ab, normal) >= 0
            && simd_dot(bc, normal) >= 0
            && simd_dot(ca, normal) >= 0
    }
}
