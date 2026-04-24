import Foundation
import simd

enum ShapeFactory {
    static func cube(size: Float = 1.2) -> Mesh {
        let h = size * 0.5
        let v: [SIMD3<Float>] = [
            SIMD3(-h, -h, -h), SIMD3( h, -h, -h), SIMD3( h,  h, -h), SIMD3(-h,  h, -h),
            SIMD3(-h, -h,  h), SIMD3( h, -h,  h), SIMD3( h,  h,  h), SIMD3(-h,  h,  h)
        ]
        let t: [Int] = [
            0, 2, 1,  0, 3, 2, // -Z
            4, 5, 6,  4, 6, 7, // +Z
            0, 4, 7,  0, 7, 3, // -X
            1, 2, 6,  1, 6, 5, // +X
            0, 1, 5,  0, 5, 4, // -Y
            3, 7, 6,  3, 6, 2  // +Y
        ]
        return orient(Mesh(vertices: v, triangles: t))
    }

    static func sphere(radius: Float = 0.75, segments: Int = 24, rings: Int = 16) -> Mesh {
        var vertices: [SIMD3<Float>] = []
        var triangles: [Int] = []
        let stride = segments + 1

        for i in 0...rings {
            let theta = Float.pi * Float(i) / Float(rings)
            let y = radius * cos(theta)
            let r = radius * sin(theta)
            for j in 0...segments {
                let phi = 2 * Float.pi * Float(j) / Float(segments)
                vertices.append(SIMD3(r * cos(phi), y, r * sin(phi)))
            }
        }

        for i in 0..<rings {
            for j in 0..<segments {
                let a = i * stride + j
                let b = a + stride
                if i != 0 {
                    triangles += [a, a + 1, b]
                }
                if i != rings - 1 {
                    triangles += [a + 1, b + 1, b]
                }
            }
        }
        return orient(Mesh(vertices: vertices, triangles: triangles))
    }

    static func cylinder(radius: Float = 0.6, height: Float = 1.6, segments: Int = 24) -> Mesh {
        var vertices: [SIMD3<Float>] = []
        var triangles: [Int] = []
        let h = height * 0.5

        let topCenter = vertices.count
        vertices.append(SIMD3(0, h, 0))
        let botCenter = vertices.count
        vertices.append(SIMD3(0, -h, 0))

        let topStart = vertices.count
        for j in 0..<segments {
            let phi = 2 * Float.pi * Float(j) / Float(segments)
            vertices.append(SIMD3(radius * cos(phi), h, radius * sin(phi)))
        }
        let botStart = vertices.count
        for j in 0..<segments {
            let phi = 2 * Float.pi * Float(j) / Float(segments)
            vertices.append(SIMD3(radius * cos(phi), -h, radius * sin(phi)))
        }

        for j in 0..<segments {
            let a = topStart + j
            let b = topStart + (j + 1) % segments
            triangles += [topCenter, b, a]                 // top cap (+Y)
        }
        for j in 0..<segments {
            let a = botStart + j
            let b = botStart + (j + 1) % segments
            triangles += [botCenter, a, b]                 // bottom cap (-Y)
        }
        for j in 0..<segments {
            let ta = topStart + j
            let tb = topStart + (j + 1) % segments
            let ba = botStart + j
            let bb = botStart + (j + 1) % segments
            triangles += [ta, ba, tb]
            triangles += [tb, ba, bb]
        }
        return orient(Mesh(vertices: vertices, triangles: triangles))
    }

    static func cone(radius: Float = 0.75, height: Float = 1.5, segments: Int = 24) -> Mesh {
        var vertices: [SIMD3<Float>] = []
        var triangles: [Int] = []

        // 체적 중심을 원점에 맞춤: 원뿔의 COG는 밑면에서 1/4 높이 지점.
        // apex = +3H/4, base = −H/4 로 배치하면 COG가 y=0.
        let apexY: Float = height * 0.75
        let baseY: Float = -height * 0.25

        let apex = vertices.count
        vertices.append(SIMD3(0, apexY, 0))
        let baseCenter = vertices.count
        vertices.append(SIMD3(0, baseY, 0))

        let baseStart = vertices.count
        for j in 0..<segments {
            let phi = 2 * Float.pi * Float(j) / Float(segments)
            vertices.append(SIMD3(radius * cos(phi), baseY, radius * sin(phi)))
        }

        for j in 0..<segments {
            let a = baseStart + j
            let b = baseStart + (j + 1) % segments
            triangles += [apex, a, b]                      // side
            triangles += [baseCenter, a, b]                // base (-Y outward)
        }
        return orient(Mesh(vertices: vertices, triangles: triangles))
    }

