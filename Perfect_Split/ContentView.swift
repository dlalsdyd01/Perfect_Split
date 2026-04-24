import SwiftUI

enum Route: Hashable {
    case stageSelect
    case game(Stage, GameMode)
    case continuous
    case settings
}

struct ContentView: View {
    @State private var path: [Route] = []
    @State private var progress = ProgressStore()
    @State private var launchFinished = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            NavigationStack(path: $path) {
                MainView(path: $path)
                    .navigationDestination(for: Route.self) { route in
                        switch route {
                        case .stageSelect:
                            StageSelectView(path: $path)
                        case .game(let stage, let mode):
                            GameView(path: $path, stage: stage, mode: mode)
                        case .continuous:
                            ContinuousSplitView(path: $path)
                        case .settings:
                            SettingsView(path: $path)
                        }
                    }
            }

            if !launchFinished {
                LaunchView {
                    withAnimation(.easeOut(duration: 0.28)) {
                        launchFinished = true
                    }
                    AdService.shared.startAfterLaunch()
                    SoundManager.shared.startBGM()
                }
                .transition(.opacity)
            }
        }
        .environment(progress)
        .preferredColorScheme(.dark)
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                SoundManager.shared.resumeBGM()
            case .background, .inactive:
                SoundManager.shared.pauseBGM()
            @unknown default:
                break
            }
        }
    }
}

#Preview {
    ContentView()
}
