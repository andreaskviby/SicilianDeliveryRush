import SceneKit
import simd

enum RoadComplexity {
    case easy
    case medium
    case hard

    var numCurves: Int {
        switch self {
        case .easy: return 4
        case .medium: return 8
        case .hard: return 12
        }
    }

    var deviationMultiplier: Float {
        switch self {
        case .easy: return 0.15
        case .medium: return 0.25
        case .hard: return 0.35
        }
    }
}

struct RoadSegment {
    let position: simd_float3
    let direction: simd_float3
    let banking: Float
    let width: Float
}

final class RoadGenerator {
    private let roadWidth: Float = 4.0
    private let roadSegmentLength: Float = 2.0

    private var segments: [RoadSegment] = []

    func generateMountainRoad(
        startPoint: simd_float3,
        endPoint: simd_float3,
        complexity: RoadComplexity
    ) -> SCNNode {
        let roadNode = SCNNode()
        roadNode.name = "road"

        let controlPoints = generateControlPoints(
            from: startPoint,
            to: endPoint,
            complexity: complexity
        )

        segments = generateSegments(along: controlPoints)

        let roadGeometry = buildRoadGeometry(from: segments)

        let material = createRoadMaterial()
        roadGeometry.materials = [material]

        roadNode.geometry = roadGeometry

        setupRoadPhysics(for: roadNode)

        addCheckpoints(to: roadNode)
        addRoadDecorations(to: roadNode)

        return roadNode
    }

    private func generateControlPoints(
        from start: simd_float3,
        to end: simd_float3,
        complexity: RoadComplexity
    ) -> [simd_float3] {
        var points: [simd_float3] = [start]

        let totalDistance = simd_length(end - start)
        let numCurves = complexity.numCurves
        let maxDeviation = totalDistance * complexity.deviationMultiplier

        for i in 1..<numCurves {
            let t = Float(i) / Float(numCurves)
            let basePoint = simd_mix(start, end, simd_float3(repeating: t))

            let side = (i % 2 == 0) ? Float(1) : Float(-1)
            let direction = simd_normalize(end - start)
            let perpendicular = simd_normalize(simd_cross(direction, simd_float3(0, 1, 0)))

            let deviation = perpendicular * side * Float.random(in: maxDeviation * 0.5...maxDeviation)

            var point = basePoint + deviation

            let heightProgress = 1.0 - t
            point.y = start.y * heightProgress + end.y * t

            points.append(point)
        }

        points.append(end)
        return points
    }

    private func generateSegments(along controlPoints: [simd_float3]) -> [RoadSegment] {
        var segments: [RoadSegment] = []

        let numSegmentsPerCurve = 20

        for i in 0..<(controlPoints.count - 1) {
            let p0 = i > 0 ? controlPoints[i - 1] : controlPoints[i]
            let p1 = controlPoints[i]
            let p2 = controlPoints[i + 1]
            let p3 = i < controlPoints.count - 2 ? controlPoints[i + 2] : controlPoints[i + 1]

            for j in 0..<numSegmentsPerCurve {
                let t = Float(j) / Float(numSegmentsPerCurve)

                let position = catmullRom(p0: p0, p1: p1, p2: p2, p3: p3, t: t)
                let nextPos = catmullRom(p0: p0, p1: p1, p2: p2, p3: p3, t: min(t + 0.01, 1.0))
                let direction = simd_normalize(nextPos - position)

                let curvature = calculateCurvature(p0: p0, p1: p1, p2: p2, p3: p3, t: t)
                let banking = curvature * 0.3

                segments.append(RoadSegment(
                    position: position,
                    direction: direction,
                    banking: banking,
                    width: roadWidth
                ))
            }
        }

        return segments
    }

    private func catmullRom(p0: simd_float3, p1: simd_float3, p2: simd_float3, p3: simd_float3, t: Float) -> simd_float3 {
        let t2 = t * t
        let t3 = t2 * t

        let term0: simd_float3 = 2 * p1
        let negP0: simd_float3 = -p0
        let term1: simd_float3 = (negP0 + p2) * t

        let twoP0: simd_float3 = 2 * p0
        let fiveP1: simd_float3 = 5 * p1
        let fourP2: simd_float3 = 4 * p2
        let term2Part: simd_float3 = twoP0 - fiveP1 + fourP2 - p3
        let term2: simd_float3 = term2Part * t2

        let threeP1: simd_float3 = 3 * p1
        let threeP2: simd_float3 = 3 * p2
        let term3Part: simd_float3 = negP0 + threeP1 - threeP2 + p3
        let term3: simd_float3 = term3Part * t3

        let sum: simd_float3 = term0 + term1 + term2 + term3
        return 0.5 * sum
    }