    static func triangularPrism(radius: Float = 0.75, height: Float = 1.5) -> Mesh {
        var vertices: [SIMD3<Float>] = []
        var triangles: [Int] = []
        let h = height * 0.5
        let angles: [Float] = [
            Float.pi / 2,
            7 * Float.pi / 6,
            11 * Float.pi / 6
        ]
        for phi in angles {
            vertices.append(SIMD3(radius * cos(phi), h, radius * sin(phi)))
        }
        for phi in angles {
            vertices.append(SIMD3(radius * cos(phi), -h, radius * sin(phi)))
        }
        triangles += [0, 2, 1]          // top cap (+Y)
        triangles += [3, 4, 5]          // bottom cap (-Y)
        for i in 0..<3 {
            let a = i
            let b = (i + 1) % 3
            let c = a + 3
            let d = b + 3
            triangles += [a, b, c]
            triangles += [b, d, c]
        }
        return orient(Mesh(vertices: vertices, triangles: triangles))
    }

    static func hexagonalPrism(radius: Float = 0.72, height: Float = 1.45) -> Mesh {
        prism(sides: 6, radius: radius, height: height, startAngle: Float.pi / 6)
    }

    static func pentagonalPrism(radius: Float = 0.76, height: Float = 1.5) -> Mesh {
        prism(sides: 5, radius: radius, height: height, startAngle: Float.pi / 2)
    }

    static func diamond(radius: Float = 0.82, height: Float = 1.55, beltSides: Int = 8) -> Mesh {
        var vertices: [SIMD3<Float>] = [
            SIMD3(0, height * 0.5, 0),
            SIMD3(0, -height * 0.5, 0)
        ]
        let beltStart = vertices.count
        for i in 0..<beltSides {
            let phi = 2 * Float.pi * Float(i) / Float(beltSides)
            vertices.append(SIMD3(radius * cos(phi), 0, radius * sin(phi)))
        }

        var triangles: [Int] = []
        for i in 0..<beltSides {
            let a = beltStart + i
            let b = beltStart + (i + 1) % beltSides
            triangles += [0, a, b]
            triangles += [1, b, a]
        }
        return orient(Mesh(vertices: vertices, triangles: triangles))
    }

    static func octahedron(radius: Float = 0.88) -> Mesh {
        let v: [SIMD3<Float>] = [
            SIMD3(0, radius, 0),
            SIMD3(0, -radius, 0),
            SIMD3(radius, 0, 0),
            SIMD3(-radius, 0, 0),
            SIMD3(0, 0, radius),
            SIMD3(0, 0, -radius)
        ]
        let t: [Int] = [
            0, 2, 4,
            0, 4, 3,
            0, 3, 5,
            0, 5, 2,
            1, 4, 2,
            1, 3, 4,
            1, 5, 3,
            1, 2, 5
        ]
        return orient(Mesh(vertices: v, triangles: t))
    }

    static func icosahedron(radius: Float = 0.86) -> Mesh {
        let phi = (1 + sqrt(Float(5))) * 0.5
        let scale = radius / sqrt(1 + phi * phi)
        let a: Float = scale
        let b: Float = phi * scale
        let v: [SIMD3<Float>] = [
            SIMD3(-a,  b,  0), SIMD3( a,  b,  0), SIMD3(-a, -b,  0), SIMD3( a, -b,  0),
            SIMD3( 0, -a,  b), SIMD3( 0,  a,  b), SIMD3( 0, -a, -b), SIMD3( 0,  a, -b),
            SIMD3( b,  0, -a), SIMD3( b,  0,  a), SIMD3(-b,  0, -a), SIMD3(-b,  0,  a)
        ]
        let t: [Int] = [
            0, 11, 5,  0, 5, 1,   0, 1, 7,   0, 7, 10,  0, 10, 11,
            1, 5, 9,   5, 11, 4,  11, 10, 2, 10, 7, 6,  7, 1, 8,
            3, 9, 4,   3, 4, 2,   3, 2, 6,   3, 6, 8,   3, 8, 9,
            4, 9, 5,   2, 4, 11,  6, 2, 10,  8, 6, 7,   9, 8, 1
        ]
        return orient(Mesh(vertices: v, triangles: t))
    }

    static func starPrism(outerRadius: Float = 0.78, innerRadius: Float = 0.36, height: Float = 1.42) -> Mesh {
        var points: [SIMD2<Float>] = []
        for i in 0..<10 {
            let radius = i.isMultiple(of: 2) ? outerRadius : innerRadius
            let phi = Float.pi / 2 + 2 * Float.pi * Float(i) / 10
            points.append(SIMD2(radius * cos(phi), radius * sin(phi)))
        }
        return polygonPrism(points: points, height: height)
    }

