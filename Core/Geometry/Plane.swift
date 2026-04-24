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
}
