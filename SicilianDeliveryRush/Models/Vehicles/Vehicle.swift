import SceneKit
import simd

enum VehicleType: String, CaseIterable, Codable {
    case vespa
    case apeLambretta

    var displayName: String {
        switch self {
        case .vespa: return "Vespa"
        case .apeLambretta: return "APE Lambretta"
        }
    }

    var modelName: String {
        switch self {
        case .vespa: return "vespa_model"
        case .apeLambretta: return "ape_lambretta_model"
        }
    }

    var maxCargoSlots: Int {
        switch self {
        case .vespa: return GameConfiguration.Gameplay.maxCargoVespa
        case .apeLambretta: return GameConfiguration.Gameplay.maxCargoApe
        }
    }

    var description: String {
        switch self {
        case .vespa:
            return "Fast and agile, but less stable. Perfect for small deliveries."
        case .apeLambretta:
            return "Slower but very stable. Ideal for large loads."
        }
    }
}

protocol Vehicle: AnyObject {
    var type: VehicleType { get }
    var node: SCNNode { get }

    var mass: Float { get }
    var maxSpeed: Float { get }
    var acceleration: Float { get }
    var brakeForce: Float { get }
    var turnRadius: Float { get }
    var centerOfMass: simd_float3 { get }

    var maxCargoSlots: Int { get }
    var cargoAttachPoints: [simd_float3] { get }

    var currentSpeed: Float { get set }
    var currentSteering: Float { get set }
    var isAccelerating: Bool { get set }
    var isBraking: Bool { get set }

    func updatePhysics(deltaTime: TimeInterval)
    func calculateLateralG() -> Float
    func attachCargo(_ cargo: CargoNode, at slotIndex: Int)
    func detachCargo(at slotIndex: Int) -> CargoNode?
}

extension Vehicle {
    func calculateLateralG() -> Float {
        let velocity = currentSpeed
        let effectiveSteering = abs(currentSteering) + 0.001
        let radius = turnRadius / effectiveSteering
        let g = abs(GameConfiguration.Physics.gravity)

        return (velocity * velocity) / (radius * g)
    }

    var speedKmh: Float {
        currentSpeed * 3.6
    }

    var speedPercentage: Float {
        currentSpeed / maxSpeed
    }
}

final class VehicleFactory {
    static func create(type: VehicleType) -> Vehicle {
        switch type {
        case .vespa:
            return Vespa()
        case .apeLambretta:
            return ApeLambretta()
        }
    }
}
