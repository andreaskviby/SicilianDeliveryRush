import SwiftUI

struct LoadingPhaseView: View {
    let phase: GamePhase.LoadingPhase
    @Bindable var coordinator: GameCoordinator

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(red: 0.96, green: 0.9, blue: 0.78)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    header
                        .padding(.top, geometry.safeAreaInsets.top + 16)

                    switch phase {
                    case .selectingVehicle:
                        VehicleSelectionView(coordinator: coordinator)

                    case .loadingCargo:
                        CargoLoadingView(coordinator: coordinator)

                    case .confirmingRoute:
                        RouteConfirmationView(coordinator: coordinator)
                    }

                    Spacer()
                }
            }
        }
    }

    private var header: some View {
        HStack {
            Button(action: {
                coordinator.transitionTo(.farm(.exploring))
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            Text(headerTitle)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Spacer()

            CargoCountBadge(count: coordinator.loadedCargo.count, max: coordinator.selectedVehicle.maxCargoSlots)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(red: 0.78, green: 0.36, blue: 0.22))
    }

    private var headerTitle: String {
        switch phase {
        case .selectingVehicle: return "SELECT VEHICLE"
        case .loadingCargo: return "LOAD CARGO"
        case .confirmingRoute: return "CONFIRM ROUTE"
        }
    }
}

struct CargoCountBadge: View {
    let count: Int
    let max: Int

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "shippingbox.fill")
                .font(.system(size: 14))

            Text("\(count)/\(max)")
                .font(.system(size: 14, weight: .bold))
        }
        .foregroundColor(Color(red: 0.78, green: 0.36, blue: 0.22))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.white)
        )
    }
}

struct VehicleSelectionView: View {
    @Bindable var coordinator: GameCoordinator

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                Text("Choose your ride")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
                    .padding(.top, 16)

                HStack(spacing: 16) {
                    VehicleCard(
                        type: .vespa,
                        isSelected: coordinator.selectedVehicle == .vespa,
                        onSelect: {
                            coordinator.selectVehicle(.vespa)
                        }
                    )

                    VehicleCard(
                        type: .apeLambretta,
                        isSelected: coordinator.selectedVehicle == .apeLambretta,
                        onSelect: {
                            coordinator.selectVehicle(.apeLambretta)
                        }
                    )
                }
                .padding(.horizontal, 16)

                Button(action: {
                    coordinator.proceedToCargoLoading()
                }) {
                    Text("CONTINUE")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(red: 0.78, green: 0.36, blue: 0.22))
                        )
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
        }
    }
}

struct VehicleCard: View {
    let type: VehicleType
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 12) {
                Image(systemName: type == .vespa ? "scooter" : "car.side.fill")
                    .font(.system(size: 50))
                    .foregroundColor(type == .vespa ?
                        Color(red: 0.2, green: 0.6, blue: 0.8) :
                        Color(red: 0.8, green: 0.5, blue: 0.2))

                Text(type.displayName)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.17, green: 0.17, blue: 0.17))

                VStack(spacing: 4) {
                    HStack {
                        Text("Speed:")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        Spacer()
                        ForEach(0..<(type == .vespa ? 5 : 3), id: \.self) { _ in
                            Circle()
                                .fill(Color.orange)
                                .frame(width: 8, height: 8)
                        }
                    }

                    HStack {
                        Text("Stability:")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        Spacer()
                        ForEach(0..<(type == .vespa ? 2 : 5), id: \.self) { _ in
                            Circle()
                                .fill(Color.green)
                                .frame(width: 8, height: 8)
                        }
                    }

                    HStack {
                        Text("Cargo:")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        Spacer()
                        Text("\(type.maxCargoSlots) items")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(red: 0.17, green: 0.17, blue: 0.17))
                    }
                }
                .padding(.horizontal, 8)

                Text(type.description)
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Color(red: 0.42, green: 0.48, blue: 0.24) : Color.clear, lineWidth: 4)
                    )
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct CargoLoadingView: View {
    @Bindable var coordinator: GameCoordinator

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                VehicleCargoArea(
                    vehicleType: coordinator.selectedVehicle,
                    loadedCargo: coordinator.loadedCargo
                )
                .frame(height: 180)
                .padding(.horizontal, 16)
                .padding(.top, 12)

                BalanceIndicator(cargo: coordinator.loadedCargo)
                    .padding(.horizontal, 16)

                Text("Tap items below to load")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)

                AvailableCargoGrid(
                    items: coordinator.harvestedItems,
                    onItemTap: { item in
                        coordinator.loadCargoItem(item)
                    }
                )
                .padding(.horizontal, 16)

                Button(action: {
                    coordinator.confirmRouteAndStartDriving()
                }) {
                    Text("START DELIVERY")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(coordinator.loadedCargo.isEmpty ?
                                      Color.gray : Color(red: 0.78, green: 0.36, blue: 0.22))
                        )
                }
                .disabled(coordinator.loadedCargo.isEmpty)
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
        }
    }
}

