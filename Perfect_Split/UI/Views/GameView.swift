import SwiftUI
import SceneKit

struct GameView: View {
    @Binding var path: [Route]
    @Environment(ProgressStore.self) private var progress

    @State private var controller: ShapeController
    @State private var currentStage: Stage
    @State private var currentMode: GameMode
    @State private var stats: CutStats?
    @State private var effectPlaying: Bool = false
    @State private var flashOpacity: Double = 0
    @State private var easyRotationEnabled: Bool = false
    @State private var hasRotatedForTutorial: Bool = false
    @State private var awardedDivisionShard: Bool = false
    @State private var rotationPinned: Bool = false
    @State private var pinnedOrientation: simd_quatf?

    init(path: Binding<[Route]>, stage: Stage, mode: GameMode) {
        self._path = path
        self._currentStage = State(initialValue: stage)
        self._currentMode = State(initialValue: mode)
        self._controller = State(initialValue: ShapeController(stage: stage, mode: mode))
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.10, green: 0.12, blue: 0.23),
                         Color(red: 0.24, green: 0.17, blue: 0.36)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            SceneKitView(
                scene: controller.scene,
                allowsCameraControl: stats != nil,
                swipeEnabled: canSwipeToCut,
                rotationEnabled: currentMode == .easy && stats == nil && !effectPlaying && easyRotationEnabled
            ) { start, end, view in
                guard stats == nil, !effectPlaying else { return }
                guard controller.canCut(from: start, to: end, in: view) else { return }
                guard let plane = SwipeToPlaneConverter.plane(from: start, to: end, in: view) else { return }
                if let result = controller.cut(along: plane) {
                    SoundManager.shared.playEffect(.slice)
                    let grade = currentStage.grade(for: result)
                    let earned = currentStage.stars(for: result)
                    awardedDivisionShard = false
                    if earned > 0 {
                        progress.record(stars: earned, for: currentStage, mode: currentMode)
                    }
                    if grade == .divine {
                        awardedDivisionShard = progress.recordDivine(for: currentStage, mode: currentMode)
                    }
                    if grade.triggersEpicEffect {
                        effectPlaying = true

                        // DIVINE: 펄스 순간 흰색 플래시
                        if grade == .divine {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                                withAnimation(.easeOut(duration: 0.06)) { flashOpacity = 0.8 }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
                                    withAnimation(.easeIn(duration: 0.4)) { flashOpacity = 0 }
                                }
                            }
                        }

                        let bannerDelay: Double = grade == .divine ? 3.8 : 3.2
                        DispatchQueue.main.asyncAfter(deadline: .now() + bannerDelay) {
                            withAnimation(.easeOut(duration: 0.45)) {
                                stats = result
                            }
                            effectPlaying = false
                            if earned > 0 {
                                AdService.shared.showInterstitialAtNaturalBreak()
                            }
                        }
                    } else {
                        if earned > 0 {
                            SoundManager.shared.playEffect(.clear)
                        } else {
                            SoundManager.shared.playEffect(.fail)
                        }
                        withAnimation(.easeOut(duration: 0.3)) {
                            stats = result
                        }
                        if earned > 0 {
                            AdService.shared.showInterstitialAtNaturalBreak()
                        }
                    }
                }
            } onRotate: { delta in
                controller.rotateActiveShape(by: delta)
                if rotationPinned {
                    pinnedOrientation = controller.currentOrientation()
                }
                if currentStage.id == "1-2", currentMode == .easy, hypot(delta.x, delta.y) > 1 {
                    hasRotatedForTutorial = true
                }
            }

            if showsTutorialGuide {
                TutorialCutGuide()
                    .transition(.opacity)
                    .allowsHitTesting(false)
            }

            if showsRotationTutorial {
                RotationTutorialGuide()
                    .transition(.opacity)
                    .allowsHitTesting(false)
            }

            VStack {
                HStack {
                    Button {
                        goBack()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(10)
                            .background(.black.opacity(0.3))
                            .clipShape(Circle())
                    }

                    Text(currentStage.title)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.black.opacity(0.3))
                        .clipShape(Capsule())
                    Text(currentMode.title)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(.black.opacity(0.25))
                        .clipShape(Capsule())
                    Spacer()
                    Button {
                        path.removeAll()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(10)
                            .background(.black.opacity(0.3))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                Spacer()

                if canManuallyRotate, stats == nil, !effectPlaying {
                    HStack(spacing: 10) {
                        Button {
                            easyRotationEnabled.toggle()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: easyRotationEnabled ? "scissors" : "rotate.3d")
                                    .font(.system(size: 16, weight: .bold))
                                Text(easyRotationEnabled ? "커트" : "회전")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                            }
                            .foregroundStyle(easyRotationEnabled ? .black : .white)
                            .padding(.horizontal, 22)
                            .padding(.vertical, 13)
                            .background(easyRotationEnabled ? AnyShapeStyle(.white) : AnyShapeStyle(.black.opacity(0.35)))
                            .clipShape(Capsule())
                        }

                        Button {
                            if rotationPinned {
                                rotationPinned = false
                                pinnedOrientation = nil
                            } else {
                                rotationPinned = true
                                pinnedOrientation = controller.currentOrientation()
                            }
                        } label: {
                            Image(systemName: rotationPinned ? "pin.fill" : "pin")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(rotationPinned ? .black : .white)
                                .frame(width: 46, height: 46)
                                .background(rotationPinned ? AnyShapeStyle(.white) : AnyShapeStyle(.black.opacity(0.35)))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.bottom, 24)
                }

                if let stats {
                    ResultOverlay(
                        stage: currentStage,
                        stats: stats,
                        awardedDivisionShard: awardedDivisionShard,
                        onNext: goToNext,
                        onRetry: retry,
                        onMenu: { path.removeAll() }
                    )
                    .padding(.bottom, 40)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }

            Color.white
                .opacity(flashOpacity)
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var showsTutorialGuide: Bool {
        currentStage.id == "1-1"
            && currentMode == .easy
            && stats == nil
            && !effectPlaying
            && !easyRotationEnabled
    }

    private var showsRotationTutorial: Bool {
        currentStage.id == "1-2"
            && currentMode == .easy
            && stats == nil
            && !effectPlaying
            && !hasRotatedForTutorial
    }

    private var canManuallyRotate: Bool {
        currentMode == .easy && currentStage.id != "1-1"
    }

    private var canSwipeToCut: Bool {
        stats == nil
            && !effectPlaying
            && !easyRotationEnabled
            && !requiresRotationTutorial
    }

    private var requiresRotationTutorial: Bool {
        currentStage.id == "1-2"
            && currentMode == .easy
            && !hasRotatedForTutorial
    }

    private func goBack() {
        if path.isEmpty {
            return
        }
        path.removeLast()
    }

    private func retry() {
        easyRotationEnabled = false
        hasRotatedForTutorial = rotationPinned && pinnedOrientation != nil
        awardedDivisionShard = false
        controller.loadInitialShape()
        if rotationPinned, let pinnedOrientation {
            controller.setOrientation(pinnedOrientation)
        }
        withAnimation(.easeOut(duration: 0.2)) { stats = nil }
    }

    private func goToNext() {
        guard let next = StageCatalog.stage(after: currentStage) else { return }
        currentStage = next
        easyRotationEnabled = false
        hasRotatedForTutorial = false
        awardedDivisionShard = false
        rotationPinned = false
        pinnedOrientation = nil
        controller.setStage(next, mode: currentMode)
        withAnimation(.easeOut(duration: 0.2)) { stats = nil }
    }
}

