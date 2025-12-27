import SceneKit
import simd

final class DrivingScene: BaseGameScene {
    override var sceneName: String { "DrivingScene" }

    private var vehicle: Vehicle?
    private var vehiclePhysics: VehiclePhysicsController?
    private var cargoNodes: [CargoNode] = []

    private var terrain: MountainTerrain?
    private var roadGenerator: RoadGenerator?
    private var checkpointsPassed: Set<Int> = []

    private var raceStartTime: TimeInterval?
    private var elapsedTime: TimeInterval = 0
    private var isRaceActive: Bool = false

    private var currentInput = VehicleInput()

    var onCargoLost: ((CargoItem) -> Void)?
    var onCheckpointReached: ((Int) -> Void)?
    var onRaceComplete: ((TimeInterval) -> Void)?
    var onCrash: ((Float) -> Void)?

    required init(coordinator: GameCoordinator) {
        super.init(coordinator: coordinator)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareScene() {
        setupSkybox()
        addCartoonLighting()
        setupFog()
        setupTerrain()
        setupRoad()
        setupVehicle()
        setupCargo()
        setupCamera()
        setupEnvironment()

        collisionHandler.delegate = self
    }

    private func setupTerrain() {
        terrain = MountainTerrain()
        terrain?.generate(width: 200, depth: 200, maxHeight: 50)

        if let terrainNode = terrain?.node {
            rootNode.addChildNode(terrainNode)
        }
    }

    private func setupRoad() {
        roadGenerator = RoadGenerator()

        let startPoint = simd_float3(0, 45, -80)
        let endPoint = simd_float3(50, 5, 80)

        guard let road = roadGenerator?.generateMountainRoad(
            startPoint: startPoint,
            endPoint: endPoint,
            complexity: .medium
        ) else { return }

        rootNode.addChildNode(road)
    }

    private func setupVehicle() {
        guard let coordinator = coordinator else { return }

        vehicle = VehicleFactory.create(type: coordinator.selectedVehicle)
        guard let vehicle = vehicle else { return }

        if let startPos = roadGenerator?.getStartPosition(),
           let startDir = roadGenerator?.getStartDirection() {
            vehicle.node.simdPosition = startPos + simd_float3(0, 0.5, 0)

            let angle = atan2(startDir.x, startDir.z)
            vehicle.node.simdEulerAngles.y = angle
        } else {
            vehicle.node.simdPosition = simd_float3(0, 46, -80)
        }

        rootNode.addChildNode(vehicle.node)

        vehiclePhysics = VehiclePhysicsController(vehicle: vehicle)
        vehiclePhysics?.cargoLostHandler = { [weak self] cargoNode in
            self?.handleCargoLost(cargoNode)
        }
    }

    private func setupCargo() {
        guard let vehicle = vehicle, let coordinator = coordinator else { return }

        for (index, item) in coordinator.loadedCargo.enumerated() {
            let cargoNode = CargoNode(item: item)
            vehicle.attachCargo(cargoNode, at: index)
            cargoNodes.append(cargoNode)
        }

        vehiclePhysics?.attachCargo(cargoNodes)
    }

    private func setupCamera() {
        guard let vehicle = vehicle else { return }

        cameraController = CameraController(
            target: vehicle.node,
            mode: .firstPerson
        )
        cameraController?.setupCamera(in: self)
        cameraController?.teleportToTarget()
    }

    private func setupEnvironment() {
        addSicilianProps()
    }

    private func addSicilianProps() {
        for _ in 0..<15 {
            let tree = createOliveTree()
            tree.position = SCNVector3(
                Float.random(in: -80...80),
                0,
                Float.random(in: -80...80)
            )

            if let terrainHeight = terrain?.heightAt(x: tree.position.x, z: tree.position.z) {
                tree.position.y = terrainHeight
            }

            rootNode.addChildNode(tree)
        }

        for _ in 0..<8 {
            let cypress = createCypressTree()
            cypress.position = SCNVector3(
                Float.random(in: -80...80),
                0,
                Float.random(in: -80...80)
            )

            if let terrainHeight = terrain?.heightAt(x: cypress.position.x, z: cypress.position.z) {
                cypress.position.y = terrainHeight
            }

            rootNode.addChildNode(cypress)
        }
    }

    private func createOliveTree() -> SCNNode {
        let treeNode = SCNNode()
        treeNode.name = "oliveTree"

        let trunkGeometry = SCNCylinder(radius: 0.25, height: 1.8)
        let trunkMaterial = SCNMaterial()
        trunkMaterial.diffuse.contents = UIColor(red: 0.45, green: 0.35, blue: 0.25, alpha: 1)
        trunkGeometry.materials = [trunkMaterial]

        let trunk = SCNNode(geometry: trunkGeometry)
        trunk.position = SCNVector3(0, 0.9, 0)
        treeNode.addChildNode(trunk)

        let foliageGeometry = SCNSphere(radius: 1.3)
        let foliageMaterial = SCNMaterial()
        foliageMaterial.diffuse.contents = UIColor(red: 0.35, green: 0.5, blue: 0.3, alpha: 1)
        foliageGeometry.materials = [foliageMaterial]

        let foliage = SCNNode(geometry: foliageGeometry)
        foliage.position = SCNVector3(0, 2.5, 0)
        foliage.scale = SCNVector3(1, 0.7, 1)
        treeNode.addChildNode(foliage)

        return treeNode
    }

    private func createCypressTree() -> SCNNode {
        let treeNode = SCNNode()
        treeNode.name = "cypressTree"

        let trunkGeometry = SCNCylinder(radius: 0.15, height: 4)
        let trunkMaterial = SCNMaterial()
        trunkMaterial.diffuse.contents = UIColor(red: 0.35, green: 0.25, blue: 0.15, alpha: 1)
        trunkGeometry.materials = [trunkMaterial]

        let trunk = SCNNode(geometry: trunkGeometry)
        trunk.position = SCNVector3(0, 2, 0)
        treeNode.addChildNode(trunk)

        let foliageGeometry = SCNCone(topRadius: 0.1, bottomRadius: 0.8, height: 5)
        let foliageMaterial = SCNMaterial()
        foliageMaterial.diffuse.contents = UIColor(red: 0.15, green: 0.35, blue: 0.2, alpha: 1)
        foliageGeometry.materials = [foliageMaterial]

        let foliage = SCNNode(geometry: foliageGeometry)
        foliage.position = SCNVector3(0, 4.5, 0)
        treeNode.addChildNode(foliage)

        return treeNode
    }

    override func update(deltaTime: TimeInterval) {
        guard isRaceActive else { return }

        if raceStartTime == nil {
            raceStartTime = CACurrentMediaTime()
        }
        elapsedTime = CACurrentMediaTime() - (raceStartTime ?? 0)

        vehiclePhysics?.update(deltaTime: deltaTime, input: currentInput)

        cameraController?.update(deltaTime: deltaTime)

        collisionHandler.cleanup(currentTime: CACurrentMediaTime())
    }

    func startRace() {
        isRaceActive = true
        raceStartTime = nil
        elapsedTime = 0
        checkpointsPassed.removeAll()
    }

    func pauseRace() {
        isRaceActive = false
    }

    func resumeRace() {
        isRaceActive = true
    }

    func handleSteeringInput(_ value: Float) {
        currentInput.steering = value.clamped(to: -1...1)
    }

    func handleThrottleInput(_ value: Float) {
        currentInput.throttle = value.clamped(to: 0...1)
    }

    func handleBrakeInput(_ value: Float) {
        currentInput.brake = value.clamped(to: 0...1)
    }

    var currentSpeed: Float {
        vehicle?.currentSpeed ?? 0
    }

    var currentSpeedKmh: Float {
        (vehicle?.currentSpeed ?? 0) * 3.6
    }

    var currentElapsedTime: TimeInterval {
        elapsedTime
    }

    var cargoStressLevel: Float {
        vehiclePhysics?.getAverageCargoStress() ?? 0
    }

    var remainingCargoCount: Int {
        cargoNodes.filter { $0.attachedSlot != nil }.count
    }

    private func handleCargoLost(_ cargoNode: CargoNode) {
        coordinator?.cargoItemLost(cargoNode.cargoItem)
        onCargoLost?(cargoNode.cargoItem)

        cameraController?.addShake(intensity: 0.3)

        physicsWorld.speed = 0.3
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.physicsWorld.speed = 1.0
        }
    }

    func switchCameraMode(_ mode: CameraMode) {
        cameraController?.setMode(mode)
    }
}

extension DrivingScene: CollisionHandlerDelegate {
    func cargoFellOff(_ cargo: CargoNode) {
        handleCargoLost(cargo)
    }

    func vehicleCrashed(at position: simd_float3, severity: Float) {
        coordinator?.audioManager.play(.crash)
        cameraController?.addShake(intensity: severity * 0.5)
        onCrash?(severity)

        if severity > 0.7 {
        }
    }

    func checkpointReached(_ checkpoint: Int) {
        guard !checkpointsPassed.contains(checkpoint) else { return }
        checkpointsPassed.insert(checkpoint)
        coordinator?.audioManager.play(.checkpoint)
        onCheckpointReached?(checkpoint)
    }

    func finishLineReached() {
        isRaceActive = false
        coordinator?.audioManager.play(.raceComplete)
        onRaceComplete?(elapsedTime)
        coordinator?.completeDelivery(timeElapsed: elapsedTime)
    }
}
