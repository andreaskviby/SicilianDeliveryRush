import Foundation

struct PhysicsCategory {
    static let none: Int = 0
    static let vehicle: Int = 1 << 0
    static let cargo: Int = 1 << 1
    static let terrain: Int = 1 << 2
    static let road: Int = 1 << 3
    static let obstacle: Int = 1 << 4
    static let building: Int = 1 << 5
    static let trigger: Int = 1 << 6
    static let vegetation: Int = 1 << 7

    static let all: Int = Int.max

    static func categoryName(_ category: Int) -> String {
        switch category {
        case vehicle: return "Vehicle"
        case cargo: return "Cargo"
        case terrain: return "Terrain"
        case road: return "Road"
        case obstacle: return "Obstacle"
        case building: return "Building"
        case trigger: return "Trigger"
        case vegetation: return "Vegetation"
        default: return "Unknown"
        }
    }
}