private struct TutorialCutGuide: View {
    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let top = CGPoint(x: size.width * 0.5, y: size.height * 0.26)
            let bottom = CGPoint(x: size.width * 0.5, y: size.height * 0.72)

            ZStack {
                CutGuideLine(start: top, end: bottom)
                    .stroke(
                        .white.opacity(0.92),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round, dash: [10, 10])
                    )
                    .shadow(color: .cyan.opacity(0.8), radius: 8)

                VStack(spacing: 7) {
                    Text("점선을 따라 자르세요")
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Text("위에서 아래로 한 번에 스와이프")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.72))
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(.black.opacity(0.42))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(.white.opacity(0.12), lineWidth: 1)
                )
                .position(x: size.width * 0.5, y: size.height * 0.79)
            }
        }
    }
}

private struct RotationTutorialGuide: View {
    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size

            VStack(spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "rotate.3d")
                        .font(.system(size: 18, weight: .black))
                    Text("회전 버튼으로 도형을 돌릴 수 있어요")
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .lineLimit(2)
                }

                HStack(spacing: 8) {
                    Image(systemName: "pin")
                        .font(.system(size: 15, weight: .black))
                    Text("핀을 누르면 실패 후에도 그 각도를 유지해요")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }

                Image(systemName: "chevron.down")
                    .font(.system(size: 17, weight: .black))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 13)
            .background(.black.opacity(0.44))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.white.opacity(0.12), lineWidth: 1)
            )
            .frame(maxWidth: min(size.width - 28, 360))
            .position(x: size.width * 0.5, y: size.height - 172)
        }
    }
}

private struct CutGuideLine: Shape {
    let start: CGPoint
    let end: CGPoint

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: start)
        path.addLine(to: end)
        return path
    }
}
