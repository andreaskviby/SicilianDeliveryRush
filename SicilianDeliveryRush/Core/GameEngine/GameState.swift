import Foundation

indirect enum GamePhase: Equatable {
    case mainMenu
    case farm(FarmPhase)
    case loading(LoadingPhase)
    case driving(DrivingPhase)
    case delivery(DeliveryPhase)
    case paused(previousPhase: GamePhase)
    case gameOver(result: DeliveryResult)

    enum FarmPhase: Equatable {
        case exploring
        case harvesting(CropType)
        case inventory
    }

    enum LoadingPhase: Equatable {
        case selectingVehicle
        case loadingCargo
        case confirmingRoute
    }

    enum DrivingPhase: Equatable {
        case countdown
        case racing
        case cargoFalling
        case crashed
    }

    enum DeliveryPhase: Equatable {
        case arriving
        case unloading
        case scoring
    }

    static func == (lhs: GamePhase, rhs: GamePhase) -> Bool {
        switch (lhs, rhs) {
        case (.mainMenu, .mainMenu):
            return true
        case (.farm(let l), .farm(let r)):
            return l == r
        case (.loading(let l), .loading(let r)):
            return l == r
        case (.driving(let l), .driving(let r)):
            return l == r
        case (.delivery(let l), .delivery(let r)):
            return l == r
        case (.paused, .paused):
            return true
        case (.gameOver, .gameOver):
            return true
        default:
            return false
        }
    }
}

struct DeliveryResult: Equatable {
    let timeElapsed: TimeInterval
    let cargoDelivered: Int
    let cargoLost: Int
    let bonusPoints: Int
    let totalScore: Int
    let starRating: Int

    static func == (lhs: DeliveryResult, rhs: DeliveryResult) -> Bool {
        lhs.totalScore == rhs.totalScore && lhs.starRating == rhs.starRating
    }
}

enum CropType: String, CaseIterable, Codable, Equatable {
    case tomatoes
    case lemons
    case olives
    case grapes
    case wheat

    var displayName: String {
        switch self {
        case .tomatoes: return "Tomatoes"
        case .lemons: return "Lemons"
        case .olives: return "Olives"
        case .grapes: return "Grapes"
        case .wheat: return "Wheat"
        }
    }

    var growthTime: TimeInterval {
        switch self {
        case .tomatoes: return 30
        case .lemons: return 45
        case .olives: return 60
        case .grapes: return 50
        case .wheat: return 25
        }
    }

    var harvestAmount: Int {
        switch self {
        case .tomatoes: return 5
        case .lemons: return 4
        case .olives: return 8
        case .grapes: return 6
        case .wheat: return 10
        }
    }
}
