import SwiftUI

struct SettingsView: View {
    @Binding var path: [Route]
    @Environment(ProgressStore.self) private var progress
    @State private var showResetConfirm = false
    @AppStorage("perfect_split.settings.haptics") private var hapticsEnabled = true
    @AppStorage("perfect_split.settings.reduceEffects") private var reduceEffects = false
    @AppStorage("perfect_split.settings.bgm") private var bgmEnabled = true
    @AppStorage("perfect_split.settings.sfx") private var sfxEnabled = true
    @AppStorage("perfect_split.settings.bgm.volume") private var bgmVolume: Double = 0.4
    @AppStorage("perfect_split.settings.sfx.volume") private var sfxVolume: Double = 0.8

    private var totalStages: Int { StageCatalog.allStages.count }
    private var totalPossibleStars: Int { totalStages * 3 }
    private var continuousBest: Int {
        UserDefaults.standard.integer(forKey: "perfect_split.continuous.best.v1")
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.06, green: 0.08, blue: 0.14),
                    Color(red: 0.05, green: 0.12, blue: 0.10)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 18) {
                    progressSection
                    optionsSection
                    dataSection
                }
                .padding(18)
            }
        }
        .navigationTitle("설정")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .confirmationDialog("진행도를 초기화할까요?", isPresented: $showResetConfirm, titleVisibility: .visible) {
            Button("진행도 초기화", role: .destructive) {
                progress.resetAllProgress()
                UserDefaults.standard.removeObject(forKey: "perfect_split.continuous.best.v1")
            }
            Button("취소", role: .cancel) {}
        } message: {
            Text("Easy/Hard 별, Divine 기록, 연속 모드 최고 기록이 삭제됩니다.")
        }
    }

    private var progressSection: some View {
        VStack(spacing: 12) {
            SettingsStatRow(
                title: "Easy 별",
                value: "\(stars(in: .easy)) / \(totalPossibleStars)",
                color: .mint
            )
            SettingsStatRow(
                title: "Hard 별",
                value: "\(stars(in: .hard)) / \(totalPossibleStars)",
                color: .green
            )
            SettingsStatRow(
                title: "Easy Divine",
                value: "\(divines(in: .easy)) / \(totalStages)",
                color: .red
            )
            SettingsStatRow(
                title: "Hard Divine",
                value: "\(divines(in: .hard)) / \(totalStages)",
                color: .red
            )
            SettingsStatRow(
                title: "연속 모드 최고",
                value: "\(continuousBest)번",
                color: .yellow
            )
            SettingsStatRow(
                title: "디바인 조각",
                value: "\(progress.divisionShardCount)개",
                color: .white
            )
        }
        .settingsPanel()
    }

    private var optionsSection: some View {
        VStack(spacing: 4) {
            Toggle("햅틱", isOn: $hapticsEnabled)
            Divider().background(.white.opacity(0.12))
            Toggle("효과 줄이기", isOn: $reduceEffects)
            Divider().background(.white.opacity(0.12))
            Toggle("배경음악", isOn: $bgmEnabled)
                .onChange(of: bgmEnabled) { _, newValue in
                    SoundManager.shared.setBGMEnabled(newValue)
                }
            VolumeSlider(
                title: "배경음악 크기",
                value: $bgmVolume,
                disabled: !bgmEnabled,
                onChanged: { new in
                    SoundManager.shared.applyBGMVolume(Float(new))
                },
                onReleased: nil
            )
            Divider().background(.white.opacity(0.12))
            Toggle("효과음", isOn: $sfxEnabled)
                .onChange(of: sfxEnabled) { _, newValue in
                    if newValue {
                        SoundManager.shared.playEffect(.click)
                    }
                }
            VolumeSlider(
                title: "효과음 크기",
                value: $sfxVolume,
                disabled: !sfxEnabled,
                onChanged: nil,
                onReleased: {
                    SoundManager.shared.playEffect(.click)
                }
            )
        }
        .font(.system(size: 16, weight: .semibold, design: .rounded))
        .foregroundStyle(.white)
        .tint(.mint)
        .settingsPanel()
    }

    private var dataSection: some View {
        VStack(spacing: 12) {
            Button(role: .destructive) {
                showResetConfirm = true
            } label: {
                Text("진행도 초기화")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(.white.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            HStack(spacing: 10) {
                Link(destination: URL(string: "https://smoggy-venus-d59.notion.site/34b6438d1fba80cda2afe08a4c159253")!) {
                    Text("개인정보 처리방침")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Link(destination: URL(string: "https://smoggy-venus-d59.notion.site/Perfect-Split-34c6438d1fba8046baa7e1f1ece4335e")!) {
                    Text("이용약관")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }

            Text("Perfect Split 1.0")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.45))

            Text("Created by MY")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.45))
        }
        .settingsPanel()
    }

    private func stars(in mode: GameMode) -> Int {
        StageCatalog.allStages.reduce(0) { partial, stage in
            partial + progress.stars(for: stage, mode: mode)
        }
    }

    private func divines(in mode: GameMode) -> Int {
        StageCatalog.allStages.filter { progress.isDivine($0, mode: mode) }.count
    }
}

private struct VolumeSlider: View {
    let title: String
    @Binding var value: Double
    let disabled: Bool
    let onChanged: ((Double) -> Void)?
    let onReleased: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(disabled ? 0.3 : 0.72))
                Spacer()
                Text("\(Int(value * 100))%")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(disabled ? 0.3 : 0.85))
                    .monospacedDigit()
            }
            Slider(
                value: $value,
                in: 0...1,
                onEditingChanged: { editing in
                    if !editing {
                        onReleased?()
                    }
                }
            )
            .onChange(of: value) { _, newValue in
                onChanged?(newValue)
            }
            .disabled(disabled)
        }
        .padding(.top, 6)
        .padding(.bottom, 4)
    }
}

private struct SettingsStatRow: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.72))
            Spacer()
            Text(value)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(color)
        }
    }
}

private extension View {
    func settingsPanel() -> some View {
        self
            .padding(16)
            .background(.black.opacity(0.34))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(.white.opacity(0.08), lineWidth: 1)
            )
    }
}
