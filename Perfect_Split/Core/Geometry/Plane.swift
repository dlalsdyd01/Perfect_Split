import Foundation
import simd

struct Plane {
    var normal: SIMD3<Float>
    var point: SIMD3<Float>

    init(normal: SIMD3<Float>, point: SIMD3<Float>) {
        self.normal = simd_normalize(normal)
        self.point = point
    }

    static func fromThreePoints(_ a: SIMD3<Float>, _ b: SIMD3<Float>, _ c: SIMD3<Float>) -> Plane {
        let n = simd_cross(b - a, c - a)
        return Plane(normal: n, point: a)
    }

    func signedDistance(to p: SIMD3<Float>) -> Float {
        simd_dot(normal, p - point)
    }

    func transformed(by matrix: simd_float4x4) -> Plane {
        let p = matrix * SIMD4<Float>(point.x, point.y, point.z, 1)
        let n = matrix * SIMD4<Float>(normal.x, normal.y, normal.z, 0)
        return Plane(
            normal: SIMD3<Float>(n.x, n.y, n.z),
            point: SIMD3<Float>(p.x, p.y, p.z)
        )
    }
}
