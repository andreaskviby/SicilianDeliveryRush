import AVFoundation
import UIKit

enum SoundEffect: String, CaseIterable {
    case engineIdle = "engine_idle"
    case engineAccel = "engine_accel"
    case brake = "brake_squeal"
    case cargoFall = "cargo_drop"
    case crash = "crash_impact"
    case checkpoint = "checkpoint_ding"
    case countdown = "countdown_beep"
    case raceStart = "race_start"
    case raceComplete = "race_complete"
    case victory = "victory_fanfare"
    case uiClick = "ui_click"
    case harvest = "harvest"
    case itemPickup = "item_pickup"
}

enum MusicTrack: String, CaseIterable {
    case menuTheme = "menu_sicilian"
    case farmAmbient = "farm_ambient"
    case racingIntense = "racing_tarantella"
    case victoryTheme = "victory_theme"
}

final class AudioManager {
    private var audioEngine: AVAudioEngine?
    private var musicPlayer: AVAudioPlayer?
    private var sfxPlayers: [String: AVAudioPlayer] = [:]

    private var musicVolume: Float = GameConfiguration.Audio.musicVolume
    private var sfxVolume: Float = GameConfiguration.Audio.sfxVolume
    private var isMuted: Bool = false

    private let hapticLight = UIImpactFeedbackGenerator(style: .light)
    private let hapticMedium = UIImpactFeedbackGenerator(style: .medium)
    private let hapticHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let hapticSuccess = UINotificationFeedbackGenerator()

    init() {
        setupAudioSession()
        preloadHaptics()
    }

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }

    private func preloadHaptics() {
        hapticLight.prepare()
        hapticMedium.prepare()
        hapticHeavy.prepare()
        hapticSuccess.prepare()
    }

    func play(_ effect: SoundEffect) {
        guard !isMuted else { return }

        playHapticForEffect(effect)
    }

    private func playHapticForEffect(_ effect: SoundEffect) {
        switch effect {
        case .uiClick:
            hapticLight.impactOccurred()

        case .checkpoint, .itemPickup:
            hapticMedium.impactOccurred()

        case .cargoFall, .crash:
            hapticHeavy.impactOccurred()
            hapticSuccess.notificationOccurred(.error)

        case .victory, .raceComplete:
            hapticSuccess.notificationOccurred(.success)

        case .harvest:
            hapticMedium.impactOccurred()

        default:
            break
        }
    }

    func playMusic(_ track: MusicTrack, loop: Bool = true) {
        guard !isMuted else { return }

        musicPlayer?.stop()
    }

    func stopMusic() {
        musicPlayer?.stop()
        musicPlayer = nil
    }

    func pauseMusic() {
        musicPlayer?.pause()
    }

    func resumeMusic() {
        musicPlayer?.play()
    }

    func handlePhaseTransition(from: GamePhase, to: GamePhase) {
        switch to {
        case .mainMenu:
            playMusic(.menuTheme)

        case .farm:
            playMusic(.farmAmbient)

        case .driving(.racing):
            playMusic(.racingIntense)

        case .gameOver(let result) where result.starRating >= 2:
            stopMusic()
            play(.victory)

        case .paused:
            pauseMusic()

        default:
            break
        }

        if case .paused = from {
            resumeMusic()
        }
    }

    func setMusicVolume(_ volume: Float) {
        musicVolume = volume.clamped(to: 0...1)
        musicPlayer?.volume = musicVolume
    }

    func setSFXVolume(_ volume: Float) {
        sfxVolume = volume.clamped(to: 0...1)
    }

    func setMuted(_ muted: Bool) {
        isMuted = muted
        if muted {
            stopMusic()
        }
    }

    func playButtonTap() {
        play(.uiClick)
    }

    func playEngineSound(speed: Float) {
    }
}