    static func twistedPrism(radius: Float = 0.72, height: Float = 1.55, sides: Int = 6) -> Mesh {
        var vertices: [SIMD3<Float>] = []
        var triangles: [Int] = []
        let h = height * 0.5
        let twist: Float = .pi / 5

        let topCenter = vertices.count
        vertices.append(SIMD3(0, h, 0))
        let bottomCenter = vertices.count
        vertices.append(SIMD3(0, -h, 0))

        let topStart = vertices.count
        for i in 0..<sides {
            let phi = 2 * Float.pi * Float(i) / Float(sides) + twist
            vertices.append(SIMD3(radius * cos(phi), h, radius * sin(phi)))
        }
        let bottomStart = vertices.count
        for i in 0..<sides {
            let phi = 2 * Float.pi * Float(i) / Float(sides) - twist
            vertices.append(SIMD3(radius * cos(phi), -h, radius * sin(phi)))
        }

        for i in 0..<sides {
            let a = topStart + i
            let b = topStart + (i + 1) % sides
            triangles += [topCenter, b, a]
        }
        for i in 0..<sides {
            let a = bottomStart + i
            let b = bottomStart + (i + 1) % sides
            triangles += [bottomCenter, a, b]
        }
        for i in 0..<sides {
            let ta = topStart + i
            let tb = topStart + (i + 1) % sides
            let ba = bottomStart + i
            let bb = bottomStart + (i + 1) % sides
            triangles += [ta, ba, tb]
            triangles += [tb, ba, bb]
        }
        return orient(Mesh(vertices: vertices, triangles: triangles))
    }

    static func facetedCrystal(radius: Float = 0.78, height: Float = 1.7, sides: Int = 8) -> Mesh {
        var vertices: [SIMD3<Float>] = [
            SIMD3(0, height * 0.5, 0),
            SIMD3(0, -height * 0.5, 0)
        ]
        let upperStart = vertices.count
        for i in 0..<sides {
            let phi = 2 * Float.pi * Float(i) / Float(sides)
            vertices.append(SIMD3(radius * 0.68 * cos(phi), height * 0.20, radius * 0.68 * sin(phi)))
        }
        let lowerStart = vertices.count
        for i in 0..<sides {
            let phi = 2 * Float.pi * Float(i) / Float(sides) + Float.pi / Float(sides)
            vertices.append(SIMD3(radius * cos(phi), -height * 0.22, radius * sin(phi)))
        }

        var triangles: [Int] = []
        for i in 0..<sides {
            let ua = upperStart + i
            let ub = upperStart + (i + 1) % sides
            let la = lowerStart + i
            let lb = lowerStart + (i + 1) % sides
            triangles += [0, ua, ub]
            triangles += [ua, la, ub]
            triangles += [ub, la, lb]
            triangles += [1, lb, la]
        }
        return orient(Mesh(vertices: vertices, triangles: triangles))
    }

    static func elongatedBipyramid(radius: Float = 0.72, height: Float = 1.9, sides: Int = 10) -> Mesh {
        var vertices: [SIMD3<Float>] = [
            SIMD3(0, height * 0.5, 0),
            SIMD3(0, -height * 0.5, 0)
        ]
        let beltStart = vertices.count
        for i in 0..<sides {
            let phi = 2 * Float.pi * Float(i) / Float(sides)
            let wave = i.isMultiple(of: 2) ? radius : radius * 0.82
            vertices.append(SIMD3(wave * cos(phi), 0, wave * sin(phi)))
        }

        var triangles: [Int] = []
        for i in 0..<sides {
            let a = beltStart + i
            let b = beltStart + (i + 1) % sides
            triangles += [0, a, b]
            triangles += [1, b, a]
        }
        return orient(Mesh(vertices: vertices, triangles: triangles))
    }

    static func asymmetricPrism(height: Float = 1.55) -> Mesh {
        let points: [SIMD2<Float>] = [
            SIMD2(0.18, 0.86),
            SIMD2(0.72, 0.38),
            SIMD2(0.66, -0.34),
            SIMD2(0.10, -0.72),
            SIMD2(-0.58, -0.56),
            SIMD2(-0.82, 0.08),
            SIMD2(-0.36, 0.68)
        ]
        return polygonPrism(points: points, height: height)
    }

