import SwiftUI

struct DrivingHUDView: View {
    let phase: GamePhase.DrivingPhase
    @Bindable var coordinator: GameCoordinator
    weak var scene: DrivingScene?

    @State private var countdownValue: Int = 3
    @State private var showCountdown: Bool = true
    @State private var elapsedTime: TimeInterval = 0
    @State private var currentSpeed: Float = 0
    @State private var cargoStress: Float = 0

    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                TouchControlsView(
                    onSteeringChange: { value in
                        scene?.handleSteeringInput(Float(value))
                    },
                    onThrottleChange: { value in
                        scene?.handleThrottleInput(Float(value))
                    },
                    onBrakeChange: { value in
                        scene?.handleBrakeInput(Float(value))
                    }
                )

                VStack {
                    HStack {
                        TimerView(time: elapsedTime)
                            .padding(.top, geometry.safeAreaInsets.top + 8)
                            .padding(.leading, 16)

                        Spacer()

                        Button(action: {
                            coordinator.transitionTo(.paused(previousPhase: .driving(phase)))
                        }) {
                            Image(systemName: "pause.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Circle().fill(.ultraThinMaterial))
                        }
                        .padding(.top, geometry.safeAreaInsets.top + 8)
                        .padding(.trailing, 16)
                    }

                    Spacer()
                }

                VStack {
                    Spacer()

                    CargoStabilityBar(stressLevel: cargoStress)
                        .frame(width: 280, height: 36)
                        .padding(.bottom, 20)

                    HStack(alignment: .bottom, spacing: 20) {
                        MiniMapView()
                            .frame(width: 100, height: 100)
                            .padding(.leading, 16)

                        Spacer()

                        SpeedometerView(speed: currentSpeed)
                            .frame(width: 100, height: 100)
                            .padding(.trailing, 16)
                    }
                    .padding(.bottom, geometry.safeAreaInsets.bottom + 16)
                }

                if showCountdown && phase == .countdown {
                    CountdownOverlay(
                        value: $countdownValue,
                        onComplete: {
                            showCountdown = false
                            scene?.startRace()
                            coordinator.startRacing()
                        }
                    )
                }

                if phase == .cargoFalling {
                    CargoWarningOverlay()
                }
            }
        }
        .onReceive(timer) { _ in
            updateHUD()
        }
    }

    private func updateHUD() {
        elapsedTime = scene?.currentElapsedTime ?? 0
        currentSpeed = scene?.currentSpeedKmh ?? 0
        cargoStress = scene?.cargoStressLevel ?? 0
    }
}

struct TimerView: View {
    let time: TimeInterval

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "stopwatch.fill")
                .font(.system(size: 16))
                .foregroundColor(Color(red: 0.91, green: 0.72, blue: 0.29))

            Text(formatTime(time))
                .font(.system(size: 22, weight: .heavy, design: .monospaced))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.7))
        )
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let milliseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%d:%02d.%02d", minutes, seconds, milliseconds)
    }
}

struct CargoStabilityBar: View {
    let stressLevel: Float

    var body: some View {
        VStack(spacing: 4) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.black.opacity(0.5))

                    RoundedRectangle(cornerRadius: 8)
                        .fill(stabilityColor)
                        .frame(width: geometry.size.width * CGFloat(1 - stressLevel))
                }
            }

            Text(stabilityText)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(stabilityColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.6))
        )
    }

    private var stabilityColor: Color {
        switch stressLevel {
        case 0..<0.3:
            return Color(red: 0.36, green: 0.67, blue: 0.49)
        case 0.3..<0.6:
            return Color(red: 0.91, green: 0.72, blue: 0.29)
        default:
            return Color(red: 0.84, green: 0.27, blue: 0.27)
        }
    }

    private var stabilityText: String {
        switch stressLevel {
        case 0..<0.3: return "STABLE"
        case 0.3..<0.6: return "CAUTION"
        default: return "DANGER!"
        }
    }
}

struct SpeedometerView: View {
    let speed: Float

    var body: some View {
        ZStack {
            Circle()
                .fill(Color(red: 0.99, green: 0.96, blue: 0.9))
                .overlay(
                    Circle()
                        .stroke(Color(red: 0.6, green: 0.5, blue: 0.4), lineWidth: 4)
                )

            VStack(spacing: 2) {
                Text("\(Int(speed))")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundColor(Color(red: 0.17, green: 0.17, blue: 0.17))

                Text("km/h")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
            }

            SpeedometerNeedle(speed: speed, maxSpeed: 60)
        }
        .shadow(color: .black.opacity(0.3), radius: 4, x: 2, y: 2)
    }
}

struct SpeedometerNeedle: View {
    let speed: Float
    let maxSpeed: Float

    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let radius = min(geometry.size.width, geometry.size.height) / 2 - 10
            let angle = -135 + (Double(speed / maxSpeed) * 270)