    private func calculateCurvature(p0: simd_float3, p1: simd_float3, p2: simd_float3, p3: simd_float3, t: Float) -> Float {
        let dt: Float = 0.01

        let pos0 = catmullRom(p0: p0, p1: p1, p2: p2, p3: p3, t: max(0, t - dt))
        let pos1 = catmullRom(p0: p0, p1: p1, p2: p2, p3: p3, t: t)
        let pos2 = catmullRom(p0: p0, p1: p1, p2: p2, p3: p3, t: min(1, t + dt))

        let d1 = pos1 - pos0
        let d2 = pos2 - pos1

        let cross = simd_cross(d1, d2)
        let lenD1 = simd_length(d1)

        guard lenD1 > 0.0001 else { return 0 }

        return simd_length(cross) / (lenD1 * lenD1 * lenD1 + 0.0001)
    }

    private func buildRoadGeometry(from segments: [RoadSegment]) -> SCNGeometry {
        var vertices: [SCNVector3] = []
        var normals: [SCNVector3] = []
        var texCoords: [CGPoint] = []
        var indices: [UInt32] = []

        let halfWidth = roadWidth / 2

        for (index, segment) in segments.enumerated() {
            let right = simd_normalize(simd_cross(segment.direction, simd_float3(0, 1, 0)))
            let up = simd_normalize(simd_cross(right, segment.direction))

            let bankAngle = segment.banking
            let cosBank = cos(bankAngle)
            let sinBank = sin(bankAngle)
            let bankedRight = right * cosBank + up * sinBank
            let bankedUp = -right * sinBank + up * cosBank

            let leftPos = segment.position - bankedRight * halfWidth
            let rightPos = segment.position + bankedRight * halfWidth

            vertices.append(SCNVector3(leftPos))
            vertices.append(SCNVector3(rightPos))

            normals.append(SCNVector3(bankedUp))
            normals.append(SCNVector3(bankedUp))

            let v = Float(index) * roadSegmentLength / roadWidth
            texCoords.append(CGPoint(x: 0, y: Double(v)))
            texCoords.append(CGPoint(x: 1, y: Double(v)))

            if index > 0 {
                let baseIndex = UInt32((index - 1) * 2)
                indices.append(contentsOf: [
                    baseIndex, baseIndex + 2, baseIndex + 1,
                    baseIndex + 1, baseIndex + 2, baseIndex + 3
                ])
            }
        }

        let vertexSource = SCNGeometrySource(vertices: vertices)
        let normalSource = SCNGeometrySource(normals: normals)
        let texCoordSource = SCNGeometrySource(textureCoordinates: texCoords)
        let element = SCNGeometryElement(indices: indices, primitiveType: .triangles)

        return SCNGeometry(sources: [vertexSource, normalSource, texCoordSource], elements: [element])
    }

    private func createRoadMaterial() -> SCNMaterial {
        let material = SCNMaterial()
        material.diffuse.contents = UIColor(red: 0.3, green: 0.3, blue: 0.35, alpha: 1)
        material.roughness.contents = 0.7
        material.lightingModel = .physicallyBased

        return material
    }

    private func setupRoadPhysics(for node: SCNNode) {
        guard let geometry = node.geometry else { return }

        let shape = SCNPhysicsShape(geometry: geometry, options: [
            .type: SCNPhysicsShape.ShapeType.concavePolyhedron
        ])

        node.physicsBody = SCNPhysicsBody(type: .static, shape: shape)
        node.physicsBody?.categoryBitMask = PhysicsCategory.road
        node.physicsBody?.friction = CGFloat(GameConfiguration.Physics.groundFriction)
    }

    private func addCheckpoints(to roadNode: SCNNode) {
        let checkpointInterval = max(segments.count / 5, 1)

        for i in stride(from: checkpointInterval, to: segments.count - checkpointInterval, by: checkpointInterval) {
            let segment = segments[i]
            let checkpointNumber = i / checkpointInterval

            let checkpoint = createCheckpointTrigger(at: segment, number: checkpointNumber)
            roadNode.addChildNode(checkpoint)
        }

        if let lastSegment = segments.last {
            let finishLine = createFinishLineTrigger(at: lastSegment)
            roadNode.addChildNode(finishLine)
        }
    }

    private func createCheckpointTrigger(at segment: RoadSegment, number: Int) -> SCNNode {
        let trigger = SCNNode()
        trigger.name = "checkpoint_\(number)"
        trigger.simdPosition = segment.position

        let triggerGeometry = SCNBox(width: CGFloat(roadWidth + 2), height: 5, length: 1, chamferRadius: 0)
        triggerGeometry.firstMaterial?.diffuse.contents = UIColor.clear
        trigger.geometry = triggerGeometry

        let shape = SCNPhysicsShape(geometry: triggerGeometry, options: nil)
        trigger.physicsBody = SCNPhysicsBody(type: .static, shape: shape)
        trigger.physicsBody?.categoryBitMask = PhysicsCategory.trigger
        trigger.physicsBody?.collisionBitMask = 0

        let right = simd_normalize(simd_cross(segment.direction, simd_float3(0, 1, 0)))
        let leftPost = createCheckpointPost(color: .orange)
        leftPost.simdPosition = segment.position - right * (roadWidth / 2 + 0.5)
        trigger.addChildNode(leftPost)

        let rightPost = createCheckpointPost(color: .orange)
        rightPost.simdPosition = segment.position + right * (roadWidth / 2 + 0.5)
        trigger.addChildNode(rightPost)

        return trigger
    }

