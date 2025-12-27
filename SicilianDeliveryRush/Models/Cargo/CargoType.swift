import Foundation
import simd
import UIKit

enum CargoType: String, CaseIterable, Codable {
    case oliveOil
    case wine
    case cheese
    case tomatoes
    case lemons
    case cannoli
    case fish
    case bread

    var displayName: String {
        switch self {
        case .oliveOil: return "Olive Oil"
        case .wine: return "Sicilian Wine"
        case .cheese: return "Pecorino"
        case .tomatoes: return "Tomatoes"
        case .lemons: return "Lemons"
        case .cannoli: return "Cannoli"
        case .fish: return "Fresh Fish"
        case .bread: return "Bread"
        }
    }

    var pointValue: Int {
        switch self {
        case .oliveOil: return 150
        case .wine: return 200
        case .cheese: return 100
        case .tomatoes: return 50
        case .lemons: return 75
        case .cannoli: return 175
        case .fish: return 125
        case .bread: return 40
        }
    }

    var fragility: Float {
        switch self {
        case .oliveOil: return 0.8
        case .wine: return 0.9
        case .cheese: return 0.3
        case .tomatoes: return 0.7
        case .lemons: return 0.4
        case .cannoli: return 0.95
        case .fish: return 0.5
        case .bread: return 0.2
        }
    }

    var weight: Float {
        switch self {
        case .oliveOil: return 5.0
        case .wine: return 6.0
        case .cheese: return 4.0
        case .tomatoes: return 3.0
        case .lemons: return 2.5
        case .cannoli: return 1.0
        case .fish: return 4.0
        case .bread: return 1.5
        }
    }

    var modelName: String {
        "cargo_\(rawValue)"
    }

    var boundingBox: simd_float3 {
        switch self {
        case .oliveOil: return simd_float3(0.15, 0.3, 0.15)
        case .wine: return simd_float3(0.2, 0.4, 0.2)
        case .cheese: return simd_float3(0.25, 0.1, 0.25)
        case .tomatoes: return simd_float3(0.3, 0.15, 0.2)
        case .lemons: return simd_float3(0.25, 0.15, 0.2)
        case .cannoli: return simd_float3(0.3, 0.1, 0.2)
        case .fish: return simd_float3(0.4, 0.1, 0.15)
        case .bread: return simd_float3(0.3, 0.15, 0.15)
        }
    }

    var color: UIColor {
        switch self {
        case .oliveOil: return UIColor(red: 0.6, green: 0.7, blue: 0.2, alpha: 1)
        case .wine: return UIColor(red: 0.5, green: 0.1, blue: 0.2, alpha: 1)
        case .cheese: return UIColor(red: 1.0, green: 0.9, blue: 0.6, alpha: 1)
        case .tomatoes: return UIColor.red
        case .lemons: return UIColor.yellow
        case .cannoli: return UIColor(red: 0.9, green: 0.85, blue: 0.7, alpha: 1)
        case .fish: return UIColor(red: 0.7, green: 0.8, blue: 0.9, alpha: 1)
        case .bread: return UIColor(red: 0.8, green: 0.6, blue: 0.4, alpha: 1)
        }
    }

    var iconName: String {
        switch self {
        case .oliveOil: return "drop.fill"
        case .wine: return "wineglass.fill"
        case .cheese: return "circle.fill"
        case .tomatoes: return "circle.fill"
        case .lemons: return "leaf.fill"
        case .cannoli: return "staroflife.fill"
        case .fish: return "fish.fill"
        case .bread: return "rectangle.fill"
        }
    }

    var fragilityDescription: String {
        switch fragility {
        case 0..<0.3: return "Sturdy"
        case 0.3..<0.6: return "Moderate"
        case 0.6..<0.8: return "Fragile"
        default: return "Very Fragile"
        }
    }

    static func from(crop: CropType) -> CargoType {
        switch crop {
        case .tomatoes: return .tomatoes
        case .lemons: return .lemons
        case .olives: return .oliveOil
        case .grapes: return .wine
        case .wheat: return .bread
        }
    }
}