    static func razorCrystal(radius: Float = 0.54, height: Float = 2.05) -> Mesh {
        var mesh = facetedCrystal(radius: radius, height: height, sides: 10)
        for i in mesh.vertices.indices {
            mesh.vertices[i].x *= 0.62
            mesh.vertices[i].z *= i.isMultiple(of: 2) ? 1.18 : 0.88
        }
        return orient(mesh)
    }

    static func skewedTower(height: Float = 1.75, sides: Int = 7) -> Mesh {
        var vertices: [SIMD3<Float>] = []
        var triangles: [Int] = []
        let h = height * 0.5
        let topOffset = SIMD2<Float>(0.22, -0.12)
        let bottomOffset = SIMD2<Float>(-0.16, 0.10)

        let topCenter = vertices.count
        vertices.append(SIMD3(topOffset.x, h, topOffset.y))
        let bottomCenter = vertices.count
        vertices.append(SIMD3(bottomOffset.x, -h, bottomOffset.y))

        let topStart = vertices.count
        for i in 0..<sides {
            let phi = 2 * Float.pi * Float(i) / Float(sides) + 0.34
            let r: Float = i.isMultiple(of: 2) ? 0.54 : 0.68
            vertices.append(SIMD3(topOffset.x + r * cos(phi), h, topOffset.y + r * sin(phi)))
        }

        let bottomStart = vertices.count
        for i in 0..<sides {
            let phi = 2 * Float.pi * Float(i) / Float(sides) - 0.18
            let r: Float = i.isMultiple(of: 2) ? 0.76 : 0.58
            vertices.append(SIMD3(bottomOffset.x + r * cos(phi), -h, bottomOffset.y + r * sin(phi)))
        }

        for i in 0..<sides {
            let a = topStart + i
            let b = topStart + (i + 1) % sides
            triangles += [topCenter, b, a]
        }
        for i in 0..<sides {
            let a = bottomStart + i
            let b = bottomStart + (i + 1) % sides
            triangles += [bottomCenter, a, b]
        }
        for i in 0..<sides {
            let ta = topStart + i
            let tb = topStart + (i + 1) % sides
            let ba = bottomStart + i
            let bb = bottomStart + (i + 1) % sides
            triangles += [ta, ba, tb]
            triangles += [tb, ba, bb]
        }
        return orient(Mesh(vertices: vertices, triangles: triangles))
    }

    static func fracturedGem(radius: Float = 0.78, height: Float = 1.68, sides: Int = 9) -> Mesh {
        var vertices: [SIMD3<Float>] = [
            SIMD3(0.12, height * 0.5, -0.08),
            SIMD3(-0.10, -height * 0.5, 0.12)
        ]
        let upperStart = vertices.count
        for i in 0..<sides {
            let phi = 2 * Float.pi * Float(i) / Float(sides)
            let r = radius * (i.isMultiple(of: 3) ? 0.54 : 0.74)
            vertices.append(SIMD3(r * cos(phi) + 0.08, height * 0.18, r * sin(phi) - 0.04))
        }
        let lowerStart = vertices.count
        for i in 0..<sides {
            let phi = 2 * Float.pi * Float(i) / Float(sides) + 0.28
            let r = radius * (i.isMultiple(of: 2) ? 0.94 : 0.66)
            vertices.append(SIMD3(r * cos(phi) - 0.06, -height * 0.24, r * sin(phi) + 0.05))
        }

        var triangles: [Int] = []
        for i in 0..<sides {
            let ua = upperStart + i
            let ub = upperStart + (i + 1) % sides
            let la = lowerStart + i
            let lb = lowerStart + (i + 1) % sides
            triangles += [0, ua, ub]
            triangles += [ua, la, ub]
            triangles += [ub, la, lb]
            triangles += [1, lb, la]
        }
        return orient(Mesh(vertices: vertices, triangles: triangles))
    }

    static func serratedBipyramid(radius: Float = 0.82, height: Float = 1.8, sides: Int = 14) -> Mesh {
        var vertices: [SIMD3<Float>] = [
            SIMD3(0.05, height * 0.5, -0.03),
            SIMD3(-0.08, -height * 0.5, 0.06)
        ]
        let beltStart = vertices.count
        for i in 0..<sides {
            let phi = 2 * Float.pi * Float(i) / Float(sides)
            let r = radius * (i.isMultiple(of: 2) ? 1.0 : 0.58)
            let y: Float = i.isMultiple(of: 3) ? 0.08 : -0.04
            vertices.append(SIMD3(r * cos(phi), y, r * sin(phi)))
        }

        var triangles: [Int] = []
        for i in 0..<sides {
            let a = beltStart + i
            let b = beltStart + (i + 1) % sides
            triangles += [0, a, b]
            triangles += [1, b, a]
        }
        return orient(Mesh(vertices: vertices, triangles: triangles))
    }

