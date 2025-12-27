import SwiftUI

struct DeliveryCompleteView: View {
    let result: DeliveryResult
    @Bindable var coordinator: GameCoordinator

    @State private var showStars = false
    @State private var showScores = false
    @State private var animatedScore = 0

    var body: some View {
        ZStack {
            Color(red: 0.96, green: 0.9, blue: 0.78)
                .ignoresSafeArea()

            if result.starRating >= 2 {
                ConfettiView()
            }

            VStack(spacing: 24) {
                Spacer()
                    .frame(height: 60)

                headerSection

                starsSection
                    .opacity(showStars ? 1 : 0)
                    .offset(y: showStars ? 0 : 20)

                scoreBreakdownSection
                    .opacity(showScores ? 1 : 0)
                    .offset(y: showScores ? 0 : 20)

                coinsSection
                    .opacity(showScores ? 1 : 0)

                Spacer()

                buttonsSection
                    .padding(.bottom, 40)
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            animateResults()
        }
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            Text(result.cargoLost == 0 ? "PERFETTO!" : "DELIVERY COMPLETE!")
                .font(.system(size: result.cargoLost == 0 ? 36 : 28, weight: .black, design: .rounded))
                .foregroundColor(result.starRating >= 2 ?
                    Color(red: 0.36, green: 0.67, blue: 0.49) :
                    Color(red: 0.78, green: 0.36, blue: 0.22))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 1, y: 1)
        }
    }

    private var starsSection: some View {
        HStack(spacing: 16) {
            ForEach(0..<3) { index in
                Image(systemName: index < result.starRating ? "star.fill" : "star")
                    .font(.system(size: 48))
                    .foregroundColor(index < result.starRating ?
                        Color(red: 0.91, green: 0.72, blue: 0.29) :
                        Color.gray.opacity(0.3))
                    .shadow(color: index < result.starRating ? Color.orange.opacity(0.5) : .clear, radius: 8)
                    .scaleEffect(showStars ? 1 : 0.5)
                    .animation(
                        .spring(response: 0.4, dampingFraction: 0.5)
                            .delay(Double(index) * 0.2),
                        value: showStars
                    )
            }
        }
    }

    private var scoreBreakdownSection: some View {
        VStack(spacing: 0) {
            HStack {
                Text("SCORE BREAKDOWN")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(red: 0.17, green: 0.17, blue: 0.17))
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)

            Divider()
                .padding(.horizontal, 16)

            VStack(spacing: 12) {
                ScoreRow(label: "Cargo Delivered", value: "\(result.cargoDelivered) items", points: result.cargoDelivered * 50)

                if result.cargoLost > 0 {
                    ScoreRow(label: "Cargo Lost", value: "\(result.cargoLost) items", points: 0, isNegative: true)
                }

                ScoreRow(label: "Time", value: formatTime(result.timeElapsed), points: result.bonusPoints / 2)

                if result.cargoLost == 0 {
                    ScoreRow(label: "Perfect Delivery", value: "Bonus!", points: 500)
                }

                Divider()

                HStack {
                    Text("TOTAL")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color(red: 0.78, green: 0.36, blue: 0.22))

                    Spacer()

                    Text("\(animatedScore)")
                        .font(.system(size: 24, weight: .heavy))
                        .foregroundColor(Color(red: 0.78, green: 0.36, blue: 0.22))
                }
                .padding(.vertical, 8)
            }
            .padding(16)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }

    private var coinsSection: some View {
        HStack(spacing: 8) {
            Image(systemName: "dollarsign.circle.fill")
                .font(.system(size: 28))
                .foregroundColor(Color(red: 0.91, green: 0.72, blue: 0.29))

            Text("Coins Earned: \(result.totalScore / 10)")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color(red: 0.91, green: 0.72, blue: 0.29))
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 24)
        .background(
            Capsule()
                .fill(Color(red: 0.91, green: 0.72, blue: 0.29).opacity(0.2))
        )
    }

    private var buttonsSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                Button(action: {
                    coordinator.restartLevel()
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("RETRY")
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(red: 0.18, green: 0.42, blue: 0.54))
                    )
                }

                Button(action: {
                    coordinator.nextLevel()
                }) {
                    HStack {
                        Text("NEXT LEVEL")
                        Image(systemName: "arrow.right")
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(red: 0.78, green: 0.36, blue: 0.22))
                    )
                }
            }

            Button(action: {
                coordinator.returnToMainMenu()
            }) {
                Text("MAIN MENU")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(red: 0.29, green: 0.34, blue: 0.17))
            }
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func animateResults() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showStars = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeOut(duration: 0.3)) {
                showScores = true
            }

            animateScoreCount()
        }
    }

    private func animateScoreCount() {
        let duration: Double = 1.0
        let steps = 30
        let stepDuration = duration / Double(steps)
        let increment = result.totalScore / steps

        for i in 0..<steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(i)) {
                if i == steps - 1 {
                    animatedScore = result.totalScore
                } else {
                    animatedScore = increment * (i + 1)
                }
            }
        }
    }
}

