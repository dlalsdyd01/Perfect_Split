import Foundation
import SceneKit
import simd

extension Mesh {
    func makeGeometry() -> SCNGeometry {
        let vertexData = vertices.withUnsafeBufferPointer { buf in
            Data(buffer: buf)
        }
        let vertexSource = SCNGeometrySource(
            data: vertexData,
            semantic: .vertex,
            vectorCount: vertices.count,
            usesFloatComponents: true,
            componentsPerVector: 3,
            bytesPerComponent: MemoryLayout<Float>.size,
            dataOffset: 0,
            dataStride: MemoryLayout<SIMD3<Float>>.stride
        )

        let indices = triangles.map { UInt32($0) }
        let indexData = indices.withUnsafeBufferPointer { buf in
            Data(buffer: buf)
        }
        let element = SCNGeometryElement(
            data: indexData,
            primitiveType: .triangles,
            primitiveCount: triangleCount,
            bytesPerIndex: MemoryLayout<UInt32>.size
        )

        return SCNGeometry(sources: [vertexSource], elements: [element])
    }
}
