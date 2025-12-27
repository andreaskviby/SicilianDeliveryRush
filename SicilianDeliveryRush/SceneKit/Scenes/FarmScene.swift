import SceneKit
import simd

final class FarmScene: BaseGameScene {
    override var sceneName: String { "FarmScene" }

    private var farmBuilding: SCNNode?
    private var crops: [SCNNode] = []
    private var harvestableAreas: [CropType: SCNNode] = [:]

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
        setupFarmBuilding()
        setupCropAreas()
        setupDecorations()
        setupCamera()
    }

    private func setupTerrain() {
        let floor = createFloor(size: 200)
        rootNode.addChildNode(floor)

        for i in 0..<5 {
            let hillGeometry = SCNSphere(radius: CGFloat(Float.random(in: 20...40)))
            let hillMaterial = SCNMaterial()
            hillMaterial.diffuse.contents = UIColor(red: 0.35, green: 0.5, blue: 0.25, alpha: 1)
            hillGeometry.materials = [hillMaterial]

            let hill = SCNNode(geometry: hillGeometry)
            let angle = Float(i) * (Float.pi * 2 / 5)
            let distance = Float.random(in: 60...100)
            hill.position = SCNVector3(
                cos(angle) * distance,
                -Float.random(in: 15...25),
                sin(angle) * distance
            )
            rootNode.addChildNode(hill)
        }
    }

    private func setupFarmBuilding() {
        let farmNode = SCNNode()
        farmNode.name = "farmBuilding"

        let houseGeometry = SCNBox(width: 8, height: 5, length: 6, chamferRadius: 0.2)
        let houseMaterial = SCNMaterial()
        houseMaterial.diffuse.contents = UIColor(red: 0.9, green: 0.85, blue: 0.7, alpha: 1)
        houseGeometry.materials = [houseMaterial]

        let house = SCNNode(geometry: houseGeometry)
        house.position = SCNVector3(0, 2.5, 0)
        farmNode.addChildNode(house)

        let roofGeometry = SCNPyramid(width: 9, height: 3, length: 7)
        let roofMaterial = SCNMaterial()
        roofMaterial.diffuse.contents = UIColor(red: 0.7, green: 0.3, blue: 0.2, alpha: 1)
        roofGeometry.materials = [roofMaterial]

        let roof = SCNNode(geometry: roofGeometry)
        roof.position = SCNVector3(0, 5, 0)
        farmNode.addChildNode(roof)

        let doorGeometry = SCNBox(width: 1.5, height: 2.5, length: 0.1, chamferRadius: 0.05)
        let doorMaterial = SCNMaterial()
        doorMaterial.diffuse.contents = UIColor(red: 0.4, green: 0.25, blue: 0.15, alpha: 1)
        doorGeometry.materials = [doorMaterial]

        let door = SCNNode(geometry: doorGeometry)
        door.position = SCNVector3(0, 1.25, 3.05)
        farmNode.addChildNode(door)

        farmNode.position = SCNVector3(0, 0, -20)
        rootNode.addChildNode(farmNode)
        farmBuilding = farmNode
    }

    private func setupCropAreas() {
        let cropPositions: [(CropType, SCNVector3)] = [
            (.tomatoes, SCNVector3(-15, 0, 10)),
            (.lemons, SCNVector3(15, 0, 10)),
            (.olives, SCNVector3(-15, 0, 25)),
            (.grapes, SCNVector3(15, 0, 25)),
            (.wheat, SCNVector3(0, 0, 35))
        ]

        for (cropType, position) in cropPositions {
            let cropArea = createCropArea(type: cropType)
            cropArea.position = position
            rootNode.addChildNode(cropArea)
            harvestableAreas[cropType] = cropArea
        }
    }

    private func createCropArea(type: CropType) -> SCNNode {
        let areaNode = SCNNode()
        areaNode.name = "cropArea_\(type.rawValue)"

        let plotGeometry = SCNBox(width: 8, height: 0.3, length: 8, chamferRadius: 0.1)
        let plotMaterial = SCNMaterial()
        plotMaterial.diffuse.contents = UIColor(red: 0.4, green: 0.3, blue: 0.2, alpha: 1)
        plotGeometry.materials = [plotMaterial]

        let plot = SCNNode(geometry: plotGeometry)
        plot.position = SCNVector3(0, 0.15, 0)
        areaNode.addChildNode(plot)

        let rows = 3
        let cols = 3
        let spacing: Float = 2.0

        for row in 0..<rows {
            for col in 0..<cols {
                let crop = createCropNode(type: type)
                crop.position = SCNVector3(
                    Float(col - 1) * spacing,
                    0.3,
                    Float(row - 1) * spacing
                )
                areaNode.addChildNode(crop)
                crops.append(crop)
            }
        }

        let signGeometry = SCNBox(width: 2, height: 1, length: 0.1, chamferRadius: 0.05)
        let signMaterial = SCNMaterial()
        signMaterial.diffuse.contents = UIColor(red: 0.6, green: 0.5, blue: 0.3, alpha: 1)
        signGeometry.materials = [signMaterial]

        let sign = SCNNode(geometry: signGeometry)
        sign.position = SCNVector3(0, 1, -4.5)
        areaNode.addChildNode(sign)

        return areaNode
    }

    private func createCropNode(type: CropType) -> SCNNode {
        let cropNode = SCNNode()
        cropNode.name = "crop_\(type.rawValue)"

        switch type {
        case .tomatoes:
            let plantGeometry = SCNSphere(radius: 0.3)
            let plantMaterial = SCNMaterial()
            plantMaterial.diffuse.contents = UIColor.red
            plantGeometry.materials = [plantMaterial]
            cropNode.geometry = plantGeometry

        case .lemons:
            let treeGeometry = SCNCone(topRadius: 0, bottomRadius: 0.5, height: 1.2)
            let treeMaterial = SCNMaterial()
            treeMaterial.diffuse.contents = UIColor(red: 0.2, green: 0.5, blue: 0.2, alpha: 1)
            treeGeometry.materials = [treeMaterial]
            cropNode.geometry = treeGeometry

        case .olives:
            let treeGeometry = SCNSphere(radius: 0.6)
            let treeMaterial = SCNMaterial()
            treeMaterial.diffuse.contents = UIColor(red: 0.3, green: 0.45, blue: 0.25, alpha: 1)
            treeGeometry.materials = [treeMaterial]
            cropNode.geometry = treeGeometry

        case .grapes:
            let vineGeometry = SCNBox(width: 0.8, height: 1.0, length: 0.3, chamferRadius: 0.1)
            let vineMaterial = SCNMaterial()
            vineMaterial.diffuse.contents = UIColor(red: 0.4, green: 0.2, blue: 0.4, alpha: 1)
            vineGeometry.materials = [vineMaterial]
            cropNode.geometry = vineGeometry

        case .wheat:
            let wheatGeometry = SCNCylinder(radius: 0.05, height: 0.8)
            let wheatMaterial = SCNMaterial()
            wheatMaterial.diffuse.contents = UIColor(red: 0.9, green: 0.8, blue: 0.4, alpha: 1)
            wheatGeometry.materials = [wheatMaterial]
            cropNode.geometry = wheatGeometry
        }

        return cropNode
    }

    private func setupDecorations() {
        for i in 0..<8 {
            let angle = Float(i) * (Float.pi / 4)
            let distance: Float = 50

            let treeNode = createOliveTree()
            treeNode.position = SCNVector3(
                cos(angle) * distance + Float.random(in: -5...5),
                0,
                sin(angle) * distance + Float.random(in: -5...5)
            )
            rootNode.addChildNode(treeNode)
        }

        let pathGeometry = SCNBox(width: 3, height: 0.05, length: 30, chamferRadius: 0)
        let pathMaterial = SCNMaterial()
        pathMaterial.diffuse.contents = UIColor(red: 0.6, green: 0.55, blue: 0.45, alpha: 1)
        pathGeometry.materials = [pathMaterial]

        let path = SCNNode(geometry: pathGeometry)
        path.position = SCNVector3(0, 0.025, 0)
        rootNode.addChildNode(path)
    }

    private func createOliveTree() -> SCNNode {
        let treeNode = SCNNode()
        treeNode.name = "oliveTree"

        let trunkGeometry = SCNCylinder(radius: 0.3, height: 2)
        let trunkMaterial = SCNMaterial()
        trunkMaterial.diffuse.contents = UIColor(red: 0.4, green: 0.3, blue: 0.2, alpha: 1)
        trunkGeometry.materials = [trunkMaterial]

        let trunk = SCNNode(geometry: trunkGeometry)
        trunk.position = SCNVector3(0, 1, 0)
        treeNode.addChildNode(trunk)

        let foliageGeometry = SCNSphere(radius: 1.5)
        let foliageMaterial = SCNMaterial()
        foliageMaterial.diffuse.contents = UIColor(red: 0.3, green: 0.5, blue: 0.25, alpha: 1)
        foliageGeometry.materials = [foliageMaterial]

        let foliage = SCNNode(geometry: foliageGeometry)
        foliage.position = SCNVector3(0, 2.8, 0)
        treeNode.addChildNode(foliage)

        return treeNode
    }

    private func setupCamera() {
        let camera = SCNNode()
        camera.name = "farmCamera"
        camera.camera = SCNCamera()
        camera.camera?.fieldOfView = 60
        camera.camera?.zNear = 0.1
        camera.camera?.zFar = 500

        camera.position = SCNVector3(0, 25, 40)
        camera.eulerAngles = SCNVector3(-Float.pi / 6, 0, 0)

        rootNode.addChildNode(camera)
    }

    override func update(deltaTime: TimeInterval) {
    }

    func getCropArea(for type: CropType) -> SCNNode? {
        harvestableAreas[type]
    }
}
