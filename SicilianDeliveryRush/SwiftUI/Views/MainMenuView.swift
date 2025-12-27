import SwiftUI

struct MainMenuView: View {
    @Bindable var coordinator: GameCoordinator
    @State private var showSettings = false
    @State private var showLeaderboard = false
    @State private var animateVespa = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                backgroundGradient

                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: geometry.safeAreaInsets.top + 40)

                    titleSection

                    Spacer()
                        .frame(height: 30)

                    animatedVespa

                    Spacer()

                    buttonSection

                    Spacer()
                        .frame(height: geometry.safeAreaInsets.bottom + 20)
                }
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(coordinator: coordinator)
        }
    }

    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.53, green: 0.81, blue: 0.92),
                Color(red: 0.96, green: 0.64, blue: 0.38).opacity(0.6)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .overlay(
            hillsSilhouette
                .offset(y: 200)
            , alignment: .bottom
        )
    }

    private var hillsSilhouette: some View {
        ZStack {
            Wave(amplitude: 30, frequency: 0.01, phase: 0)
                .fill(Color(red: 0.4, green: 0.5, blue: 0.3).opacity(0.5))
                .frame(height: 150)

            Wave(amplitude: 20, frequency: 0.015, phase: 0.5)
                .fill(Color(red: 0.35, green: 0.45, blue: 0.25).opacity(0.7))
                .frame(height: 120)
                .offset(y: 30)
        }
    }

    private var titleSection: some View {
        VStack(spacing: 8) {
            Text("SICILIAN")
                .font(.system(size: 36, weight: .black, design: .rounded))
                .foregroundColor(Color(red: 0.78, green: 0.36, blue: 0.22))
                .shadow(color: Color(red: 0.55, green: 0.24, blue: 0.16), radius: 0, x: 2, y: 2)

            Text("DELIVERY RUSH")
                .font(.system(size: 48, weight: .black, design: .rounded))
                .foregroundColor(Color(red: 0.17, green: 0.17, blue: 0.17))
                .shadow(color: .white.opacity(0.8), radius: 0, x: 1, y: 1)
        }
    }

    private var animatedVespa: some View {
        VStack {
            Image(systemName: "scooter")
                .font(.system(size: 80))
                .foregroundColor(Color(red: 0.2, green: 0.6, blue: 0.8))
                .shadow(color: .black.opacity(0.3), radius: 4, x: 2, y: 2)
                .offset(y: animateVespa ? -5 : 5)
                .animation(
                    Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                    value: animateVespa
                )

            HStack(spacing: 8) {
                ForEach(0..<3) { index in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(red: 0.6, green: 0.4, blue: 0.2))
                        .frame(width: 20, height: 15)
                        .offset(y: animateVespa ? -2 : 2)
                        .animation(
                            Animation.easeInOut(duration: 1.2)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.1),
                            value: animateVespa
                        )
                }
            }
            .offset(x: 30, y: -20)
        }
        .onAppear {
            animateVespa = true
        }
    }

    private var buttonSection: some View {
        VStack(spacing: 16) {
            Button(action: {
                coordinator.audioManager.playButtonTap()
                coordinator.startNewGame()
            }) {
                HStack {
                    Image(systemName: "play.fill")
                    Text("PLAY")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                }
                .foregroundColor(Color(red: 0.99, green: 0.96, blue: 0.9))
                .frame(width: 280, height: 64)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(red: 0.78, green: 0.36, blue: 0.22))
                        .shadow(color: Color(red: 0.17, green: 0.17, blue: 0.17).opacity(0.3), radius: 8, x: 0, y: 4)
                )
            }
            .buttonStyle(ScaleButtonStyle())

            HStack(spacing: 16) {
                Button(action: {
                    coordinator.audioManager.playButtonTap()
                    showLeaderboard = true
                }) {
                    HStack {
                        Image(systemName: "trophy.fill")
                        Text("SCORES")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(Color(red: 0.29, green: 0.34, blue: 0.17))
                    .frame(width: 130, height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(red: 0.99, green: 0.96, blue: 0.9))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(red: 0.42, green: 0.48, blue: 0.24), lineWidth: 3)
                            )
                    )
                }
                .buttonStyle(ScaleButtonStyle())

                Button(action: {
                    coordinator.audioManager.playButtonTap()
                    showSettings = true
                }) {
                    HStack {
                        Image(systemName: "gearshape.fill")
                        Text("SETTINGS")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(Color(red: 0.29, green: 0.34, blue: 0.17))
                    .frame(width: 130, height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(red: 0.99, green: 0.96, blue: 0.9))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(red: 0.42, green: 0.48, blue: 0.24), lineWidth: 3)
                            )
                    )
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct Wave: Shape {
    var amplitude: CGFloat
    var frequency: CGFloat
    var phase: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: 0, y: rect.height))

        for x in stride(from: 0, through: rect.width, by: 1) {
            let relativeX = x / rect.width
            let sine = sin((relativeX + phase) * .pi * 2 * frequency * rect.width)
            let y = rect.height / 2 + amplitude * sine
            path.addLine(to: CGPoint(x: x, y: y))
        }

        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.closeSubpath()

        return path
    }
}

#Preview {
    MainMenuView(coordinator: GameCoordinator())
}
