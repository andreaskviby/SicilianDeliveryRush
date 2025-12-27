import SceneKit
import simd

struct VehicleInput {
    var steering: Float = 0
    var throttle: Float = 0
    var brake: Float = 0

    static let zero = VehicleInput()

    var isAccelerating: Bool { throttle > 0.1 }
    var isBraking: Bool { brake > 0.1 }
}

final class VehiclePhysicsController {
    let vehicle: any Vehicle
    weak var gameScene: SCNScene?
    private var cargoNodes: [CargoNode] = []

    private var roadNormal: simd_float3 = simd_float3(0, 1, 0)
    private var roadSlope: Float = 0
    private var isOnRoad: Bool = true

    private var gravityComponent: Float = 0
    private var lastPosition: simd_float3 = .zero
    private var actualVelocity: simd_float3 = .zero

    var cargoLostHandler: ((CargoNode) -> Void)?

    init(vehicle: any Vehicle, scene: SCNScene? = nil) {
        self.vehicle = vehicle
        self.gameScene = scene
        self.lastPosition = vehicle.node.simdPosition
    }

    func attachCargo(_ nodes: [CargoNode]) {
        cargoNodes = nodes
    }

    func update(deltaTime: TimeInterval, input: VehicleInput) {
        vehicle.currentSteering = input.steering
        vehicle.isAccelerating = input.isAccelerating
        vehicle.isBraking = input.isBraking

        updateRoadInteraction()

        applyDownhillPhysics(deltaTime: deltaTime)

        vehicle.updatePhysics(deltaTime: deltaTime)

        let currentPosition = vehicle.node.simdPosition
        actualVelocity = (currentPosition - lastPosition) / Float(deltaTime)
        lastPosition = currentPosition

        let lateralG = vehicle.calculateLateralG()
        updateCargoStability(lateralG: lateralG, deltaTime: deltaTime)
    }

    private func updateRoadInteraction() {
        guard let scene = gameScene else { return }

        let vehicleNode = vehicle.node
        // Cast ray from above vehicle to below
        let rayStart = vehicleNode.simdPosition + simd_float3(0, 5, 0)
        let rayEnd = vehicleNode.simdPosition - simd_float3(0, 10, 0)

        let options: [SCNPhysicsWorld.TestOption: Any] = [
            .collisionBitMask: NSNumber(value: PhysicsCategory.road | PhysicsCategory.terrain),
            .searchMode: SCNPhysicsWorld.TestSearchMode.closest
        ]

        let hitResults = scene.physicsWorld.rayTestWithSegment(
            from: SCNVector3(rayStart),
            to: SCNVector3(rayEnd),
            options: options
        )

        if let hit = hitResults.first {
            roadNormal = simd_float3(
                Float(hit.worldNormal.x),
                Float(hit.worldNormal.y),
                Float(hit.worldNormal.z)
            )

            let forward = vehicle.node.simdWorldFront
            let downComponent = simd_float3(0, -1, 0)
            roadSlope = simd_dot(forward, downComponent + roadNormal)

            isOnRoad = hit.node.physicsBody?.categoryBitMask == PhysicsCategory.road

            let groundY = Float(hit.worldCoordinates.y)
            // Height offset based on vehicle type (wheel radius + some clearance)
            let heightOffset: Float = 0.3

            // Smoothly adjust vehicle height to follow terrain
            let targetY = groundY + heightOffset
            let currentY = vehicle.node.simdPosition.y
            let heightDiff = targetY - currentY

            // Apply smooth height correction
            if abs(heightDiff) > 0.01 {
                vehicle.node.simdPosition.y = currentY + heightDiff * 0.3
            }
        }
    }

    private func applyDownhillPhysics(deltaTime: TimeInterval) {
        let dt = Float(deltaTime)
        let gravity = abs(GameConfiguration.Physics.gravity)

        if roadSlope < 0 {
            let downhillForce = abs(roadSlope) * gravity * 0.3
            vehicle.currentSpeed += downhillForce * dt
        } else if roadSlope > 0 && !vehicle.isAccelerating {
            let uphillDrag = roadSlope * gravity * 0.2
            vehicle.currentSpeed -= uphillDrag * dt
            vehicle.currentSpeed = max(0, vehicle.currentSpeed)
        }

        if !isOnRoad {
            vehicle.currentSpeed *= 0.98
        }
    }

    private func updateCargoStability(lateralG: Float, deltaTime: TimeInterval) {
        for cargo in cargoNodes {
            let isStable = cargo.updateStability(vehicleLateralG: lateralG, deltaTime: deltaTime)

            if !isStable {
                if let scene = gameScene {
                    cargo.removeFromParentNode()
                    scene.rootNode.addChildNode(cargo)
                }

                cargoLostHandler?(cargo)

                if let index = cargoNodes.firstIndex(where: { $0 === cargo }) {
                    cargoNodes.remove(at: index)
                }
            }
        }
    }

    var currentLateralG: Float {
        vehicle.calculateLateralG()
    }

    var currentSlope: Float {
        roadSlope
    }

    var isVehicleOnRoad: Bool {
        isOnRoad
    }

    func getCargoStressLevels() -> [Float] {
        cargoNodes.map { $0.stressLevel }
    }

    func getAverageCargoStress() -> Float {
        guard !cargoNodes.isEmpty else { return 0 }
        let total = cargoNodes.reduce(0) { $0 + $1.stressLevel }
        return total / Float(cargoNodes.count)
    }
}
