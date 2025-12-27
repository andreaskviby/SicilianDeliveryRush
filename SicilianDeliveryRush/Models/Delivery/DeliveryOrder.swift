import Foundation
import simd

struct DeliveryOrder: Identifiable, Codable {
    let id: UUID
    let destinationName: String
    let destinationDescription: String
    let requiredItems: [CargoType]
    let timeLimit: TimeInterval
    let difficulty: Difficulty
    let bonusObjectives: [BonusObjective]

    var estimatedDistance: Float {
        Float(timeLimit) * 0.5
    }

    init(
        destinationName: String,
        destinationDescription: String,
        requiredItems: [CargoType],
        timeLimit: TimeInterval,
        difficulty: Difficulty,
        bonusObjectives: [BonusObjective] = []
    ) {
        self.id = UUID()
        self.destinationName = destinationName
        self.destinationDescription = destinationDescription
        self.requiredItems = requiredItems
        self.timeLimit = timeLimit
        self.difficulty = difficulty
        self.bonusObjectives = bonusObjectives
    }

    enum Difficulty: String, Codable, CaseIterable {
        case easy
        case medium
        case hard

        var displayName: String {
            rawValue.capitalized
        }

        var starMultiplier: Float {
            switch self {
            case .easy: return 1.0
            case .medium: return 1.5
            case .hard: return 2.0
            }
        }

        var roadComplexity: RoadComplexity {
            switch self {
            case .easy: return .easy
            case .medium: return .medium
            case .hard: return .hard
            }
        }
    }

    struct BonusObjective: Codable {
        let description: String
        let bonusPoints: Int
        let type: ObjectiveType

        enum ObjectiveType: String, Codable {
            case noDamage
            case underTime
            case perfectCargo
            case noCheckpointMiss
        }
    }
}

struct Destination: Identifiable, Codable {
    let id: UUID
    let name: String
    let description: String
    let position: SIMD3<Float>

    init(name: String, description: String, position: SIMD3<Float>) {
        self.id = UUID()
        self.name = name
        self.description = description
        self.position = position
    }

    static let sampleDestinations: [Destination] = [
        Destination(
            name: "Taormina",
            description: "Historic hillside town with ancient theater",
            position: SIMD3<Float>(50, 5, 80)
        ),
        Destination(
            name: "Cefalù",
            description: "Charming fishing village by the sea",
            position: SIMD3<Float>(70, 3, 90)
        ),
        Destination(
            name: "Siracusa",
            description: "Ancient Greek city with baroque architecture",
            position: SIMD3<Float>(30, 8, 100)
        ),
        Destination(
            name: "Agrigento",
            description: "Valley of the Temples",
            position: SIMD3<Float>(60, 10, 70)
        ),
        Destination(
            name: "Noto",
            description: "Baroque jewel of Sicily",
            position: SIMD3<Float>(40, 6, 85)
        )
    ]
}

final class DeliveryOrderGenerator {
    static func generateOrder(forLevel level: Int) -> DeliveryOrder {
        let destinations = Destination.sampleDestinations
        let destination = destinations[level % destinations.count]

        let difficulty: DeliveryOrder.Difficulty
        switch level {
        case 1...3: difficulty = .easy
        case 4...7: difficulty = .medium
        default: difficulty = .hard
        }

        let itemCount = min(2 + level, 8)
        let requiredItems = generateRequiredItems(count: itemCount, difficulty: difficulty)

        let baseTime: TimeInterval = 120
        let timeLimit = baseTime + Double(level) * 10

        var bonusObjectives: [DeliveryOrder.BonusObjective] = [
            DeliveryOrder.BonusObjective(
                description: "Deliver all items intact",
                bonusPoints: 200,
                type: .perfectCargo
            )
        ]

        if difficulty != .easy {
            bonusObjectives.append(
                DeliveryOrder.BonusObjective(
                    description: "Complete under \(Int(timeLimit * 0.8)) seconds",
                    bonusPoints: 300,
                    type: .underTime
                )
            )
        }

        return DeliveryOrder(
            destinationName: destination.name,
            destinationDescription: destination.description,
            requiredItems: requiredItems,
            timeLimit: timeLimit,
            difficulty: difficulty,
            bonusObjectives: bonusObjectives
        )
    }

    private static func generateRequiredItems(count: Int, difficulty: DeliveryOrder.Difficulty) -> [CargoType] {
        var items: [CargoType] = []
        let allTypes = CargoType.allCases

        for _ in 0..<count {
            let type: CargoType

            switch difficulty {
            case .easy:
                let easyTypes: [CargoType] = [.bread, .cheese, .lemons, .tomatoes]
                type = easyTypes.randomElement() ?? .bread

            case .medium:
                let mediumTypes: [CargoType] = [.cheese, .oliveOil, .fish, .lemons]
                type = mediumTypes.randomElement() ?? .cheese

            case .hard:
                type = allTypes.randomElement() ?? .wine
            }

            items.append(type)
        }

        return items
    }
}
