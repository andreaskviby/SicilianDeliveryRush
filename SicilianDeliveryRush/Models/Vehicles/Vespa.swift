import SceneKit
import simd

final class Vespa: Vehicle {
    let type: VehicleType = .vespa
    let node: SCNNode

    let mass: Float = 120.0
    let maxSpeed: Float = GameConfiguration.Physics.vespaMaxSpeed
    let acceleration: Float = 4.0
    let brakeForce: Float = 8.0
    let turnRadius: Float = GameConfiguration.Physics.vespaTurnRadius
    let centerOfMass: simd_float3 = simd_float3(0, 0.4, 0)

    let maxCargoSlots: Int = GameConfiguration.Gameplay.maxCargoVespa
    let cargoAttachPoints: [simd_float3] = [
        simd_float3(0, 0.5, -0.3),
        simd_float3(-0.15, 0.5, -0.3),
        simd_float3(0.15, 0.5, -0.3),
        simd_float3(0, 0.6, -0.3)
    ]

    var currentSpeed: Float = 0
    var currentSteering: Float = 0
    var isAccelerating: Bool = false
    var isBraking: Bool = false

    private var wheelRotation: Float = 0
    private var leanAngle: Float = 0
    private var attachedCargo: [Int: CargoNode] = [:]

    init() {
        self.node = SCNNode()
        node.name = "vespa"
        setupGeometry()
        setupPhysicsBody()
    }

    private func setupGeometry() {
        let bodyGeometry = SCNBox(width: 0.5, height: 0.6, length: 1.4, chamferRadius: 0.1)
        let bodyMaterial = SCNMaterial()
        bodyMaterial.diffuse.contents = UIColor(red: 0.2, green: 0.6, blue: 0.8, alpha: 1.0)
        bodyMaterial.roughness.contents = 0.3
        bodyGeometry.materials = [bodyMaterial]

        let bodyNode = SCNNode(geometry: bodyGeometry)
        bodyNode.position = SCNVector3(0, 0.5, 0)
        node.addChildNode(bodyNode)

        let seatGeometry = SCNBox(width: 0.35, height: 0.15, length: 0.5, chamferRadius: 0.05)
        let seatMaterial = SCNMaterial()
        seatMaterial.diffuse.contents = UIColor(red: 0.15, green: 0.1, blue: 0.05, alpha: 1.0)
        seatGeometry.materials = [seatMaterial]

        let seatNode = SCNNode(geometry: seatGeometry)
        seatNode.position = SCNVector3(0, 0.87, -0.1)
        node.addChildNode(seatNode)

        let wheelGeometry = SCNCylinder(radius: 0.25, height: 0.1)
        let wheelMaterial = SCNMaterial()
        wheelMaterial.diffuse.contents = UIColor.darkGray
        wheelGeometry.materials = [wheelMaterial]

        let frontWheel = SCNNode(geometry: wheelGeometry)
        frontWheel.name = "wheel_front"
        frontWheel.position = SCNVector3(0, 0.25, 0.5)
        frontWheel.eulerAngles.z = .pi / 2
        node.addChildNode(frontWheel)

        let rearWheel = SCNNode(geometry: wheelGeometry)
        rearWheel.name = "wheel_rear"
        rearWheel.position = SCNVector3(0, 0.25, -0.5)
        rearWheel.eulerAngles.z = .pi / 2
        node.addChildNode(rearWheel)

        let handlebarGeometry = SCNCylinder(radius: 0.02, height: 0.6)
        let handlebarMaterial = SCNMaterial()
        handlebarMaterial.diffuse.contents = UIColor.gray
        handlebarGeometry.materials = [handlebarMaterial]

        let handlebar = SCNNode(geometry: handlebarGeometry)
        handlebar.position = SCNVector3(0, 0.95, 0.4)
        handlebar.eulerAngles.x = .pi / 2
        node.addChildNode(handlebar)

        let rackGeometry = SCNBox(width: 0.4, height: 0.05, length: 0.3, chamferRadius: 0.02)
        let rackMaterial = SCNMaterial()
        rackMaterial.diffuse.contents = UIColor.gray
        rackGeometry.materials = [rackMaterial]

        let cargoRack = SCNNode(geometry: rackGeometry)
        cargoRack.name = "cargo_rack"
        cargoRack.position = SCNVector3(0, 0.82, -0.45)
        node.addChildNode(cargoRack)
    }

    private func setupPhysicsBody() {
        let shape = SCNPhysicsShape(
            geometry: SCNBox(width: 0.6, height: 1.2, length: 1.8, chamferRadius: 0.1),
            options: nil
        )

        // Use kinematic physics - we control position manually
        node.physicsBody = SCNPhysicsBody(type: .kinematic, shape: shape)
        node.physicsBody?.mass = CGFloat(mass)
        node.physicsBody?.friction = 0.8
        node.physicsBody?.restitution = 0.1
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
            currentSpeed = max(currentSpeed - 1.0 * dt, 0)
        }

        let speedFactor = min(currentSpeed / maxSpeed, 1.0)
        let targetLean = -currentSteering * speedFactor * 0.4
        leanAngle = leanAngle + (targetLean - leanAngle) * 0.1

        node.eulerAngles.z = leanAngle

        wheelRotation += currentSpeed * dt * 2.0
        if let frontWheel = node.childNode(withName: "wheel_front", recursively: true) {
            frontWheel.eulerAngles.x = wheelRotation
        }
        if let rearWheel = node.childNode(withName: "wheel_rear", recursively: true) {
            rearWheel.eulerAngles.x = wheelRotation
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
        let worldRotation = cargo.simdWorldTransform

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
