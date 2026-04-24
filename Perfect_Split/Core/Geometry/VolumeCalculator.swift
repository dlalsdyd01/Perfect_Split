import Foundation
import simd

enum VolumeCalculator {
    static func signedVolume(of mesh: Mesh) -> Float {
        var sum: Float = 0
        for ti in 0..<mesh.triangleCount {
            let (a, b, c) = mesh.triangle(at: ti)
            sum += simd_dot(a, simd_cross(b, c))
        }
        return sum / 6.0
    }

    static func volume(of mesh: Mesh) -> Float {
        abs(signedVolume(of: mesh))
    }
}