    private func createCheckpointPost(color: UIColor) -> SCNNode {
        let postGeometry = SCNCylinder(radius: 0.15, height: 3)
        let postMaterial = SCNMaterial()
        postMaterial.diffuse.contents = color
        postGeometry.materials = [postMaterial]

        let post = SCNNode(geometry: postGeometry)
        post.position.y = 1.5

        return post
    }

    private func createFinishLineTrigger(at segment: RoadSegment) -> SCNNode {
        let trigger = SCNNode()
        trigger.name = "finish_line"
        trigger.simdPosition = segment.position

        let triggerGeometry = SCNBox(width: CGFloat(roadWidth + 2), height: 5, length: 2, chamferRadius: 0)
        triggerGeometry.firstMaterial?.diffuse.contents = UIColor.clear
        trigger.geometry = triggerGeometry

        let shape = SCNPhysicsShape(geometry: triggerGeometry, options: nil)
        trigger.physicsBody = SCNPhysicsBody(type: .static, shape: shape)
        trigger.physicsBody?.categoryBitMask = PhysicsCategory.trigger
        trigger.physicsBody?.collisionBitMask = 0

        let bannerGeometry = SCNBox(width: CGFloat(roadWidth + 1), height: 1, length: 0.1, chamferRadius: 0.05)
        let bannerMaterial = SCNMaterial()
        bannerMaterial.diffuse.contents = UIColor.white
        bannerGeometry.materials = [bannerMaterial]

        let banner = SCNNode(geometry: bannerGeometry)
        banner.position = SCNVector3(0, 4, 0)
        trigger.addChildNode(banner)

        let right = simd_normalize(simd_cross(segment.direction, simd_float3(0, 1, 0)))

        let leftPost = createCheckpointPost(color: .red)
        leftPost.simdPosition = -right * (roadWidth / 2 + 0.5)
        leftPost.scale = SCNVector3(1.5, 1.5, 1.5)
        trigger.addChildNode(leftPost)

        let rightPost = createCheckpointPost(color: .red)
        rightPost.simdPosition = right * (roadWidth / 2 + 0.5)
        rightPost.scale = SCNVector3(1.5, 1.5, 1.5)
        trigger.addChildNode(rightPost)

        return trigger
    }

    private func addRoadDecorations(to roadNode: SCNNode) {
        let decorationInterval = max(segments.count / 20, 1)

        for i in stride(from: 0, to: segments.count, by: decorationInterval) {
            let segment = segments[i]
            let right = simd_normalize(simd_cross(segment.direction, simd_float3(0, 1, 0)))

            if Bool.random() {
                let tree = createRoadsideTree()
                let side: Float = Bool.random() ? 1 : -1
                tree.simdPosition = segment.position + right * side * (roadWidth / 2 + Float.random(in: 2...5))
                roadNode.addChildNode(tree)
            }

            if Bool.random() && i % (decorationInterval * 2) == 0 {
                let rock = createRoadsideRock()
                let side: Float = Bool.random() ? 1 : -1
                rock.simdPosition = segment.position + right * side * (roadWidth / 2 + Float.random(in: 1...3))
                roadNode.addChildNode(rock)
            }
        }
    }

    private func createRoadsideTree() -> SCNNode {
        let treeNode = SCNNode()
        treeNode.name = "roadsideTree"

        let trunkGeometry = SCNCylinder(radius: 0.2, height: 1.5)
        let trunkMaterial = SCNMaterial()
        trunkMaterial.diffuse.contents = UIColor(red: 0.4, green: 0.3, blue: 0.2, alpha: 1)
        trunkGeometry.materials = [trunkMaterial]

        let trunk = SCNNode(geometry: trunkGeometry)
        trunk.position = SCNVector3(0, 0.75, 0)
        treeNode.addChildNode(trunk)

        let foliageGeometry = SCNCone(topRadius: 0, bottomRadius: 1.0, height: 2.0)
        let foliageMaterial = SCNMaterial()
        foliageMaterial.diffuse.contents = UIColor(red: 0.2, green: 0.4, blue: 0.2, alpha: 1)
        foliageGeometry.materials = [foliageMaterial]

        let foliage = SCNNode(geometry: foliageGeometry)
        foliage.position = SCNVector3(0, 2.5, 0)
        treeNode.addChildNode(foliage)

        return treeNode
    }

    private func createRoadsideRock() -> SCNNode {
        let rockGeometry = SCNSphere(radius: CGFloat(Float.random(in: 0.3...0.8)))
        let rockMaterial = SCNMaterial()
        rockMaterial.diffuse.contents = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)
        rockMaterial.roughness.contents = 0.9
        rockGeometry.materials = [rockMaterial]

        let rock = SCNNode(geometry: rockGeometry)
        rock.name = "roadsideRock"
        rock.scale = SCNVector3(1, Float.random(in: 0.5...0.8), 1)

        return rock
    }

    func getStartPosition() -> simd_float3? {
        segments.first?.position
    }

    func getStartDirection() -> simd_float3? {
        segments.first?.direction
    }

    func getSegments() -> [RoadSegment] {
        segments
    }
}
