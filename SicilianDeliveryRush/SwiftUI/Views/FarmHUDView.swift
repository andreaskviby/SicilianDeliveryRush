import SwiftUI

struct FarmHUDView: View {
    @Bindable var coordinator: GameCoordinator

    @State private var selectedCrop: CropType?
    @State private var showInventory = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack {
                    HStack {
                        TimeIndicator()
                            .padding(.top, geometry.safeAreaInsets.top + 8)
                            .padding(.leading, 16)

                        Spacer()

                        InventoryCounter(count: coordinator.harvestedItems.count, max: 20)
                            .padding(.top, geometry.safeAreaInsets.top + 8)
                            .padding(.trailing, 16)
                    }

                    Spacer()
                }

                VStack {
                    Spacer()

                    CropSelector(
                        selectedCrop: $selectedCrop,
                        onHarvest: { crop in
                            coordinator.harvestCrop(crop)
                        }
                    )
                    .padding(.horizontal, 16)

                    InventoryPanel(items: coordinator.harvestedItems)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)

                    Button(action: {
                        let order = DeliveryOrderGenerator.generateOrder(forLevel: coordinator.currentLevel)
                        coordinator.startNewDelivery(order: order)
                    }) {
                        HStack {
                            Image(systemName: "shippingbox.fill")
                            Text("LOAD VEHICLE")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .frame(width: 200, height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(coordinator.harvestedItems.isEmpty ?
                                      Color.gray : Color(red: 0.78, green: 0.36, blue: 0.22))
                        )
                    }
                    .disabled(coordinator.harvestedItems.isEmpty)
                    .padding(.bottom, geometry.safeAreaInsets.bottom + 16)
                }
            }
        }
    }
}

struct TimeIndicator: View {
    @State private var currentTime = Date()

    let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: timeIcon)
                .font(.system(size: 16))
                .foregroundColor(timeColor)

            Text(timeString)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(red: 0.17, green: 0.17, blue: 0.17))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.99, green: 0.96, blue: 0.9).opacity(0.9))
        )
        .onReceive(timer) { _ in
            currentTime = Date()
        }
    }

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: currentTime)
    }

    private var hour: Int {
        Calendar.current.component(.hour, from: currentTime)
    }

    private var timeIcon: String {
        switch hour {
        case 6..<18: return "sun.max.fill"
        default: return "moon.fill"
        }
    }

    private var timeColor: Color {
        switch hour {
        case 6..<12: return Color(red: 0.91, green: 0.72, blue: 0.29)
        case 12..<17: return Color(red: 0.96, green: 0.64, blue: 0.38)
        case 17..<20: return Color(red: 0.78, green: 0.36, blue: 0.22)
        default: return Color(red: 0.18, green: 0.42, blue: 0.54)
        }
    }
}

struct InventoryCounter: View {
    let count: Int
    let max: Int

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "backpack.fill")
                .font(.system(size: 16))
                .foregroundColor(Color(red: 0.42, green: 0.48, blue: 0.24))

            Text("\(count)/\(max)")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.42, green: 0.48, blue: 0.24).opacity(0.9))
        )
    }
}

struct CropSelector: View {
    @Binding var selectedCrop: CropType?
    let onHarvest: (CropType) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(CropType.allCases, id: \.self) { crop in
                    CropButton(
                        crop: crop,
                        isSelected: selectedCrop == crop,
                        onTap: {
                            selectedCrop = crop
                            onHarvest(crop)
                        }
                    )
                }
            }
            .padding(.horizontal, 8)
        }
        .frame(height: 80)
    }
}

struct CropButton: View {
    let crop: CropType
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Image(systemName: iconName)
                    .font(.system(size: 28))
                    .foregroundColor(iconColor)

                Text(crop.displayName)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Color(red: 0.17, green: 0.17, blue: 0.17))
            }
            .frame(width: 60, height: 70)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(red: 0.99, green: 0.96, blue: 0.9))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isSelected ? Color(red: 0.42, green: 0.48, blue: 0.24) : Color.clear, lineWidth: 3)
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private var iconName: String {
        switch crop {
        case .tomatoes: return "circle.fill"
        case .lemons: return "leaf.fill"
        case .olives: return "circle.fill"
        case .grapes: return "circle.grid.2x2.fill"
        case .wheat: return "leaf.arrow.triangle.circlepath"
        }
    }

    private var iconColor: Color {
        switch crop {
        case .tomatoes: return .red
        case .lemons: return .yellow
        case .olives: return Color(red: 0.4, green: 0.5, blue: 0.3)
        case .grapes: return .purple
        case .wheat: return Color(red: 0.9, green: 0.8, blue: 0.4)
        }
    }
}

struct InventoryPanel: View {
    let items: [CargoItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("INVENTORY")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color(red: 0.17, green: 0.17, blue: 0.17))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(items) { item in
                        InventorySlot(item: item)
                    }

                    ForEach(0..<max(0, 8 - items.count), id: \.self) { _ in
                        EmptyInventorySlot()
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.96, green: 0.9, blue: 0.78))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(red: 0.55, green: 0.24, blue: 0.16), lineWidth: 3)
                )
        )
    }
}

struct InventorySlot: View {
    let item: CargoItem

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: item.type.iconName)
                .font(.system(size: 20))
                .foregroundColor(Color(item.type.color))

            Text(String(item.type.displayName.prefix(4)))
                .font(.system(size: 8, weight: .medium))
                .foregroundColor(.gray)
        }
        .frame(width: 48, height: 48)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(red: 0.78, green: 0.36, blue: 0.22), lineWidth: 2)
                )
        )
    }
}

struct EmptyInventorySlot: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .stroke(Color(red: 0.78, green: 0.36, blue: 0.22).opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [4]))
            .frame(width: 48, height: 48)
    }
}

#Preview {
    FarmHUDView(coordinator: GameCoordinator())
        .background(Color.green.opacity(0.3))
}
