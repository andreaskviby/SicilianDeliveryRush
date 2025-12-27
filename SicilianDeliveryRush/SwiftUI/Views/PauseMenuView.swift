import SwiftUI

struct PauseMenuView: View {
    @Bindable var coordinator: GameCoordinator

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Text("PAUSED")
                    .font(.system(size: 42, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 4, x: 2, y: 2)

                VStack(spacing: 16) {
                    PauseMenuButton(
                        title: "RESUME",
                        icon: "play.fill",
                        color: Color(red: 0.42, green: 0.48, blue: 0.24)
                    ) {
                        coordinator.resumeFromPause()
                    }

                    PauseMenuButton(
                        title: "RESTART",
                        icon: "arrow.clockwise",
                        color: Color(red: 0.91, green: 0.72, blue: 0.29)
                    ) {
                        coordinator.restartLevel()
                    }

                    PauseMenuButton(
                        title: "MAIN MENU",
                        icon: "house.fill",
                        color: Color(red: 0.78, green: 0.36, blue: 0.22)
                    ) {
                        coordinator.returnToMainMenu()
                    }
                }
                .padding(.horizontal, 40)

                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "speaker.wave.2.fill")
                            .foregroundColor(.white)
                        Text("Sound")
                            .foregroundColor(.white)
                        Spacer()
                        Toggle("", isOn: .constant(true))
                            .labelsHidden()
                            .tint(Color(red: 0.42, green: 0.48, blue: 0.24))
                    }

                    HStack {
                        Image(systemName: "iphone.radiowaves.left.and.right")
                            .foregroundColor(.white)
                        Text("Haptics")
                            .foregroundColor(.white)
                        Spacer()
                        Toggle("", isOn: .constant(true))
                            .labelsHidden()
                            .tint(Color(red: 0.42, green: 0.48, blue: 0.24))
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.1))
                )
                .padding(.horizontal, 40)
            }
        }
    }
}

struct PauseMenuButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .bold))

                Text(title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(color)
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

#Preview {
    PauseMenuView(coordinator: GameCoordinator())
}
