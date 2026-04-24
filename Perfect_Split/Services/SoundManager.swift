import Foundation
import AVFoundation

enum SoundEffect: String, CaseIterable {
    case click = "Click"
    case slice = "Slice"
    case divine = "Divine"
    case clear = "Clear"
    case fail = "fail"

    var fileExtension: String { "mp3" }
}

@MainActor
final class SoundManager {
    static let shared = SoundManager()

    private var bgmPlayer: AVAudioPlayer?
    private var effectData: [SoundEffect: Data] = [:]
    private var activeEffectPlayers: [AVAudioPlayer] = []

    private var isBGMEnabled: Bool {
        UserDefaults.standard.object(forKey: "perfect_split.settings.bgm") as? Bool ?? true
    }

    private var isSFXEnabled: Bool {
        UserDefaults.standard.object(forKey: "perfect_split.settings.sfx") as? Bool ?? true
    }

    private var bgmVolume: Float {
        Float(UserDefaults.standard.object(forKey: "perfect_split.settings.bgm.volume") as? Double ?? 0.4)
    }

    private var sfxVolume: Float {
        Float(UserDefaults.standard.object(forKey: "perfect_split.settings.sfx.volume") as? Double ?? 0.8)
    }

    private init() {
        configureSession()
    }

    private func configureSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("[SoundManager] Session error: \(error)")
        }
    }

    func startBGM() {
        guard isBGMEnabled else { return }

        if let player = bgmPlayer {
            if !player.isPlaying {
                player.play()
            }
            return
        }

        guard let url = Bundle.main.url(forResource: "bgm", withExtension: "mp3") else {
            print("[SoundManager] bgm.mp3 not found in bundle")
            return
        }
        print("[SoundManager] Loading bgm.mp3 from: \(url.path)")

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.volume = bgmVolume
            player.prepareToPlay()
            let started = player.play()
            bgmPlayer = player
            print("[SoundManager] play() returned \(started), isPlaying=\(player.isPlaying), volume=\(player.volume), duration=\(player.duration)")
        } catch {
            print("[SoundManager] Player error: \(error)")
        }
    }

    func stopBGM() {
        bgmPlayer?.stop()
        bgmPlayer = nil
    }

    func pauseBGM() {
        bgmPlayer?.pause()
    }

    func resumeBGM() {
        guard isBGMEnabled else { return }
        bgmPlayer?.play()
    }

    func setBGMEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: "perfect_split.settings.bgm")
        if enabled {
            startBGM()
        } else {
            stopBGM()
        }
    }

    func playEffect(_ effect: SoundEffect) {
        guard isSFXEnabled else { return }

        if effectData[effect] == nil {
            guard let url = Bundle.main.url(forResource: effect.rawValue, withExtension: effect.fileExtension),
                  let data = try? Data(contentsOf: url) else {
                print("[SoundManager] \(effect.rawValue).\(effect.fileExtension) not found in bundle")
                return
            }
            effectData[effect] = data
        }

        guard let data = effectData[effect] else { return }

        do {
            let player = try AVAudioPlayer(data: data)
            player.volume = sfxVolume
            player.prepareToPlay()
            player.play()
            activeEffectPlayers.append(player)
            activeEffectPlayers.removeAll { !$0.isPlaying }
        } catch {
            print("[SoundManager] Effect error: \(error)")
        }
    }

    func applyBGMVolume(_ volume: Float) {
        bgmPlayer?.volume = volume
    }
}
