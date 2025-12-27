import SceneKit

class BaseGameScene: SCNScene {
    weak var coordinator: GameCoordinator?

    var cameraController: CameraController?
    let collisionHandler = CollisionHandler()

    var sceneName: String { "" }

    required init(coordinator: GameCoordinator) {
        self.coordinator = coordinator
        super.init()

        physicsWorld.contactDelegate = collisionHandler
        physicsWorld.gravity = SCNVector3(0, GameConfiguration.Physics.gravity, 0)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func prepareScene() {
    }

    func update(deltaTime: TimeInterval) {
    }

    func addCartoonLighting() {
        let sunLight = SCNNode()
        sunLight.name = "sunLight"
        sunLight.light = SCNLight()
        sunLight.light?.type = .directional
        sunLight.light?.intensity = 1000
        sunLight.light?.color = UIColor(red: 1.0, green: 0.95, blue: 0.8, alpha: 1)
        sunLight.light?.castsShadow = true
        sunLight.light?.shadowMode = .forward
        sunLight.light?.shadowColor = UIColor(white: 0, alpha: 0.3)
        sunLight.light?.shadowMapSize = CGSize(width: 2048, height: 2048)
        sunLight.light?.shadowRadius = 3
        sunLight.light?.shadowSampleCount = 8
        sunLight.eulerAngles = SCNVector3(-Float.pi / 4, Float.pi / 6, 0)
        rootNode.addChildNode(sunLight)

        let ambientLight = SCNNode()
        ambientLight.name = "ambientLight"
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.intensity = 400
        ambientLight.light?.color = UIColor(red: 0.6, green: 0.7, blue: 0.9, alpha: 1)
        rootNode.addChildNode(ambientLight)
    }

    func setupFog() {
        fogStartDistance = 100
        fogEndDistance = CGFloat(GameConfiguration.Visual.drawDistance)
        fogColor = UIColor(red: 0.7, green: 0.8, blue: 0.9, alpha: 1)
        fogDensityExponent = 1.5
    }

    func setupSkybox() {
        background.contents = UIColor(red: 0.4, green: 0.6, blue: 0.9, alpha: 1)
    }

    func createFloor(size: Float = 500) -> SCNNode {
        let floor = SCNFloor()
        floor.reflectivity = 0.1

        let material = SCNMaterial()
        material.diffuse.contents = UIColor(red: 0.4, green: 0.5, blue: 0.3, alpha: 1)
        material.roughness.contents = 0.9
        floor.materials = [material]

        let floorNode = SCNNode(geometry: floor)
        floorNode.name = "floor"
        floorNode.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
        floorNode.physicsBody?.categoryBitMask = PhysicsCategory.terrain
        floorNode.physicsBody?.friction = CGFloat(GameConfiguration.Physics.groundFriction)

        return floorNode
    }
}
