import SwiftUI

struct MainView: View {
    @Binding var path: [Route]
    @Environment(ProgressStore.self) private var progress
    @State private var cutTrail: [CGPoint] = []
    @State private var trailOpacity: Double = 0

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.10, green: 0.12, blue: 0.23),
                         Color(red: 0.24, green: 0.17, blue: 0.36)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                HStack {
                    Spacer()
                    Button {
                        SoundManager.shared.playEffect(.click)
                        path.append(.settings)
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(12)
                            .background(.black.opacity(0.28))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 10)

                Spacer()

                VStack(spacing: 8) {
                    Text("PERFECT")
                        .font(.system(size: 52, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Text("SPLIT")
                        .font(.system(size: 52, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.cyan, .pink],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                }
                .shadow(color: .black.opacity(0.4), radius: 10)

                Spacer()

                VStack(spacing: 14) {
                    MenuButton(title: "시작", primary: true) {
                        path.append(.game(nextToPlay, .easy))
                    }
                    MenuButton(title: "스테이지 선택") {
                        path.append(.stageSelect)
                    }
                    MenuButton(title: "연속 모드") {
                        path.append(.continuous)
                    }
                }
                .padding(.horizontal, 40)

                Spacer().frame(height: 60)
            }

            if !cutTrail.isEmpty {
                MainCutTrail(points: cutTrail)
                    .stroke(
                        LinearGradient(
                            colors: [.green, .mint, .white],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round)
                    )
                    .opacity(trailOpacity)
                    .shadow(color: .green.opacity(0.65), radius: 10)
                    .allowsHitTesting(false)
            }
        }
        .contentShape(Rectangle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 14)
                .onChanged { value in
                    if cutTrail.isEmpty {
                        cutTrail = [value.startLocation]
                    }
                    cutTrail.append(value.location)
                    trailOpacity = 1
                }
                .onEnded { value in
                    cutTrail.append(value.location)
                    withAnimation(.easeOut(duration: 0.32)) {
                        trailOpacity = 0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.34) {
                        cutTrail.removeAll()
                    }
                }
        )
        .toolbar(.hidden, for: .navigationBar)
    }

    private var nextToPlay: Stage {
        for stage in StageCatalog.allStages where progress.stars(for: stage, mode: .easy) == 0 {
            return stage
        }
        return StageCatalog.firstStage
    }
}

private struct MainCutTrail: Shape {
    let points: [CGPoint]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: first)
        for point in points.dropFirst() {
            path.addLine(to: point)
        }
        return path
    }
}

private struct MenuButton: View {
    let title: String
    var primary: Bool = false
    let action: () -> Void

    var body: some View {
        Button {
            SoundManager.shared.playEffect(.click)
            action()
        } label: {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(primary ? .black : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(primary ? AnyShapeStyle(.white) : AnyShapeStyle(.white.opacity(0.15)))
                .clipShape(Capsule())
        }
    }
}
