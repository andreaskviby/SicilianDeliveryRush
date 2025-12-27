import SwiftUI

struct SettingsView: View {
    @Bindable var coordinator: GameCoordinator
    @Environment(\.dismiss) private var dismiss

    @State private var settings: GameSettings

    init(coordinator: GameCoordinator) {
        self.coordinator = coordinator
        self._settings = State(initialValue: coordinator.dataManager.loadSettings())
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.96, green: 0.9, blue: 0.78)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        soundSection

                        controlsSection

                        graphicsSection

                        aboutSection
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        saveSettings()
                        dismiss()
                    }
                    .foregroundColor(Color(red: 0.78, green: 0.36, blue: 0.22))
                }
            }
        }
    }

    private var soundSection: some View {
        SettingsCard(title: "Sound", icon: "speaker.wave.2.fill") {
            VStack(spacing: 16) {
                SettingsSlider(
                    label: "Music",
                    value: $settings.musicVolume,
                    icon: "music.note"
                )

                SettingsSlider(
                    label: "Sound FX",
                    value: $settings.sfxVolume,
                    icon: "speaker.wave.3.fill"
                )

                SettingsToggle(
                    label: "Haptics",
                    isOn: $settings.hapticsEnabled,
                    icon: "iphone.radiowaves.left.and.right"
                )
            }
        }
    }

    private var controlsSection: some View {
        SettingsCard(title: "Controls", icon: "gamecontroller.fill") {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Control Type")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)

                    Picker("Control Type", selection: $settings.controlType) {
                        ForEach(GameSettings.ControlType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }

                SettingsSlider(
                    label: "Sensitivity",
                    value: $settings.tiltSensitivity,
                    icon: "dial.min.fill",
                    range: 0.5...2.0
                )

                SettingsToggle(
                    label: "Invert Steering",
                    isOn: $settings.invertY,
                    icon: "arrow.left.arrow.right"
                )

                if settings.controlType == .tilt {
                    Button(action: calibrateTilt) {
                        HStack {
                            Image(systemName: "scope")
                            Text("Calibrate Tilt")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(red: 0.18, green: 0.42, blue: 0.54))
                        )
                    }
                }
            }
        }
    }

    private var graphicsSection: some View {
        SettingsCard(title: "Graphics", icon: "sparkles") {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Quality")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)

                    Picker("Quality", selection: $settings.graphicsQuality) {
                        ForEach(GameSettings.GraphicsQuality.allCases, id: \.self) { quality in
                            Text(quality.displayName).tag(quality)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }

                SettingsToggle(
                    label: "60 FPS",
                    isOn: Binding(
                        get: { settings.targetFPS == 60 },
                        set: { settings.targetFPS = $0 ? 60 : 30 }
                    ),
                    icon: "speedometer"
                )
            }
        }
    }

    private var aboutSection: some View {
        SettingsCard(title: "About", icon: "info.circle.fill") {
            VStack(spacing: 12) {
                HStack {
                    Text("Version")
                        .foregroundColor(.gray)
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(Color(red: 0.17, green: 0.17, blue: 0.17))
                }
                .font(.system(size: 14))

                Divider()

                HStack(spacing: 24) {
                    Button("Credits") {
                    }
                    .foregroundColor(Color(red: 0.18, green: 0.42, blue: 0.54))

                    Button("Support") {
                    }
                    .foregroundColor(Color(red: 0.18, green: 0.42, blue: 0.54))

                    Button("Privacy") {
                    }
                    .foregroundColor(Color(red: 0.18, green: 0.42, blue: 0.54))
                }
                .font(.system(size: 14, weight: .medium))
            }
        }
    }

    private func saveSettings() {
        coordinator.dataManager.saveSettings(settings)
        coordinator.audioManager.setMusicVolume(settings.musicVolume)
        coordinator.audioManager.setSFXVolume(settings.sfxVolume)
    }

    private func calibrateTilt() {
        coordinator.inputManager.calibrate()
        coordinator.audioManager.play(.uiClick)
    }
}

struct SettingsCard<Content: View>: View {
    let title: String
    let icon: String
    let content: Content

    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(Color(red: 0.78, green: 0.36, blue: 0.22))

                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(red: 0.17, green: 0.17, blue: 0.17))
            }

            Divider()

            content
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(red: 0.42, green: 0.48, blue: 0.24), lineWidth: 2)
                )
        )
    }
}

struct SettingsSlider: View {
    let label: String
    @Binding var value: Float
    let icon: String
    var range: ClosedRange<Float> = 0...1

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .frame(width: 20)

                Text(label)
                    .font(.system(size: 14))
                    .foregroundColor(Color(red: 0.17, green: 0.17, blue: 0.17))

                Spacer()

                Text("\(Int(value * 100))%")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(red: 0.17, green: 0.17, blue: 0.17))
            }

            Slider(value: $value, in: range)
                .tint(Color(red: 0.78, green: 0.36, blue: 0.22))
        }
    }
}

struct SettingsToggle: View {
    let label: String
    @Binding var isOn: Bool
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .frame(width: 20)

            Text(label)
                .font(.system(size: 14))
                .foregroundColor(Color(red: 0.17, green: 0.17, blue: 0.17))

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Color(red: 0.42, green: 0.48, blue: 0.24))
        }
    }
}

#Preview {
    SettingsView(coordinator: GameCoordinator())
}
