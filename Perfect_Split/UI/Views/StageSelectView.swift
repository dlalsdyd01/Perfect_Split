import SwiftUI

struct StageSelectView: View {
    @Binding var path: [Route]
    @Environment(ProgressStore.self) private var progress
    @State private var selectedMode: GameMode = .easy
    @State private var pendingLockedStage: Stage?
    @State private var adRewardMessage: String?
    @State private var isRequestingAdReward = false
    @State private var showDivineShardMenu = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.10, green: 0.12, blue: 0.23),
                         Color(red: 0.24, green: 0.17, blue: 0.36)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    HStack {
                        Spacer()

                        Button {
                            showDivineShardMenu = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "diamond.fill")
                                    .font(.system(size: 12, weight: .bold))
                                Text("디바인 조각")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                Text("\(progress.divisionShardCount)")
                                    .font(.system(size: 18, weight: .black, design: .rounded))
                            }
                            .foregroundStyle(.black)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(.white)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)

                        Button {
                            showDivineShardMenu = true
                        } label: {
                            Image(systemName: "questionmark.circle")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white.opacity(0.72))
                        }
                        .buttonStyle(.plain)
                    }

                    Picker("Mode", selection: $selectedMode) {
                        ForEach(GameMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)

                    ForEach(StageCatalog.chapters) { chapter in
                        ChapterSection(
                            chapter: chapter,
                            mode: selectedMode,
                            path: $path,
                            onRequestLockedStage: { pendingLockedStage = $0 }
                        )
                    }
                }
                .padding(20)
            }

            if showDivineShardMenu {
                Color.black.opacity(0.28)
                    .ignoresSafeArea()
                    .onTapGesture {
                        showDivineShardMenu = false
                    }

                DivineShardSheet(
                    isLoading: isRequestingAdReward,
                    onWatchAd: {
                        guard !isRequestingAdReward else { return }
                        isRequestingAdReward = true
                        AdService.shared.showRewardedDivisionShard {
                            progress.awardDivisionShardFromAd()
                            adRewardMessage = "광고 보상을 받아 디바인 조각 1개를 획득했어요."
                            isRequestingAdReward = false
                            showDivineShardMenu = false
                        } onUnavailable: {
                            adRewardMessage = "지금은 보상형 광고를 불러오지 못했어요. 잠시 후 다시 시도해 주세요."
                            isRequestingAdReward = false
                            showDivineShardMenu = false
                        }
                    },
                    onClose: {
                        showDivineShardMenu = false
                    }
                )
                .padding(.horizontal, 28)
                .transition(.scale(scale: 0.96).combined(with: .opacity))
                .zIndex(1)
            }

            if let stage = pendingLockedStage {
                Color.black.opacity(0.28)
                    .ignoresSafeArea()
                    .onTapGesture {
                        pendingLockedStage = nil
                    }

                LockedStageSheet(
                    stage: stage,
                    hasDivisionShard: progress.divisionShardCount > 0,
                    onUseShard: {
                        if progress.canUnlockWithDivision(stage, mode: selectedMode) {
                            if progress.unlockStageWithDivision(stage, mode: selectedMode) {
                                pendingLockedStage = nil
                                path.append(.game(stage, selectedMode))
                            }
                        }
                    },
                    onWatchAd: {
                        guard !isRequestingAdReward else { return }
                        isRequestingAdReward = true
                        AdService.shared.showRewardedDivisionShard {
                            if progress.unlockStageWithAd(stage, mode: selectedMode) {
                                pendingLockedStage = nil
                                path.append(.game(stage, selectedMode))
                            }
                            isRequestingAdReward = false
                        } onUnavailable: {
                            pendingLockedStage = nil
                            adRewardMessage = "지금은 보상형 광고를 불러오지 못했어요. 잠시 후 다시 시도해 주세요."
                            isRequestingAdReward = false
                        }
                    },
                    onClose: {
                        pendingLockedStage = nil
                    }
                )
                .padding(.horizontal, 28)
                .transition(.scale(scale: 0.96).combined(with: .opacity))
                .zIndex(2)
            }
        }
        .navigationTitle("스테이지")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .alert(
            "디바인 조각",
            isPresented: Binding(
                get: { adRewardMessage != nil },
                set: { if !$0 { adRewardMessage = nil } }
            ),
            actions: {
                Button("확인", role: .cancel) {
                    adRewardMessage = nil
                }
            },
            message: {
                Text(adRewardMessage ?? "")
            }
        )
    }
}