struct ScoreRow: View {
    let label: String
    let value: String
    let points: Int
    var isNegative: Bool = false

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 15))
                .foregroundColor(Color(red: 0.17, green: 0.17, blue: 0.17))

            Spacer()

            Text(value)
                .font(.system(size: 14))
                .foregroundColor(.gray)

            Text(isNegative ? "-" : "+\(points)")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(isNegative ? .red : Color(red: 0.42, green: 0.48, blue: 0.24))
                .frame(width: 60, alignment: .trailing)
        }
    }
}

struct ConfettiView: View {
    @State private var confetti: [ConfettiPiece] = []

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(confetti) { piece in
                    Rectangle()
                        .fill(piece.color)
                        .frame(width: 10, height: 10)
                        .rotationEffect(.degrees(piece.rotation))
                        .position(piece.position)
                        .opacity(piece.opacity)
                }
            }
            .onAppear {
                createConfetti(in: geometry.size)
            }
        }
        .allowsHitTesting(false)
    }

    private func createConfetti(in size: CGSize) {
        let colors: [Color] = [
            Color(red: 0.78, green: 0.36, blue: 0.22),
            Color(red: 0.91, green: 0.72, blue: 0.29),
            Color(red: 0.42, green: 0.48, blue: 0.24),
            Color(red: 0.18, green: 0.42, blue: 0.54),
            .red, .orange, .yellow
        ]

        for i in 0..<50 {
            let piece = ConfettiPiece(
                id: i,
                color: colors.randomElement()!,
                position: CGPoint(x: CGFloat.random(in: 0...size.width), y: -20),
                rotation: Double.random(in: 0...360),
                opacity: 1.0
            )
            confetti.append(piece)
        }

        animateConfetti(in: size)
    }

    private func animateConfetti(in size: CGSize) {
        for i in confetti.indices {
            let delay = Double.random(in: 0...0.5)
            let duration = Double.random(in: 2...4)

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeOut(duration: duration)) {
                    confetti[i].position.y = size.height + 50
                    confetti[i].position.x += CGFloat.random(in: -100...100)
                    confetti[i].rotation += Double.random(in: 360...720)
                    confetti[i].opacity = 0
                }
            }
        }
    }
}

struct ConfettiPiece: Identifiable {
    let id: Int
    var color: Color
    var position: CGPoint
    var rotation: Double
    var opacity: Double
}

#Preview {
    DeliveryCompleteView(
        result: DeliveryResult(
            timeElapsed: 85,
            cargoDelivered: 4,
            cargoLost: 0,
            bonusPoints: 850,
            totalScore: 1250,
            starRating: 3
        ),
        coordinator: GameCoordinator()
    )
}
