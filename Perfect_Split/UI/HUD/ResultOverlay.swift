import SwiftUI

struct ResultOverlay: View {
    let stage: Stage
    let stats: CutStats
    let awardedDivisionShard: Bool
    let onNext: () -> Void
    let onRetry: () -> Void
    let onMenu: () -> Void

    private var grade: Grade { stage.grade(for: stats) }
    private var stars: Int { stage.stars(for: stats) }
    private var nextStage: Stage? { StageCatalog.stage(after: stage) }
    private var starColor: Color {
        grade == .divine ? .red : .yellow
    }

    var body: some View {
        VStack(spacing: 14) {
            Text(grade.label)
                .font(.system(size: 40, weight: .heavy, design: .rounded))
                .foregroundStyle(gradeColor)
                .shadow(color: gradeColor.opacity(0.6), radius: 10)

            HStack(spacing: 6) {
                ForEach(0..<3) { i in
                    Image(systemName: i < stars ? "star.fill" : "star")
                        .font(.system(size: 26))
                        .foregroundStyle(i < stars ? starColor : .white.opacity(0.3))
                }
            }

            HStack(spacing: 14) {
                Text(String(format: "%.1f%%", stats.leftPercent))
                Text("|").foregroundStyle(.white.opacity(0.5))
                Text(String(format: "%.1f%%", stats.rightPercent))
            }
            .font(.system(size: 18, weight: .medium, design: .rounded))
            .foregroundStyle(.white)

            Text(String(format: "오차 %.2f%%  /  기준 %.1f%%", stats.errorPercent, stage.targetError))
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.6))

            if awardedDivisionShard {
                HStack(spacing: 8) {
                    Image(systemName: "diamond.fill")
                        .font(.system(size: 12, weight: .bold))
                    Text("디바인 조각 +1")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                }
                .foregroundStyle(.black)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white)
                .clipShape(Capsule())
            }

            HStack(spacing: 10) {
                OverlayButton(title: "메뉴", style: .secondary, action: onMenu)
                OverlayButton(title: "재도전", style: .secondary, action: onRetry)
                if stars >= 1, nextStage != nil {
                    OverlayButton(title: "다음", style: .primary, action: onNext)
                }
            }
            .padding(.top, 6)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 22)
        .background(.black.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .padding(.horizontal, 16)
    }

    private var gradeColor: Color {
        switch grade {
        case .divine:  return Color(red: 1.0, green: 0.4, blue: 0.9)
        case .perfect: return .yellow
        case .great:   return .green
        case .good:    return .cyan
        case .close:   return .orange
        case .miss:    return .red
        }
    }
}

private struct OverlayButton: View {
    enum Style { case primary, secondary }
    let title: String
    let style: Style
    let action: () -> Void

    var body: some View {
        Button {
            SoundManager.shared.playEffect(.click)
            action()
        } label: {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(style == .primary ? .black : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(style == .primary ? AnyShapeStyle(.white) : AnyShapeStyle(.white.opacity(0.15)))
                .clipShape(Capsule())
        }
    }
}
