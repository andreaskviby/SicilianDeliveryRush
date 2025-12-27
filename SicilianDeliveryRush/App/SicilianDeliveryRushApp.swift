import SwiftUI

@main
struct SicilianDeliveryRushApp: App {
    @State private var coordinator = GameCoordinator()

    var body: some Scene {
        WindowGroup {
            GameContainerView(coordinator: coordinator)
                .preferredColorScheme(.light)
        }
    }
}
