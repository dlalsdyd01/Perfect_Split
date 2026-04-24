import Foundation
import simd

struct Mesh {
    var vertices: [SIMD3<Float>]
    var triangles: [Int]

    init(vertices: [SIMD3<Float>] = [], triangles: [Int] = []) {
        self.vertices = vertices
        self.triangles = triangles
    }

    var triangleCount: Int { triangles.count / 3 }

    func triangle(at index: Int) -> (SIMD3<Float>, SIMD3<Float>, SIMD3<Float>) {
        let i = index * 3
        return (vertices[triangles[i]], vertices[triangles[i + 1]], vertices[triangles[i + 2]])
    }

    mutating func appendTriangle(_ a: SIMD3<Float>, _ b: SIMD3<Float>, _ c: SIMD3<Float>) {
        let base = vertices.count
        vertices.append(a)
        vertices.append(b)
        vertices.append(c)
        triangles.append(base)
        triangles.append(base + 1)
        triangles.append(base + 2)
    }
}
