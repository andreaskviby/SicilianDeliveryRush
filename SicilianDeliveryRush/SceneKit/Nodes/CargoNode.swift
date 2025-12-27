import SceneKit
import simd

final class CargoNode: SCNNode {
    let cargoItem: CargoItem
    var attachedSlot: Int?

    private var previousVelocity: simd_float3 = .zero
    private var accumulatedStress: Float = 0
    private var isDetached: Bool = false

    init(item: CargoItem) {
        self.cargoItem = item
        super.init()

        name = "cargo_\(item.id.uuidString)"
        setupGeometry()
        setupPhysics()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupGeometry() {
        let box = SCNBox(
            width: CGFloat(cargoItem.type.boundingBox.x),
            height: CGFloat(cargoItem.type.boundingBox.y),
            length: CGFloat(cargoItem.type.boundingBox.z),
            chamferRadius: 0.02
        )

        let material = SCNMaterial()
        material.diffuse.contents = cargoItem.type.color
        material.roughness.contents = 0.7
        material.lightingModel = .physicallyBased

        box.materials = [material]
        self.geometry = box

        addDecorations()
    }

    private func addDecorations() {
        switch cargoItem.type {
        case .wine:
            let neckGeometry = SCNCylinder(radius: 0.03, height: 0.1)
            let neckMaterial = SCNMaterial()
            neckMaterial.diffuse.contents = cargoItem.type.color
            neckGeometry.materials = [neckMaterial]

            let neck = SCNNode(geometry: neckGeometry)
            neck.position = SCNVector3(0, Float(cargoItem.type.boundingBox.y / 2) + 0.05, 0)
            addChildNode(neck)

        case .oliveOil:
            let capGeometry = SCNCylinder(radius: 0.02, height: 0.03)
            let capMaterial = SCNMaterial()
            capMaterial.diffuse.contents = UIColor.brown
            capGeometry.materials = [capMaterial]

            let cap = SCNNode(geometry: capGeometry)
            cap.position = SCNVector3(0, Float(cargoItem.type.boundingBox.y / 2) + 0.015, 0)
            addChildNode(cap)

        case .cheese:
            let wedgeGeometry = SCNCone(topRadius: 0.05, bottomRadius: 0.12, height: 0.1)
            let wedgeMaterial = SCNMaterial()
            wedgeMaterial.diffuse.contents = cargoItem.type.color
            wedgeGeometry.materials = [wedgeMaterial]

        default:
            break
        }
    }

    private func setupPhysics() {
        let shape = SCNPhysicsShape(
            geometry: SCNBox(
                width: CGFloat(cargoItem.type.boundingBox.x),
                height: CGFloat(cargoItem.type.boundingBox.y),
                length: CGFloat(cargoItem.type.boundingBox.z),
                chamferRadius: 0
            ),
            options: nil
        )

        physicsBody = SCNPhysicsBody(type: .dynamic, shape: shape)
        physicsBody?.mass = CGFloat(cargoItem.type.weight)
        physicsBody?.friction = CGFloat(GameConfiguration.Physics.cargoFriction)
        physicsBody?.restitution = 0.2
        physicsBody?.categoryBitMask = PhysicsCategory.cargo
        physicsBody?.contactTestBitMask = PhysicsCategory.terrain | PhysicsCategory.obstacle
        physicsBody?.collisionBitMask = PhysicsCategory.vehicle | PhysicsCategory.terrain | PhysicsCategory.cargo

        physicsBody?.isAffectedByGravity = false
    }

    func updateStability(vehicleLateralG: Float, deltaTime: TimeInterval) -> Bool {
        guard !isDetached else { return false }

        let stressThreshold = GameConfiguration.Physics.cargoSlipThreshold
        let fallThreshold = GameConfiguration.Physics.cargoFallThreshold

        let stress = vehicleLateralG * cargoItem.type.fragility

        if stress > stressThreshold {
            accumulatedStress += stress * Float(deltaTime)

            let shakeAmount = min(stress * 0.02, 0.05)
            let randomOffset = simd_float3(
                Float.random(in: -shakeAmount...shakeAmount),
                0,
                Float.random(in: -shakeAmount...shakeAmount)
            )
            simdPosition += randomOffset
        } else {
            accumulatedStress = max(0, accumulatedStress - Float(deltaTime) * 0.5)
        }

        if accumulatedStress > fallThreshold || vehicleLateralG > fallThreshold * 1.5 {
            detachFromVehicle()
            return false
        }

        return true
    }

    var stressLevel: Float {
        accumulatedStress / GameConfiguration.Physics.cargoFallThreshold
    }

    func detachFromVehicle() {
        guard !isDetached else { return }
        isDetached = true

        physicsBody?.isAffectedByGravity = true

        if let parent = parent, let vehicleBody = parent.physicsBody {
            physicsBody?.velocity = vehicleBody.velocity

            physicsBody?.angularVelocity = SCNVector4(
                Float.random(in: -2...2),
                Float.random(in: -2...2),
                Float.random(in: -2...2),
                Float.random(in: 1...3)
            )
        }

        attachedSlot = nil
    }

    func reset() {
        isDetached = false
        accumulatedStress = 0
        physicsBody?.isAffectedByGravity = false
        physicsBody?.velocity = SCNVector3Zero
        physicsBody?.angularVelocity = SCNVector4Zero
    }
}
