import CoreMotion
import UIKit
import Combine

enum ControlType: String, CaseIterable, Codable {
    case tilt
    case touch
    case twoThumb

    var displayName: String {
        switch self {
        case .tilt: return "Tilt"
        case .touch: return "Touch"
        case .twoThumb: return "Two Thumb"
        }
    }
}

struct InputState {
    var steering: Float = 0
    var throttle: Float = 0
    var brake: Float = 0

    static let zero = InputState()
}

final class InputManager: ObservableObject {
    @Published var currentInput = InputState()
    @Published var controlType: ControlType = .tilt

    private let motionManager = CMMotionManager()
    private var referenceAttitude: CMAttitude?

    var sensitivity: Float = 1.0
    var deadZone: Float = 0.05
    var invertSteering: Bool = false

    private var isMotionActive = false

    init() {
        loadSettings()
    }

    deinit {
        stopMotionUpdates()
    }

    private func loadSettings() {
        let dataManager = GameDataManager()
        let settings = dataManager.loadSettings()
        controlType = settings.controlType == .tilt ? .tilt :
                      settings.controlType == .touch ? .touch : .twoThumb
        sensitivity = settings.tiltSensitivity
    }

    func startMotionUpdates() {
        guard controlType == .tilt else { return }
        guard motionManager.isDeviceMotionAvailable else {
            print("Device motion not available")
            return
        }

        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0

        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let self = self, let motion = motion else { return }

            if self.referenceAttitude == nil {
                self.referenceAttitude = motion.attitude.copy() as? CMAttitude
            }

            self.processMotion(motion)
        }

        isMotionActive = true
    }

    func stopMotionUpdates() {
        motionManager.stopDeviceMotionUpdates()
        isMotionActive = false
        referenceAttitude = nil
    }

    func calibrate() {
        referenceAttitude = nil
    }

    private func processMotion(_ motion: CMDeviceMotion) {
        guard let reference = referenceAttitude else { return }

        let attitude = motion.attitude
        attitude.multiply(byInverseOf: reference)

        var roll = Float(attitude.roll)

        if abs(roll) < deadZone {
            roll = 0
        } else {
            roll = (roll - deadZone * (roll > 0 ? 1 : -1))
        }

        let maxTilt = GameConfiguration.Controls.maxTiltAngle
        var normalizedRoll = (roll / maxTilt).clamped(to: -1...1)

        normalizedRoll *= sensitivity

        if invertSteering {
            normalizedRoll = -normalizedRoll
        }

        currentInput.steering = normalizedRoll
    }

    func handleTouchBegan(at location: CGPoint, in bounds: CGRect) {
        guard controlType == .touch || controlType == .twoThumb else { return }

        let normalizedX = Float(location.x / bounds.width)

        if controlType == .twoThumb {
            if normalizedX < 0.4 {
                currentInput.brake = 1.0
            } else if normalizedX > 0.6 {
                currentInput.throttle = 1.0
            }
        } else {
            if normalizedX > 0.5 {
                currentInput.throttle = 1.0
            }
        }
    }

    func handleTouchMoved(at location: CGPoint, from startLocation: CGPoint, in bounds: CGRect) {
        guard controlType == .touch else { return }

        let deltaX = Float(location.x - startLocation.x)
        let steeringRadius = Float(GameConfiguration.Controls.touchSteeringRadius)

        let steering = (deltaX / steeringRadius).clamped(to: -1...1) * sensitivity
        currentInput.steering = invertSteering ? -steering : steering
    }

    func handleTouchEnded(at location: CGPoint, in bounds: CGRect) {
        let normalizedX = Float(location.x / bounds.width)

        if controlType == .twoThumb {
            if normalizedX < 0.4 {
                currentInput.brake = 0
            } else if normalizedX > 0.6 {
                currentInput.throttle = 0
            }
        } else {
            currentInput.throttle = 0
            currentInput.steering = 0
        }
    }

    func setThrottle(_ value: Float) {
        currentInput.throttle = value.clamped(to: 0...1)
    }

    func setBrake(_ value: Float) {
        currentInput.brake = value.clamped(to: 0...1)
    }

    func setSteering(_ value: Float) {
        let steering = value.clamped(to: -1...1) * sensitivity
        currentInput.steering = invertSteering ? -steering : steering
    }

    func reset() {
        currentInput = .zero
    }
}
