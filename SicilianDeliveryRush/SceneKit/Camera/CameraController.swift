import SceneKit
import simd

enum CameraMode {
    case firstPerson
    case thirdPerson
    case cinematic

    var fieldOfView: CGFloat {
        switch self {
        case .firstPerson: return 75
        case .thirdPerson: return 60
        case .cinematic: return 50
        }
    }
}

final class CameraController {
    let cameraNode: SCNNode
    private weak var targetNode: SCNNode?
    private var mode: CameraMode

    private let fpvOffset = simd_float3(0, 1.2, 0.3)
    private let fpvLookAhead: Float = 5.0

    private let tpOffset = simd_float3(0, 3, -8)
    private let tpLookOffset = simd_float3(0, 1, 5)

    private var currentPosition: simd_float3 = .zero
    private var currentLookAt: simd_float3 = .zero
    private var positionSmoothing: Float = 0.1
    private var rotationSmoothing: Float = 0.15

    private var shakeIntensity: Float = 0
    private var shakeDecay: Float = 5.0

    private var speedEffectIntensity: Float = 0

    init(target: SCNNode, mode: CameraMode = .firstPerson) {
        self.targetNode = target
        self.mode = mode

        cameraNode = SCNNode()
        cameraNode.name = "mainCamera"
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.fieldOfView = mode.fieldOfView
        cameraNode.camera?.zNear = 0.1
        cameraNode.camera?.zFar = Double(GameConfiguration.Visual.drawDistance)
        cameraNode.camera?.motionBlurIntensity = 0.1

        if let target = targetNode {
            currentPosition = target.simdPosition + fpvOffset
            currentLookAt = target.simdPosition + target.simdWorldFront * fpvLookAhead
        }
    }

    func setupCamera(in scene: SCNScene) {
        scene.rootNode.addChildNode(cameraNode)
    }

    func setMode(_ newMode: CameraMode) {
        mode = newMode
        cameraNode.camera?.fieldOfView = mode.fieldOfView

        switch mode {
        case .firstPerson:
            positionSmoothing = 0.1
            rotationSmoothing = 0.15
        case .thirdPerson:
            positionSmoothing = 0.08
            rotationSmoothing = 0.1
        case .cinematic:
            positionSmoothing = 0.03
            rotationSmoothing = 0.05
        }
    }

    func update(deltaTime: TimeInterval) {
        guard let target = targetNode else { return }

        let dt = Float(deltaTime)

        var targetPosition: simd_float3
        var lookAtPosition: simd_float3

        switch mode {
        case .firstPerson:
            let vehicleTransform = target.simdWorldTransform
            let localOffset = simd_float4(fpvOffset.x, fpvOffset.y, fpvOffset.z, 1)
            let worldOffset = vehicleTransform * localOffset
            targetPosition = simd_float3(worldOffset.x, worldOffset.y, worldOffset.z)

            let forward = target.simdWorldFront
            lookAtPosition = target.simdWorldPosition + forward * fpvLookAhead

        case .thirdPerson:
            let vehicleTransform = target.simdWorldTransform
            let localOffset = simd_float4(tpOffset.x, tpOffset.y, tpOffset.z, 1)
            let worldOffset = vehicleTransform * localOffset
            targetPosition = simd_float3(worldOffset.x, worldOffset.y, worldOffset.z)

            lookAtPosition = target.simdWorldPosition + simd_float3(0, 1, 0)

        case .cinematic:
            targetPosition = currentPosition
            lookAtPosition = target.simdWorldPosition
        }

        currentPosition = simd_mix(currentPosition, targetPosition, simd_float3(repeating: positionSmoothing))
        currentLookAt = simd_mix(currentLookAt, lookAtPosition, simd_float3(repeating: rotationSmoothing))

        var finalPosition = currentPosition
        if shakeIntensity > 0.01 {
            finalPosition += simd_float3(
                Float.random(in: -1...1) * shakeIntensity,
                Float.random(in: -1...1) * shakeIntensity,
                Float.random(in: -1...1) * shakeIntensity
            )
            shakeIntensity *= (1.0 - shakeDecay * dt)
        }

        cameraNode.simdPosition = finalPosition
        cameraNode.simdLook(at: currentLookAt)

        updateSpeedEffects()
    }

    private func updateSpeedEffects() {
        guard let target = targetNode,
              let vehicle = target as? SCNNode,
              let body = vehicle.physicsBody else { return }

        let speed = simd_length(simd_float3(
            Float(body.velocity.x),
            Float(body.velocity.y),
            Float(body.velocity.z)
        ))

        let maxSpeed = GameConfiguration.Physics.vespaMaxSpeed
        speedEffectIntensity = min(speed / maxSpeed, 1.0)

        let baseFOV = mode.fieldOfView
        let fovIncrease = CGFloat(speedEffectIntensity) * 10
        cameraNode.camera?.fieldOfView = baseFOV + fovIncrease

        cameraNode.camera?.motionBlurIntensity = CGFloat(speedEffectIntensity * 0.3)
    }

    func addShake(intensity: Float) {
        shakeIntensity = max(shakeIntensity, intensity)
    }

    func setTarget(_ node: SCNNode) {
        targetNode = node
        currentPosition = node.simdPosition
        currentLookAt = node.simdPosition + node.simdWorldFront * 5
    }

    func teleportToTarget() {
        guard let target = targetNode else { return }

        switch mode {
        case .firstPerson:
            let vehicleTransform = target.simdWorldTransform
            let localOffset = simd_float4(fpvOffset.x, fpvOffset.y, fpvOffset.z, 1)
            let worldOffset = vehicleTransform * localOffset
            currentPosition = simd_float3(worldOffset.x, worldOffset.y, worldOffset.z)

        case .thirdPerson:
            let vehicleTransform = target.simdWorldTransform
            let localOffset = simd_float4(tpOffset.x, tpOffset.y, tpOffset.z, 1)
            let worldOffset = vehicleTransform * localOffset
            currentPosition = simd_float3(worldOffset.x, worldOffset.y, worldOffset.z)

        case .cinematic:
            break
        }

        currentLookAt = target.simdWorldPosition
        cameraNode.simdPosition = currentPosition
        cameraNode.simdLook(at: currentLookAt)
    }
}
