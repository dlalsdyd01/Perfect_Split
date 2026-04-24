import Foundation

enum ShapeType: String, Codable, Hashable {
    case cube
    case sphere
    case cylinder
    case cone
    case triangularPrism
    case hexagonalPrism
    case diamond
    case octahedron
    case icosahedron
    case pentagonalPrism
    case starPrism
    case twistedPrism
    case facetedCrystal
    case elongatedBipyramid
    case asymmetricPrism
    case razorCrystal
    case skewedTower
    case fracturedGem
    case serratedBipyramid
    case chaosPolyhedron
}

enum GameMode: String, CaseIterable, Codable, Hashable, Identifiable {
    case easy
    case hard

    var id: String { rawValue }

    var title: String {
        switch self {
        case .easy: return "Easy"
        case .hard: return "Hard"
        }
    }

    var rotatesShape: Bool {
        self == .hard
    }
}

struct Stage: Identifiable, Hashable, Codable {
    let id: String
    let chapter: Int
    let number: Int
    let shapeType: ShapeType
    let rotationSpeedMultiplier: Double
    let targetError: Double

    var title: String { "\(chapter)-\(number)" }

    func stars(for stats: CutStats) -> Int {
        switch grade(for: stats) {
        case .divine, .perfect: return 3
        case .great: return 2
        case .good: return 1
        case .close, .miss: return 0
        }
    }

    func grade(for stats: CutStats) -> Grade {
        let e = stats.errorPercent
        if e <= 0.1 { return .divine }
        if e <= 0.5 { return .perfect }
        if e <= targetError / 2 { return .great }
        if e <= targetError { return .good }
        if e <= targetError * 1.5 { return .close }
        return .miss
    }
}

struct Chapter: Identifiable, Hashable {
    let id: Int
    let title: String
    let stages: [Stage]
}