    static func chaosPolyhedron() -> Mesh {
        var mesh = icosahedron(radius: 0.86)
        for i in mesh.vertices.indices {
            var v = mesh.vertices[i]
            let scale: Float
            switch i % 5 {
            case 0: scale = 1.12
            case 1: scale = 0.82
            case 2: scale = 1.03
            case 3: scale = 0.92
            default: scale = 1.22
            }
            v.x *= scale * (i.isMultiple(of: 2) ? 1.12 : 0.84)
            v.y *= scale * (i.isMultiple(of: 3) ? 0.88 : 1.16)
            v.z *= scale * (i.isMultiple(of: 4) ? 1.20 : 0.9)
            mesh.vertices[i] = v
        }
        return orient(mesh)
    }

    private static func prism(
        sides: Int,
        radius: Float,
        height: Float,
        startAngle: Float = 0
    ) -> Mesh {
        var vertices: [SIMD3<Float>] = []
        var triangles: [Int] = []
        let h = height * 0.5

        let topCenter = vertices.count
        vertices.append(SIMD3(0, h, 0))
        let bottomCenter = vertices.count
        vertices.append(SIMD3(0, -h, 0))

        let topStart = vertices.count
        for i in 0..<sides {
            let phi = startAngle + 2 * Float.pi * Float(i) / Float(sides)
            vertices.append(SIMD3(radius * cos(phi), h, radius * sin(phi)))
        }
        let bottomStart = vertices.count
        for i in 0..<sides {
            let phi = startAngle + 2 * Float.pi * Float(i) / Float(sides)
            vertices.append(SIMD3(radius * cos(phi), -h, radius * sin(phi)))
        }

        for i in 0..<sides {
            let a = topStart + i
            let b = topStart + (i + 1) % sides
            triangles += [topCenter, b, a]
        }
        for i in 0..<sides {
            let a = bottomStart + i
            let b = bottomStart + (i + 1) % sides
            triangles += [bottomCenter, a, b]
        }
        for i in 0..<sides {
            let ta = topStart + i
            let tb = topStart + (i + 1) % sides
            let ba = bottomStart + i
            let bb = bottomStart + (i + 1) % sides
            triangles += [ta, ba, tb]
            triangles += [tb, ba, bb]
        }
        return orient(Mesh(vertices: vertices, triangles: triangles))
    }

    private static func polygonPrism(points: [SIMD2<Float>], height: Float) -> Mesh {
        var vertices: [SIMD3<Float>] = []
        var triangles: [Int] = []
        let h = height * 0.5

        let topCenter = vertices.count
        vertices.append(SIMD3(0, h, 0))
        let bottomCenter = vertices.count
        vertices.append(SIMD3(0, -h, 0))

        let topStart = vertices.count
        for point in points {
            vertices.append(SIMD3(point.x, h, point.y))
        }
        let bottomStart = vertices.count
        for point in points {
            vertices.append(SIMD3(point.x, -h, point.y))
        }

        for i in points.indices {
            let next = (i + 1) % points.count
            let ta = topStart + i
            let tb = topStart + next
            let ba = bottomStart + i
            let bb = bottomStart + next
            triangles += [topCenter, tb, ta]
            triangles += [bottomCenter, ba, bb]
            triangles += [ta, ba, tb]
            triangles += [tb, ba, bb]
        }
        return orient(Mesh(vertices: vertices, triangles: triangles))
    }

    // MARK: - Winding correction
    // 각 삼각형의 외적 방향이 (face_center − mesh_center) 방향과 같도록 맞춤.
    // convex 도형에 대해 안전.
    private static func orient(_ mesh: Mesh) -> Mesh {
        let count = mesh.vertices.count
        guard count > 0 else { return mesh }

        var sum: SIMD3<Float> = .zero
        for v in mesh.vertices { sum += v }
        let center = sum / Float(count)

        var m = mesh
        var i = 0
        while i < m.triangles.count {
            let a = m.vertices[m.triangles[i]]
            let b = m.vertices[m.triangles[i + 1]]
            let c = m.vertices[m.triangles[i + 2]]
            let faceCenter = (a + b + c) / 3
            let outward = faceCenter - center
            if simd_length_squared(outward) > 1e-12 {
                let normal = simd_cross(b - a, c - a)
                if simd_dot(outward, normal) < 0 {
                    m.triangles.swapAt(i + 1, i + 2)
                }
            }
            i += 3
        }
        return m
    }
}
