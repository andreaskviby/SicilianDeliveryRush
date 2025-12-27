import Foundation

struct PlayerProgress: Codable {
    var totalScore: Int = 0
    var highScore: Int = 0
    var completedDeliveries: Int = 0
    var perfectDeliveries: Int = 0
    var unlockedLevels: Set<Int> = [1]
    var totalCoins: Int = 0
    var achievements: Set<String> = []

    var currentLevel: Int {
        unlockedLevels.max() ?? 1
    }

    mutating func unlockLevel(_ level: Int) {
        unlockedLevels.insert(level)
    }

    mutating func addCoins(_ amount: Int) {
        totalCoins += amount
    }

    mutating func unlockAchievement(_ id: String) {
        achievements.insert(id)
    }
}

final class GameDataManager {
    private let userDefaults = UserDefaults.standard
    private let progressKey = "playerProgress"
    private let settingsKey = "gameSettings"

    func loadProgress() -> PlayerProgress? {
        guard let data = userDefaults.data(forKey: progressKey) else {
            return nil
        }

        do {
            return try JSONDecoder().decode(PlayerProgress.self, from: data)
        } catch {
            print("Failed to load progress: \(error)")
            return nil
        }
    }

    func saveProgress(_ progress: PlayerProgress) {
        do {
            let data = try JSONEncoder().encode(progress)
            userDefaults.set(data, forKey: progressKey)
        } catch {
            print("Failed to save progress: \(error)")
        }
    }

    func loadSettings() -> GameSettings {
        guard let data = userDefaults.data(forKey: settingsKey) else {
            return GameSettings()
        }

        do {
            return try JSONDecoder().decode(GameSettings.self, from: data)
        } catch {
            return GameSettings()
        }
    }

    func saveSettings(_ settings: GameSettings) {
        do {
            let data = try JSONEncoder().encode(settings)
            userDefaults.set(data, forKey: settingsKey)
        } catch {
            print("Failed to save settings: \(error)")
        }
    }

    func resetProgress() {
        userDefaults.removeObject(forKey: progressKey)
    }
}

struct GameSettings: Codable {
    var musicVolume: Float = 0.7
    var sfxVolume: Float = 1.0
    var hapticsEnabled: Bool = true
    var controlType: ControlType = .tilt
    var tiltSensitivity: Float = 1.0
    var invertY: Bool = false
    var graphicsQuality: GraphicsQuality = .high
    var targetFPS: Int = 60

    enum ControlType: String, Codable, CaseIterable {
        case tilt
        case touch
        case twoThumb

        var displayName: String {
            switch self {
            case .tilt: return "Tilt"
            case .touch: return "Touch"
            case .twoThumb: return "Two Thumb"
            }
        }
    }

    enum GraphicsQuality: String, Codable, CaseIterable {
        case low
        case medium
        case high

        var displayName: String {
            rawValue.capitalized
        }
    }
}