enum StageCatalog {
    static let chapters: [Chapter] = [
        Chapter(id: 1, title: "Chapter 1 · Cube", stages: [
            Stage(id: "1-1", chapter: 1, number: 1, shapeType: .cube, rotationSpeedMultiplier: 0.5, targetError: 10.0),
            Stage(id: "1-2", chapter: 1, number: 2, shapeType: .cube, rotationSpeedMultiplier: 0.9, targetError: 3.0),
            Stage(id: "1-3", chapter: 1, number: 3, shapeType: .cube, rotationSpeedMultiplier: 1.3, targetError: 2.0),
            Stage(id: "1-4", chapter: 1, number: 4, shapeType: .cube, rotationSpeedMultiplier: 1.7, targetError: 1.2),
        ]),
        Chapter(id: 2, title: "Chapter 2 · Cylinder", stages: [
            Stage(id: "2-1", chapter: 2, number: 1, shapeType: .cylinder, rotationSpeedMultiplier: 0.7, targetError: 4.5),
            Stage(id: "2-2", chapter: 2, number: 2, shapeType: .cylinder, rotationSpeedMultiplier: 1.1, targetError: 2.7),
            Stage(id: "2-3", chapter: 2, number: 3, shapeType: .cylinder, rotationSpeedMultiplier: 1.5, targetError: 1.7),
            Stage(id: "2-4", chapter: 2, number: 4, shapeType: .cylinder, rotationSpeedMultiplier: 1.9, targetError: 1.0),
        ]),
        Chapter(id: 3, title: "Chapter 3 · Sphere", stages: [
            Stage(id: "3-1", chapter: 3, number: 1, shapeType: .sphere, rotationSpeedMultiplier: 0.8, targetError: 4.0),
            Stage(id: "3-2", chapter: 3, number: 2, shapeType: .sphere, rotationSpeedMultiplier: 1.2, targetError: 2.5),
            Stage(id: "3-3", chapter: 3, number: 3, shapeType: .sphere, rotationSpeedMultiplier: 1.6, targetError: 1.5),
            Stage(id: "3-4", chapter: 3, number: 4, shapeType: .sphere, rotationSpeedMultiplier: 2.0, targetError: 0.9),
        ]),
        Chapter(id: 4, title: "Chapter 4 · Cone", stages: [
            Stage(id: "4-1", chapter: 4, number: 1, shapeType: .cone, rotationSpeedMultiplier: 0.9, targetError: 3.5),
            Stage(id: "4-2", chapter: 4, number: 2, shapeType: .cone, rotationSpeedMultiplier: 1.3, targetError: 2.2),
            Stage(id: "4-3", chapter: 4, number: 3, shapeType: .cone, rotationSpeedMultiplier: 1.7, targetError: 1.3),
            Stage(id: "4-4", chapter: 4, number: 4, shapeType: .cone, rotationSpeedMultiplier: 2.1, targetError: 0.9),
        ]),
        Chapter(id: 5, title: "Chapter 5 · Triangular Prism", stages: [
            Stage(id: "5-1", chapter: 5, number: 1, shapeType: .triangularPrism, rotationSpeedMultiplier: 1.0, targetError: 3.0),
            Stage(id: "5-2", chapter: 5, number: 2, shapeType: .triangularPrism, rotationSpeedMultiplier: 1.4, targetError: 1.8),
            Stage(id: "5-3", chapter: 5, number: 3, shapeType: .triangularPrism, rotationSpeedMultiplier: 1.8, targetError: 1.1),
            Stage(id: "5-4", chapter: 5, number: 4, shapeType: .triangularPrism, rotationSpeedMultiplier: 2.2, targetError: 0.8),
        ]),
        Chapter(id: 6, title: "Chapter 6 · Hexagonal Prism", stages: [
            Stage(id: "6-1", chapter: 6, number: 1, shapeType: .hexagonalPrism, rotationSpeedMultiplier: 1.1, targetError: 2.6),
            Stage(id: "6-2", chapter: 6, number: 2, shapeType: .hexagonalPrism, rotationSpeedMultiplier: 1.5, targetError: 1.6),
            Stage(id: "6-3", chapter: 6, number: 3, shapeType: .hexagonalPrism, rotationSpeedMultiplier: 1.9, targetError: 1.0),
            Stage(id: "6-4", chapter: 6, number: 4, shapeType: .hexagonalPrism, rotationSpeedMultiplier: 2.3, targetError: 0.7),
        ]),
        Chapter(id: 7, title: "Chapter 7 · Diamond", stages: [
            Stage(id: "7-1", chapter: 7, number: 1, shapeType: .diamond, rotationSpeedMultiplier: 1.2, targetError: 2.4),
            Stage(id: "7-2", chapter: 7, number: 2, shapeType: .diamond, rotationSpeedMultiplier: 1.6, targetError: 1.5),
            Stage(id: "7-3", chapter: 7, number: 3, shapeType: .diamond, rotationSpeedMultiplier: 2.0, targetError: 0.9),
            Stage(id: "7-4", chapter: 7, number: 4, shapeType: .diamond, rotationSpeedMultiplier: 2.4, targetError: 0.65),
        ]),
        Chapter(id: 8, title: "Chapter 8 · Octahedron", stages: [
            Stage(id: "8-1", chapter: 8, number: 1, shapeType: .octahedron, rotationSpeedMultiplier: 1.3, targetError: 2.2),
            Stage(id: "8-2", chapter: 8, number: 2, shapeType: .octahedron, rotationSpeedMultiplier: 1.7, targetError: 1.3),
            Stage(id: "8-3", chapter: 8, number: 3, shapeType: .octahedron, rotationSpeedMultiplier: 2.1, targetError: 0.85),
            Stage(id: "8-4", chapter: 8, number: 4, shapeType: .octahedron, rotationSpeedMultiplier: 2.5, targetError: 0.6),
        ]),
        Chapter(id: 9, title: "Chapter 9 · Icosahedron", stages: [
            Stage(id: "9-1", chapter: 9, number: 1, shapeType: .icosahedron, rotationSpeedMultiplier: 1.4, targetError: 2.0),
            Stage(id: "9-2", chapter: 9, number: 2, shapeType: .icosahedron, rotationSpeedMultiplier: 1.8, targetError: 1.2),
            Stage(id: "9-3", chapter: 9, number: 3, shapeType: .icosahedron, rotationSpeedMultiplier: 2.2, targetError: 0.8),
            Stage(id: "9-4", chapter: 9, number: 4, shapeType: .icosahedron, rotationSpeedMultiplier: 2.6, targetError: 0.55),
        ]),
        Chapter(id: 10, title: "Chapter 10 · Pentagonal Prism", stages: [
            Stage(id: "10-1", chapter: 10, number: 1, shapeType: .pentagonalPrism, rotationSpeedMultiplier: 1.5, targetError: 1.9),
            Stage(id: "10-2", chapter: 10, number: 2, shapeType: .pentagonalPrism, rotationSpeedMultiplier: 1.9, targetError: 1.1),
            Stage(id: "10-3", chapter: 10, number: 3, shapeType: .pentagonalPrism, rotationSpeedMultiplier: 2.3, targetError: 0.75),
            Stage(id: "10-4", chapter: 10, number: 4, shapeType: .pentagonalPrism, rotationSpeedMultiplier: 2.7, targetError: 0.5),
        ]),
        Chapter(id: 11, title: "Chapter 11 · Star Prism", stages: [
            Stage(id: "11-1", chapter: 11, number: 1, shapeType: .starPrism, rotationSpeedMultiplier: 1.6, targetError: 1.8),
            Stage(id: "11-2", chapter: 11, number: 2, shapeType: .starPrism, rotationSpeedMultiplier: 2.0, targetError: 1.05),
            Stage(id: "11-3", chapter: 11, number: 3, shapeType: .starPrism, rotationSpeedMultiplier: 2.4, targetError: 0.7),
            Stage(id: "11-4", chapter: 11, number: 4, shapeType: .starPrism, rotationSpeedMultiplier: 2.8, targetError: 0.48),
        ]),
        Chapter(id: 12, title: "Chapter 12 · Twisted Prism", stages: [
            Stage(id: "12-1", chapter: 12, number: 1, shapeType: .twistedPrism, rotationSpeedMultiplier: 1.7, targetError: 1.65),
            Stage(id: "12-2", chapter: 12, number: 2, shapeType: .twistedPrism, rotationSpeedMultiplier: 2.1, targetError: 1.0),
            Stage(id: "12-3", chapter: 12, number: 3, shapeType: .twistedPrism, rotationSpeedMultiplier: 2.5, targetError: 0.65),
            Stage(id: "12-4", chapter: 12, number: 4, shapeType: .twistedPrism, rotationSpeedMultiplier: 2.9, targetError: 0.45),
        ]),
        Chapter(id: 13, title: "Chapter 13 · Faceted Crystal", stages: [
            Stage(id: "13-1", chapter: 13, number: 1, shapeType: .facetedCrystal, rotationSpeedMultiplier: 1.8, targetError: 1.5),
            Stage(id: "13-2", chapter: 13, number: 2, shapeType: .facetedCrystal, rotationSpeedMultiplier: 2.2, targetError: 0.9),
            Stage(id: "13-3", chapter: 13, number: 3, shapeType: .facetedCrystal, rotationSpeedMultiplier: 2.6, targetError: 0.6),
            Stage(id: "13-4", chapter: 13, number: 4, shapeType: .facetedCrystal, rotationSpeedMultiplier: 3.0, targetError: 0.42),
        ]),
        Chapter(id: 14, title: "Chapter 14 · Long Bipyramid", stages: [
            Stage(id: "14-1", chapter: 14, number: 1, shapeType: .elongatedBipyramid, rotationSpeedMultiplier: 1.9, targetError: 1.35),
            Stage(id: "14-2", chapter: 14, number: 2, shapeType: .elongatedBipyramid, rotationSpeedMultiplier: 2.3, targetError: 0.82),
            Stage(id: "14-3", chapter: 14, number: 3, shapeType: .elongatedBipyramid, rotationSpeedMultiplier: 2.7, targetError: 0.55),
            Stage(id: "14-4", chapter: 14, number: 4, shapeType: .elongatedBipyramid, rotationSpeedMultiplier: 3.1, targetError: 0.4),
        ]),
        Chapter(id: 15, title: "Chapter 15 · Asymmetric Prism", stages: [
            Stage(id: "15-1", chapter: 15, number: 1, shapeType: .asymmetricPrism, rotationSpeedMultiplier: 2.0, targetError: 1.2),
            Stage(id: "15-2", chapter: 15, number: 2, shapeType: .asymmetricPrism, rotationSpeedMultiplier: 2.4, targetError: 0.72),
            Stage(id: "15-3", chapter: 15, number: 3, shapeType: .asymmetricPrism, rotationSpeedMultiplier: 2.8, targetError: 0.48),
            Stage(id: "15-4", chapter: 15, number: 4, shapeType: .asymmetricPrism, rotationSpeedMultiplier: 3.2, targetError: 0.35),
        ]),
        Chapter(id: 16, title: "Chapter 16 · Razor Crystal", stages: [
            Stage(id: "16-1", chapter: 16, number: 1, shapeType: .razorCrystal, rotationSpeedMultiplier: 2.1, targetError: 1.1),
            Stage(id: "16-2", chapter: 16, number: 2, shapeType: .razorCrystal, rotationSpeedMultiplier: 2.5, targetError: 0.68),
            Stage(id: "16-3", chapter: 16, number: 3, shapeType: .razorCrystal, rotationSpeedMultiplier: 2.9, targetError: 0.45),
            Stage(id: "16-4", chapter: 16, number: 4, shapeType: .razorCrystal, rotationSpeedMultiplier: 3.3, targetError: 0.32),
        ]),
        Chapter(id: 17, title: "Chapter 17 · Skewed Tower", stages: [
            Stage(id: "17-1", chapter: 17, number: 1, shapeType: .skewedTower, rotationSpeedMultiplier: 2.2, targetError: 1.0),
            Stage(id: "17-2", chapter: 17, number: 2, shapeType: .skewedTower, rotationSpeedMultiplier: 2.6, targetError: 0.62),
            Stage(id: "17-3", chapter: 17, number: 3, shapeType: .skewedTower, rotationSpeedMultiplier: 3.0, targetError: 0.42),
            Stage(id: "17-4", chapter: 17, number: 4, shapeType: .skewedTower, rotationSpeedMultiplier: 3.4, targetError: 0.3),
        ]),
        Chapter(id: 18, title: "Chapter 18 · Fractured Gem", stages: [
            Stage(id: "18-1", chapter: 18, number: 1, shapeType: .fracturedGem, rotationSpeedMultiplier: 2.3, targetError: 0.95),
            Stage(id: "18-2", chapter: 18, number: 2, shapeType: .fracturedGem, rotationSpeedMultiplier: 2.7, targetError: 0.58),
            Stage(id: "18-3", chapter: 18, number: 3, shapeType: .fracturedGem, rotationSpeedMultiplier: 3.1, targetError: 0.4),
            Stage(id: "18-4", chapter: 18, number: 4, shapeType: .fracturedGem, rotationSpeedMultiplier: 3.5, targetError: 0.28),
        ]),
        Chapter(id: 19, title: "Chapter 19 · Serrated Bipyramid", stages: [
            Stage(id: "19-1", chapter: 19, number: 1, shapeType: .serratedBipyramid, rotationSpeedMultiplier: 2.4, targetError: 0.9),
            Stage(id: "19-2", chapter: 19, number: 2, shapeType: .serratedBipyramid, rotationSpeedMultiplier: 2.8, targetError: 0.55),
            Stage(id: "19-3", chapter: 19, number: 3, shapeType: .serratedBipyramid, rotationSpeedMultiplier: 3.2, targetError: 0.38),
            Stage(id: "19-4", chapter: 19, number: 4, shapeType: .serratedBipyramid, rotationSpeedMultiplier: 3.6, targetError: 0.26),
        ]),
        Chapter(id: 20, title: "Chapter 20 · Chaos Polyhedron", stages: [
            Stage(id: "20-1", chapter: 20, number: 1, shapeType: .chaosPolyhedron, rotationSpeedMultiplier: 2.5, targetError: 0.85),
            Stage(id: "20-2", chapter: 20, number: 2, shapeType: .chaosPolyhedron, rotationSpeedMultiplier: 2.9, targetError: 0.52),
            Stage(id: "20-3", chapter: 20, number: 3, shapeType: .chaosPolyhedron, rotationSpeedMultiplier: 3.3, targetError: 0.36),
            Stage(id: "20-4", chapter: 20, number: 4, shapeType: .chaosPolyhedron, rotationSpeedMultiplier: 3.7, targetError: 0.25),
        ]),
    ]

    static var allStages: [Stage] { chapters.flatMap(\.stages) }

    static var firstStage: Stage { allStages.first! }

    static func stage(after current: Stage) -> Stage? {
        let all = allStages
        guard let i = all.firstIndex(of: current) else { return nil }
        return i + 1 < all.count ? all[i + 1] : nil
    }

    static func stage(before current: Stage) -> Stage? {
        let all = allStages
        guard let i = all.firstIndex(of: current), i > 0 else { return nil }
        return all[i - 1]
    }
}
