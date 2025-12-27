import SceneKit
import simd

final class ApeLambretta: Vehicle {
    let type: VehicleType = .apeLambretta
    let node: SCNNode

    let mass: Float = 350.0
    let maxSpeed: Float = GameConfiguration.Physics.apeMaxSpeed
    let acceleration: Float = 2.5
    let brakeForce: Float = 6.0
    let turnRadius: Float = GameConfiguration.Physics.apeTurnRadius
    let centerOfMass: simd_float3 = simd_float3(0, 0.5, -0.2)

    let maxCargoSlots: Int = GameConfiguration.Gameplay.maxCargoApe
    let cargoAttachPoints: [simd_float3] = [
        simd_float3(-0.25, 0.6, -0.5),
        simd_float3(0.25, 0.6, -0.5),
        simd_float3(-0.25, 0.6, -0.9),
        simd_float3(0.25, 0.6, -0.9),
        simd_float3(-0.25, 0.9, -0.5),
        simd_float3(0.25, 0.9, -0.5),
        simd_float3(-0.25, 0.9, -0.9),
        simd_float3(0.25, 0.9, -0.9)
    ]

    var currentSpeed: Float = 0
    var currentSteering: Float = 0
    var isAccelerating: Bool = false
    var isBraking: Bool = false

    private var wheelRotation: Float = 0
    private var bodyRoll: Float = 0
    private var attachedCargo: [Int: CargoNode] = [:]

    init() {
        self.node = SCNNode()
        node.name = "ape_lambretta"
        setupGeometry()
        setupPhysicsBody()
    }

    private func setupGeometry() {
        let cabGeometry = SCNBox(width: 0.8, height: 0.9, length: 0.9, chamferRadius: 0.1)
        let cabMaterial = SCNMaterial()
        cabMaterial.diffuse.contents = UIColor(red: 0.8, green: 0.5, blue: 0.2, alpha: 1.0)
        cabMaterial.roughness.contents = 0.4
        cabGeometry.materials = [cabMaterial]

        let cabNode = SCNNode(geometry: cabGeometry)
        cabNode.position = SCNVector3(0, 0.65, 0.3)
        node.addChildNode(cabNode)

        let bedGeometry = SCNBox(width: 1.0, height: 0.3, length: 1.2, chamferRadius: 0.05)
        let bedMaterial = SCNMaterial()
        bedMaterial.diffuse.contents = UIColor(red: 0.3, green: 0.25, blue: 0.2, alpha: 1.0)
        bedGeometry.materials = [bedMaterial]

        let bedNode = SCNNode(geometry: bedGeometry)
        bedNode.position = SCNVector3(0, 0.45, -0.7)
        node.addChildNode(bedNode)

        let sideHeight: CGFloat = 0.4
        let sideGeometry = SCNBox(width: 0.05, height: sideHeight, length: 1.2, chamferRadius: 0.02)
        let sideMaterial = SCNMaterial()
        sideMaterial.diffuse.contents = UIColor(red: 0.35, green: 0.3, blue: 0.25, alpha: 1.0)
        sideGeometry.materials = [sideMaterial]

        let leftSide = SCNNode(geometry: sideGeometry)
        leftSide.position = SCNVector3(-0.5, 0.45 + Float(sideHeight/2) + 0.1, -0.7)
        node.addChildNode(leftSide)

        let rightSide = SCNNode(geometry: sideGeometry)
        rightSide.position = SCNVector3(0.5, 0.45 + Float(sideHeight/2) + 0.1, -0.7)
        node.addChildNode(rightSide)

        let backGeometry = SCNBox(width: 1.0, height: sideHeight, length: 0.05, chamferRadius: 0.02)
        backGeometry.materials = [sideMaterial]

        let backSide = SCNNode(geometry: backGeometry)
        backSide.position = SCNVector3(0, 0.45 + Float(sideHeight/2) + 0.1, -1.3)
        node.addChildNode(backSide)

        let frontWheelGeometry = SCNCylinder(radius: 0.22, height: 0.12)
        let wheelMaterial = SCNMaterial()
        wheelMaterial.diffuse.contents = UIColor.darkGray
        frontWheelGeometry.materials = [wheelMaterial]

        let frontWheel = SCNNode(geometry: frontWheelGeometry)
        frontWheel.name = "wheel_front"
        frontWheel.position = SCNVector3(0, 0.22, 0.6)
        frontWheel.eulerAngles.z = .pi / 2
        node.addChildNode(frontWheel)

        let rearWheelGeometry = SCNCylinder(radius: 0.25, height: 0.15)
        rearWheelGeometry.materials = [wheelMaterial]

        let rearLeftWheel = SCNNode(geometry: rearWheelGeometry)
        rearLeftWheel.name = "wheel_rear_left"
        rearLeftWheel.position = SCNVector3(-0.45, 0.25, -0.9)
        rearLeftWheel.eulerAngles.z = .pi / 2
        node.addChildNode(rearLeftWheel)

        let rearRightWheel = SCNNode(geometry: rearWheelGeometry)
        rearRightWheel.name = "wheel_rear_right"
        rearRightWheel.position = SCNVector3(0.45, 0.25, -0.9)
        rearRightWheel.eulerAngles.z = .pi / 2
        node.addChildNode(rearRightWheel)

        let handlebarGeometry = SCNCylinder(radius: 0.02, height: 0.5)
        let handlebarMaterial = SCNMaterial()
        handlebarMaterial.diffuse.contents = UIColor.gray
        handlebarGeometry.materials = [handlebarMaterial]

        let handlebar = SCNNode(geometry: handlebarGeometry)
        handlebar.position = SCNVector3(0, 1.15, 0.5)
        handlebar.eulerAngles.x = .pi / 2
        node.addChildNode(handlebar)
    }

