import SceneKit

protocol CollisionHandlerDelegate: AnyObject {
    func cargoFellOff(_ cargo: CargoNode)
    func vehicleCrashed(at position: simd_float3, severity: Float)
    func checkpointReached(_ checkpoint: Int)
    func finishLineReached()
}

final class CollisionHandler: NSObject, SCNPhysicsContactDelegate {
    weak var delegate: CollisionHandlerDelegate?

    private var processedContacts: Set<String> = []
    private var lastCleanupTime: TimeInterval = 0
    private let cleanupInterval: TimeInterval = 1.0

    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        let categoryA = contact.nodeA.physicsBody?.categoryBitMask ?? 0
        let categoryB = contact.nodeB.physicsBody?.categoryBitMask ?? 0

        handleCargoTerrainContact(contact: contact, categoryA: categoryA, categoryB: categoryB)
        handleVehicleObstacleContact(contact: contact, categoryA: categoryA, categoryB: categoryB)
        handleTriggerContact(contact: contact, categoryA: categoryA, categoryB: categoryB)
    }

    func physicsWorld(_ world: SCNPhysicsWorld, didUpdate contact: SCNPhysicsContact) {
    }

    func physicsWorld(_ world: SCNPhysicsWorld, didEnd contact: SCNPhysicsContact) {
    }

    private func handleCargoTerrainContact(contact: SCNPhysicsContact, categoryA: Int, categoryB: Int) {
        let isCargoTerrain = (categoryA == PhysicsCategory.cargo && categoryB == PhysicsCategory.terrain) ||
                             (categoryB == PhysicsCategory.cargo && categoryA == PhysicsCategory.terrain)

        let isCargoObstacle = (categoryA == PhysicsCategory.cargo && categoryB == PhysicsCategory.obstacle) ||
                              (categoryB == PhysicsCategory.cargo && categoryA == PhysicsCategory.obstacle)

        guard isCargoTerrain || isCargoObstacle else { return }

        let cargoNode: CargoNode?
        if categoryA == PhysicsCategory.cargo {
            cargoNode = contact.nodeA as? CargoNode
        } else {
            cargoNode = contact.nodeB as? CargoNode
        }

        guard let cargo = cargoNode else { return }

        if cargo.attachedSlot == nil {
            let contactId = "cargo_\(cargo.cargoItem.id)"
            guard !processedContacts.contains(contactId) else { return }
            processedContacts.insert(contactId)

            DispatchQueue.main.async { [weak self] in
                self?.delegate?.cargoFellOff(cargo)
            }
        }
    }

    private func handleVehicleObstacleContact(contact: SCNPhysicsContact, categoryA: Int, categoryB: Int) {
        let isVehicleObstacle = (categoryA == PhysicsCategory.vehicle && categoryB == PhysicsCategory.obstacle) ||
                                (categoryB == PhysicsCategory.vehicle && categoryA == PhysicsCategory.obstacle)

        guard isVehicleObstacle else { return }

        let severity = min(Float(contact.collisionImpulse) / 1000.0, 1.0)

        guard severity > 0.1 else { return }

        let position = simd_float3(
            Float(contact.contactPoint.x),
            Float(contact.contactPoint.y),
            Float(contact.contactPoint.z)
        )

        DispatchQueue.main.async { [weak self] in
            self?.delegate?.vehicleCrashed(at: position, severity: severity)
        }
    }

    private func handleTriggerContact(contact: SCNPhysicsContact, categoryA: Int, categoryB: Int) {
        let hasTrigger = categoryA == PhysicsCategory.trigger || categoryB == PhysicsCategory.trigger
        let hasVehicle = categoryA == PhysicsCategory.vehicle || categoryB == PhysicsCategory.vehicle

        guard hasTrigger && hasVehicle else { return }

        let triggerNode = categoryA == PhysicsCategory.trigger ? contact.nodeA : contact.nodeB

        guard let nodeName = triggerNode.name else { return }

        let contactId = "trigger_\(nodeName)"
        guard !processedContacts.contains(contactId) else { return }
        processedContacts.insert(contactId)

        if nodeName.hasPrefix("checkpoint_") {
            if let checkpointString = nodeName.replacingOccurrences(of: "checkpoint_", with: "").components(separatedBy: "_").first,
               let checkpoint = Int(checkpointString) {
                DispatchQueue.main.async { [weak self] in
                    self?.delegate?.checkpointReached(checkpoint)
                }
            }
        } else if nodeName == "finish_line" {
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.finishLineReached()
            }
        }
    }

    func cleanup(currentTime: TimeInterval) {
        if currentTime - lastCleanupTime > cleanupInterval {
            processedContacts.removeAll()
            lastCleanupTime = currentTime
        }
    }

    func reset() {
        processedContacts.removeAll()
        lastCleanupTime = 0
    }
}