            Path { path in
                path.move(to: center)
                let endPoint = CGPoint(
                    x: center.x + CGFloat(cos(angle * .pi / 180)) * radius * 0.7,
                    y: center.y + CGFloat(sin(angle * .pi / 180)) * radius * 0.7
                )
                path.addLine(to: endPoint)
            }
            .stroke(Color.red, style: StrokeStyle(lineWidth: 3, lineCap: .round))
        }
    }
}

struct MiniMapView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.96, green: 0.9, blue: 0.78).opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(red: 0.55, green: 0.24, blue: 0.16), lineWidth: 2)
                )

            VStack {
                Image(systemName: "location.north.fill")
                    .font(.system(size: 8))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing, 8)
                    .padding(.top, 4)

                Spacer()

                Circle()
                    .fill(Color.blue)
                    .frame(width: 12, height: 12)

                Path { path in
                    path.move(to: CGPoint(x: 50, y: 80))
                    path.addCurve(
                        to: CGPoint(x: 50, y: 20),
                        control1: CGPoint(x: 30, y: 60),
                        control2: CGPoint(x: 70, y: 40)
                    )
                }
                .stroke(Color.red.opacity(0.6), style: StrokeStyle(lineWidth: 2, dash: [4, 2]))

                Spacer()

                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.red)
                    .padding(.bottom, 8)
            }
        }
    }
}

struct CountdownOverlay: View {
    @Binding var value: Int
    let onComplete: () -> Void

    @State private var scale: CGFloat = 2.0
    @State private var opacity: Double = 0

    var body: some View {
        Text(value > 0 ? "\(value)" : "GO!")
            .font(.system(size: 120, weight: .black, design: .rounded))
            .foregroundColor(.white)
            .shadow(color: .black.opacity(0.5), radius: 10)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                animateCountdown()
            }
    }

    private func animateCountdown() {
        withAnimation(.easeOut(duration: 0.3)) {
            scale = 1.0
            opacity = 1.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation(.easeIn(duration: 0.2)) {
                opacity = 0
                scale = 0.8
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if value > 0 {
                value -= 1
                scale = 2.0
                animateCountdown()
            } else {
                onComplete()
            }
        }
    }
}

struct CargoWarningOverlay: View {
    @State private var isFlashing = false

    var body: some View {
        VStack {
            Text("CARGO FALLING!")
                .font(.system(size: 24, weight: .black))
                .foregroundColor(.white)
                .padding()
                .background(Color.red.opacity(isFlashing ? 0.8 : 0.5))
                .cornerRadius(12)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.3).repeatForever(autoreverses: true)) {
                isFlashing = true
            }
        }
    }
}

struct TouchControlsView: View {
    let onSteeringChange: (Double) -> Void
    let onThrottleChange: (Double) -> Void
    let onBrakeChange: (Double) -> Void

    @State private var steeringValue: Double = 0
    @State private var throttleActive: Bool = false
    @State private var brakeActive: Bool = false
    @State private var steeringTouchLocation: CGPoint?

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                Rectangle()
                    .fill(Color.red.opacity(brakeActive ? 0.3 : 0.1))
                    .frame(width: 100)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                brakeActive = true
                                onBrakeChange(1.0)
                            }
                            .onEnded { _ in
                                brakeActive = false
                                onBrakeChange(0.0)
                            }
                    )
                    .overlay(
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.white.opacity(0.5))
                    )

                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                if steeringTouchLocation == nil {
                                    steeringTouchLocation = value.startLocation
                                }

                                if let startLocation = steeringTouchLocation {
                                    let deltaX = value.location.x - startLocation.x
                                    let steeringRadius: CGFloat = 80
                                    steeringValue = Double((deltaX / steeringRadius).clamped(to: -1...1))
                                    onSteeringChange(steeringValue)
                                }
                            }
                            .onEnded { _ in
                                steeringTouchLocation = nil
                                withAnimation(.easeOut(duration: 0.2)) {
                                    steeringValue = 0
                                }
                                onSteeringChange(0)
                            }
                    )
                    .overlay(
                        SteeringIndicator(value: steeringValue)
                            .frame(height: 60)
                            .padding(.horizontal, 40)
                            .padding(.bottom, 100)
                        , alignment: .bottom
                    )

                Rectangle()
                    .fill(Color.green.opacity(throttleActive ? 0.3 : 0.1))
                    .frame(width: 100)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                throttleActive = true
                                onThrottleChange(1.0)
                            }
                            .onEnded { _ in
                                throttleActive = false
                                onThrottleChange(0.0)
                            }
                    )
                    .overlay(
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.white.opacity(0.5))
                    )
            }
        }
        .ignoresSafeArea()
    }
}

struct SteeringIndicator: View {
    let value: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Capsule()
                    .fill(Color.white.opacity(0.2))

                Circle()
                    .fill(Color.white)
                    .frame(width: 50, height: 50)
                    .offset(x: CGFloat(value) * (geometry.size.width / 2 - 25))
            }
        }
    }
}

#Preview {
    DrivingHUDView(
        phase: .racing,
        coordinator: GameCoordinator(),
        scene: nil
    )
    .background(Color.gray)
}
