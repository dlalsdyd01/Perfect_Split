import Foundation

enum Grade {
    case divine, perfect, great, good, close, miss

    var label: String {
        switch self {
        case .divine:  return "DIVINE"
        case .perfect: return "PERFECT"
        case .great:   return "GREAT"
        case .good:    return "GOOD"
        case .close:   return "CLOSE"
        case .miss:    return "MISS"
        }
    }

    var triggersEpicEffect: Bool { self == .divine || self == .perfect }
}

struct CutStats {
    let leftPercent: Double
    let rightPercent: Double

    var errorPercent: Double {
        (50.0 - min(leftPercent, rightPercent)) * 2.0
    }

    var grade: Grade {
        let e = errorPercent
        if e <= 0.1 { return .divine }
        if e <= 0.5 { return .perfect }
        if e <= 2.0 { return .great }
        if e <= 5.0 { return .good }
        if e <= 7.5 { return .close }
        return .miss
    }
}