    private func setupPhysicsBody() {
        let shape = SCNPhysicsShape(
            geometry: SCNBox(width: 1.2, height: 1.5, length: 2.5, chamferRadius: 0.1),
            options: nil
        )

        // Use kinematic physics - we control position manually
        node.physicsBody = SCNPhysicsBody(type: .kinematic, shape: shape)
        node.physicsBody?.mass = CGFloat(mass)
        node.physicsBody?.friction = 0.9
        node.physicsBody?.restitution = 0.05
        node.physicsBody?.categoryBitMask = PhysicsCategory.vehicle
        node.physicsBody?.contactTestBitMask = PhysicsCategory.obstacle | PhysicsCategory.road | PhysicsCategory.trigger | PhysicsCategory.terrain
        node.physicsBody?.collisionBitMask = PhysicsCategory.none
    }

    func updatePhysics(deltaTime: TimeInterval) {
        let dt = Float(deltaTime)

        if isAccelerating {
            currentSpeed = min(currentSpeed + acceleration * dt, maxSpeed)
        } else if isBraking {
            currentSpeed = max(currentSpeed - brakeForce * dt, 0)
        } else {
            currentSpeed = max(currentSpeed - 0.8 * dt, 0)
        }

        let lateralG = calculateLateralG()
        let targetRoll = currentSteering * lateralG * 0.15
        bodyRoll = bodyRoll + (targetRoll - bodyRoll) * 0.15
        node.eulerAngles.z = bodyRoll

        wheelRotation += currentSpeed * dt * 1.5

        if let frontWheel = node.childNode(withName: "wheel_front", recursively: true) {
            frontWheel.eulerAngles.x = wheelRotation
        }

        ["wheel_rear_left", "wheel_rear_right"].forEach { name in
            if let wheel = node.childNode(withName: name, recursively: true) {
                wheel.eulerAngles.x = wheelRotation
            }
        }

        let forward = node.simdWorldFront
        let velocity = forward * currentSpeed
        node.simdPosition += velocity * dt

        if currentSpeed > 0.1 {
            let angularVelocity = currentSteering * (currentSpeed / turnRadius)
            node.simdEulerAngles.y += angularVelocity * dt
        }
    }

    func attachCargo(_ cargo: CargoNode, at slotIndex: Int) {
        guard slotIndex < cargoAttachPoints.count else { return }
        guard attachedCargo[slotIndex] == nil else { return }

        cargo.removeFromParentNode()
        node.addChildNode(cargo)
        cargo.simdPosition = cargoAttachPoints[slotIndex]
        cargo.attachedSlot = slotIndex
        attachedCargo[slotIndex] = cargo
    }

    func detachCargo(at slotIndex: Int) -> CargoNode? {
        guard let cargo = attachedCargo[slotIndex] else { return nil }

        let worldPosition = cargo.simdWorldPosition

        cargo.removeFromParentNode()
        cargo.simdPosition = worldPosition
        cargo.attachedSlot = nil
        attachedCargo[slotIndex] = nil

        return cargo
    }

    func getAttachedCargo() -> [CargoNode] {
        Array(attachedCargo.values)
    }
}