struct VehicleCargoArea: View {
    let vehicleType: VehicleType
    let loadedCargo: [CargoItem]

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.96, green: 0.9, blue: 0.78))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(red: 0.55, green: 0.24, blue: 0.16), lineWidth: 2)
                )

            HStack(spacing: 20) {
                Image(systemName: vehicleType == .vespa ? "scooter" : "car.side.fill")
                    .font(.system(size: 60))
                    .foregroundColor(vehicleType == .vespa ?
                        Color(red: 0.2, green: 0.6, blue: 0.8) :
                        Color(red: 0.8, green: 0.5, blue: 0.2))

                VStack(alignment: .leading, spacing: 8) {
                    Text("Loaded Cargo")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)

                    LazyVGrid(columns: Array(repeating: GridItem(.fixed(40), spacing: 4), count: 4), spacing: 4) {
                        ForEach(loadedCargo) { item in
                            Image(systemName: item.type.iconName)
                                .font(.system(size: 18))
                                .foregroundColor(Color(item.type.color))
                                .frame(width: 36, height: 36)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.white)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(Color.green, lineWidth: 2)
                                        )
                                )
                        }

                        ForEach(0..<max(0, vehicleType.maxCargoSlots - loadedCargo.count), id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [4]))
                                .frame(width: 36, height: 36)
                        }
                    }
                }
            }
            .padding(20)
        }
    }
}

struct BalanceIndicator: View {
    let cargo: [CargoItem]

    private var balance: Float {
        guard !cargo.isEmpty else { return 0.5 }
        let totalWeight = cargo.reduce(0) { $0 + $1.weight }
        let avgWeight = totalWeight / Float(cargo.count)
        return 0.5 + (avgWeight - 3.0) * 0.05
    }

    var body: some View {
        VStack(spacing: 4) {
            Text("BALANCE")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.gray)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.black.opacity(0.1))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(balanceColor)
                        .frame(width: geometry.size.width * CGFloat(balance.clamped(to: 0...1)))

                    Rectangle()
                        .fill(Color.white)
                        .frame(width: 2)
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                }
            }
            .frame(height: 20)
        }
    }

    private var balanceColor: Color {
        let diff = abs(balance - 0.5)
        if diff < 0.1 {
            return Color.green
        } else if diff < 0.2 {
            return Color.yellow
        } else {
            return Color.red
        }
    }
}

struct AvailableCargoGrid: View {
    let items: [CargoItem]
    let onItemTap: (CargoItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("AVAILABLE ITEMS")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.gray)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5), spacing: 8) {
                ForEach(items) { item in
                    Button(action: { onItemTap(item) }) {
                        VStack(spacing: 2) {
                            Image(systemName: item.type.iconName)
                                .font(.system(size: 22))
                                .foregroundColor(Color(item.type.color))

                            Text("\(item.type.pointValue)")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.gray)
                        }
                        .frame(width: 50, height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.5))
        )
    }
}

struct RouteConfirmationView: View {
    @Bindable var coordinator: GameCoordinator

    var body: some View {
        VStack(spacing: 20) {
            if let delivery = coordinator.currentDelivery {
                VStack(spacing: 8) {
                    Text("Delivering to")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)

                    Text(delivery.destinationName)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.17, green: 0.17, blue: 0.17))

                    Text(delivery.destinationDescription)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                .padding(.top, 24)

                HStack(spacing: 30) {
                    VStack {
                        Text("\(Int(delivery.timeLimit))")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(Color(red: 0.18, green: 0.42, blue: 0.54))
                        Text("seconds")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }

                    VStack {
                        Text("\(coordinator.loadedCargo.count)")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(Color(red: 0.42, green: 0.48, blue: 0.24))
                        Text("items")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }

                    VStack {
                        Text(delivery.difficulty.displayName)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(difficultyColor(delivery.difficulty))
                        Text("difficulty")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.vertical, 20)
            }

            Spacer()

            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 0.78, green: 0.36, blue: 0.22)))
                .scaleEffect(1.5)

            Text("Preparing route...")
                .font(.system(size: 16))
                .foregroundColor(.gray)

            Spacer()
        }
    }

    private func difficultyColor(_ difficulty: DeliveryOrder.Difficulty) -> Color {
        switch difficulty {
        case .easy: return Color.green
        case .medium: return Color.orange
        case .hard: return Color.red
        }
    }
}

#Preview {
    LoadingPhaseView(phase: .selectingVehicle, coordinator: GameCoordinator())
}
