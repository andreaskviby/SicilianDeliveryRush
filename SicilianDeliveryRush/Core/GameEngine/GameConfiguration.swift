import Foundation
import simd

struct GameConfiguration {

    struct Physics {
        static let gravity: Float = -9.81
        static let groundFriction: Float = 0.8
        static let cargoFriction: Float = 0.6

        static let cargoSlipThreshold: Float = 0.4
        static let cargoFallThreshold: Float = 0.7

        static let vespaMaxSpeed: Float = 15.0
        static let apeMaxSpeed: Float = 12.0
        static let vespaTurnRadius: Float = 3.0
        static let apeTurnRadius: Float = 4.5
    }

    struct Gameplay {
        static let countdownDuration: TimeInterval = 3.0
        static let perfectTimeBonus: TimeInterval = 90.0
        static let maxCargoVespa: Int = 4
        static let maxCargoApe: Int = 8

        static let baseDeliveryTime: TimeInterval = 120.0
        static let bonusTimeMultiplier: Double = 10.0
        static let perfectDeliveryBonus: Int = 500
    }

    struct Visual {
        static let cartoonOutlineWidth: Float = 2.0
        static let drawDistance: Float = 500.0
        static let lodDistances: [Float] = [50, 150, 300]
        static let fieldOfView: CGFloat = 75.0
        static let cameraSmoothing: Float = 0.1
    }

    struct Audio {
        static let masterVolume: Float = 1.0
        static let musicVolume: Float = 0.7
        static let sfxVolume: Float = 1.0
    }

    struct Controls {
        static let defaultTiltSensitivity: Float = 1.0
        static let tiltDeadZone: Float = 0.05
        static let maxTiltAngle: Float = 0.5
        static let steeringSmoothing: Float = 0.3
        static let touchSteeringRadius: CGFloat = 80.0
    }

    struct Scoring {
        static func calculateStars(for score: Int) -> Int {
            switch score {
            case 0..<500: return 1
            case 500..<1000: return 2
            default: return 3
            }
        }

        static func calculateTimeBonus(elapsed: TimeInterval, target: TimeInterval) -> Int {
            let remaining = target - elapsed
            if remaining > 0 {
                return Int(remaining * Gameplay.bonusTimeMultiplier)
            }
            return 0
        }
    }
}