private struct DivineShardSheet: View {
    let isLoading: Bool
    let onWatchAd: () -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("디바인 조각")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Text("스테이지를 Divine으로 쪼갤 때마다 한 스테이지당 1개씩 지급됩니다.")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.72))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(8)
                        .background(.white.opacity(0.08))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }

            Button(action: onWatchAd) {
                HStack(spacing: 10) {
                    Image(systemName: "play.rectangle.fill")
                        .font(.system(size: 15, weight: .bold))
                    Text(isLoading ? "광고 준비 중..." : "광고 보고 디바인 조각 +1")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(.white.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.10), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .disabled(isLoading)
        }
        .padding(22)
        .background(.black.opacity(0.52))
        .clipShape(RoundedRectangle(cornerRadius: 26))
        .overlay(
            RoundedRectangle(cornerRadius: 26)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.28), radius: 20, y: 10)
    }
}

private struct ChapterSection: View {
    let chapter: Chapter
    let mode: GameMode
    @Binding var path: [Route]
    let onRequestLockedStage: (Stage) -> Void

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: 12), count: 4
    )

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(chapter.title)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.8))
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(chapter.stages) { stage in
                    StageCell(
                        stage: stage,
                        mode: mode,
                        path: $path,
                        onRequestLockedStage: onRequestLockedStage
                    )
                }
            }
        }
    }
}

private struct StageCell: View {
    let stage: Stage
    let mode: GameMode
    @Binding var path: [Route]
    let onRequestLockedStage: (Stage) -> Void
    @Environment(ProgressStore.self) private var progress

    private var stars: Int { progress.stars(for: stage, mode: mode) }
    private var unlocked: Bool { progress.isStageUnlocked(stage, mode: mode) }
    private var canUnlockWithDivision: Bool { progress.canUnlockWithDivision(stage, mode: mode) }
    private var starColor: Color {
        progress.isDivine(stage, mode: mode) ? .red : .yellow
    }

    var body: some View {
        Button {
            SoundManager.shared.playEffect(.click)
            if unlocked {
                path.append(.game(stage, mode))
            } else {
                onRequestLockedStage(stage)
            }
        } label: {
            VStack(spacing: 6) {
                HStack(spacing: 5) {
                    if !unlocked {
                        Image(systemName: canUnlockWithDivision ? "diamond.fill" : "lock.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(canUnlockWithDivision ? .white.opacity(0.82) : .white.opacity(0.58))
                    }
                    Text(stage.title)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(unlocked ? .white : .white.opacity(0.62))
                }

                if unlocked {
                    HStack(spacing: 2) {
                        ForEach(0..<3) { i in
                            Image(systemName: i < stars ? "star.fill" : "star")
                                .font(.system(size: 9))
                                .foregroundStyle(i < stars ? starColor : .white.opacity(0.3))
                        }
                    }
                } else {
                    Text(canUnlockWithDivision ? "조각 1개" : "LOCKED")
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .foregroundStyle(canUnlockWithDivision ? .white.opacity(0.62) : .white.opacity(0.34))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(unlocked ? .white.opacity(0.12) : (canUnlockWithDivision ? .white.opacity(0.08) : .white.opacity(0.04)))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(unlocked ? .clear : (canUnlockWithDivision ? .white.opacity(0.18) : .white.opacity(0.08)), lineWidth: 1)
            )
        }
        .opacity(unlocked || progress.canUnlockWithAd(stage, mode: mode) ? 1 : 0.4)
    }
}

private struct LockedStageSheet: View {
    let stage: Stage
    let hasDivisionShard: Bool
    let onUseShard: () -> Void
    let onWatchAd: () -> Void
    let onClose: () -> Void
    @State private var showMissingShardMessage = false

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(stage.title)
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                }

                Spacer()

                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(8)
                        .background(.white.opacity(0.08))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }

            VStack(spacing: 10) {
                LockedStageActionButton(
                    title: "광고 보고 열기",
                    icon: "play.rectangle.fill",
                    action: onWatchAd
                )

                LockedStageActionButton(
                    title: "디바인 조각으로 열기",
                    icon: "diamond.fill",
                    action: {
                        if hasDivisionShard {
                            showMissingShardMessage = false
                            onUseShard()
                        } else {
                            showMissingShardMessage = true
                        }
                    }
                )

                if showMissingShardMessage {
                    Text("디바인 조각이 없어요.")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.72))
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .padding(22)
        .background(.black.opacity(0.52))
        .clipShape(RoundedRectangle(cornerRadius: 26))
        .overlay(
            RoundedRectangle(cornerRadius: 26)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.28), radius: 20, y: 10)
    }
}

private struct LockedStageActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .bold))
                Text(title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(.white.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.white.opacity(0.10), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
