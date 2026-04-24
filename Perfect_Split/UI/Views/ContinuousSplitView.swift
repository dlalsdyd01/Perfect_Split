import SwiftUI
import SceneKit

struct ContinuousSplitView: View {
    @Binding var path: [Route]

    @State private var controller = ContinuousSplitController()
    @State private var streak = 0
    @State private var bestStreak = UserDefaults.standard.integer(forKey: "perfect_split.continuous.best.v1")
    @State private var lastStats: CutStats?
    @State private var isResolving = false
    @State private var gameOver = false
    @State private var rotationEnabled = false
    @State private var extraLifeUsed = false

    private let tolerance = 10.0

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.07, blue: 0.12),
                    Color(red: 0.04, green: 0.14, blue: 0.10)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            SceneKitView(
                scene: controller.scene,
                allowsCameraControl: gameOver,
                swipeEnabled: !isResolving && !gameOver && !rotationEnabled,
                rotationEnabled: !isResolving && !gameOver && rotationEnabled
            ) { start, end, view in
                guard !isResolving, !gameOver else { return }
                guard controller.canCut(from: start, to: end, in: view) else { return }
                guard let plane = SwipeToPlaneConverter.plane(from: start, to: end, in: view) else { return }
                guard let result = controller.cut(along: plane, tolerance: tolerance) else { return }
                SoundManager.shared.playEffect(.slice)
                handle(result)
            } onRotate: { delta in
                controller.rotateActiveShape(by: delta)
            }

            VStack {
                topBar
                Spacer()

                if let lastStats {
                    statusPanel(stats: lastStats)
                        .padding(.horizontal, 18)
                        .padding(.bottom, gameOver ? 18 : 34)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                if !gameOver, !isResolving {
                    rotateToggle
                        .padding(.bottom, 24)
                }

                if gameOver {
                    gameOverPanel
                        .padding(.horizontal, 18)
                        .padding(.bottom, 32)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var topBar: some View {
        HStack {
            Button {
                path.removeLast()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(.black.opacity(0.3))
                    .clipShape(Circle())
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("연속 모드")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("오차 \(Int(tolerance))% 이내")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.62))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text("\(streak)")
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundStyle(.mint)
                Text("BEST \(bestStreak)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.62))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private func statusPanel(stats: CutStats) -> some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(gameOver ? "FAILED" : "PASS")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(gameOver ? .red : .mint)
                Text(String(format: "%.1f%% / %.1f%%", stats.leftPercent, stats.rightPercent))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))
            }
            Spacer()
            Text(String(format: "오차 %.2f%%", stats.errorPercent))
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(.black.opacity(0.45))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var gameOverPanel: some View {
        VStack(spacing: 12) {
            Text("\(streak)번 성공")
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            if !extraLifeUsed {
                Button {
                    watchAdForExtraLife()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "play.rectangle.fill")
                            .font(.system(size: 15, weight: .bold))
                        Text("광고 보고 계속")
                            .font(.system(size: 15, weight: .bold))
                    }
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(.mint)
                    .clipShape(Capsule())
                }
            }

            ShareLink(
                item: continuousShareText,
                subject: Text("Perfect Split 연속 모드 기록"),
                message: Text("내 연속 모드 기록을 공유해요.")
            ) {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 15, weight: .bold))
                    Text("공유")
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(.white.opacity(0.14))
                .clipShape(Capsule())
            }

            HStack(spacing: 10) {
                Button {
                    path.removeAll()
                } label: {
                    Text("메뉴")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(.white.opacity(0.14))
                        .clipShape(Capsule())
                }

                Button {
                    restart()
                } label: {
                    Text("다시")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(.white)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .background(.black.opacity(0.58))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var continuousShareText: String {
        """
        Perfect Split

        연속 모드 기록: \(streak)번 성공
        내 최고 기록: BEST \(bestStreak)

        정확히 반으로 자르는 3D 퍼즐 게임
        #PerfectSplit
        """
    }

    private var rotateToggle: some View {
        Button {
            rotationEnabled.toggle()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: rotationEnabled ? "scissors" : "rotate.3d")
                    .font(.system(size: 16, weight: .bold))
                Text(rotationEnabled ? "커트" : "회전")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
            }
            .foregroundStyle(rotationEnabled ? .black : .white)
            .padding(.horizontal, 22)
            .padding(.vertical, 13)
            .background(rotationEnabled ? AnyShapeStyle(.white) : AnyShapeStyle(.black.opacity(0.35)))
            .clipShape(Capsule())
        }
    }

    private func handle(_ result: ContinuousCutResult) {
        isResolving = true
        rotationEnabled = false
        withAnimation(.easeOut(duration: 0.22)) {
            lastStats = result.stats
            gameOver = !result.passed
        }

        if result.passed {
            SoundManager.shared.playEffect(.clear)
            streak += 1
            saveBestIfNeeded()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.72) {
                controller.continueWithNextPiece()
                withAnimation(.easeOut(duration: 0.18)) {
                    lastStats = nil
                }
                isResolving = false
            }
        } else {
            SoundManager.shared.playEffect(.fail)
            saveBestIfNeeded()
            isResolving = false
        }
    }

    private func watchAdForExtraLife() {
        guard !extraLifeUsed else { return }
        isResolving = true
        AdService.shared.showRewardedExtraLife {
            extraLifeUsed = true
            controller.continueWithNextPiece()
            withAnimation(.easeOut(duration: 0.22)) {
                lastStats = nil
                gameOver = false
            }
            isResolving = false
        }
    }

    private func restart() {
        controller.reset()
        streak = 0
        lastStats = nil
        isResolving = false
        gameOver = false
        rotationEnabled = false
        extraLifeUsed = false
    }

    private func saveBestIfNeeded() {
        guard streak > bestStreak else { return }
        bestStreak = streak
        UserDefaults.standard.set(streak, forKey: "perfect_split.continuous.best.v1")
    }
}
