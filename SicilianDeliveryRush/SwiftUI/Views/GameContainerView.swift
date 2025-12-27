import SwiftUI
import SceneKit

struct GameContainerView: View {
    @Bindable var coordinator: GameCoordinator

    var body: some View {
        ZStack {
            if let scene = coordinator.activeScene {
                SceneKitContainer(scene: scene, coordinator: coordinator)
                    .ignoresSafeArea()
            }

            overlayForPhase(coordinator.currentPhase)
        }
        .statusBarHidden()
    }

    @ViewBuilder
    private func overlayForPhase(_ phase: GamePhase) -> some View {
        switch phase {
        case .mainMenu:
            MainMenuView(coordinator: coordinator)

        case .farm:
            FarmHUDView(coordinator: coordinator)

        case .loading(let loadingPhase):
            LoadingPhaseView(phase: loadingPhase, coordinator: coordinator)

        case .driving(let drivingPhase):
            DrivingHUDView(
                phase: drivingPhase,
                coordinator: coordinator,
                scene: coordinator.activeScene as? DrivingScene
            )

        case .delivery:
            EmptyView()

        case .paused:
            PauseMenuView(coordinator: coordinator)

        case .gameOver(let result):
            DeliveryCompleteView(result: result, coordinator: coordinator)
        }
    }
}

struct SceneKitContainer: UIViewRepresentable {
    let scene: SCNScene
    let coordinator: GameCoordinator

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.scene = scene
        scnView.allowsCameraControl = false
        scnView.showsStatistics = false
        scnView.backgroundColor = .black
        scnView.antialiasingMode = .multisampling4X
        scnView.preferredFramesPerSecond = 60
        scnView.autoenablesDefaultLighting = false

        // Set the camera from the scene's camera controller
        if let gameScene = scene as? BaseGameScene,
           let cameraNode = gameScene.cameraController?.cameraNode {
            scnView.pointOfView = cameraNode
        }

        scnView.delegate = context.coordinator
        scnView.isPlaying = true

        return scnView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        if uiView.scene !== scene {
            uiView.scene = scene

            // Update the camera point of view when scene changes
            if let gameScene = scene as? BaseGameScene,
               let cameraNode = gameScene.cameraController?.cameraNode {
                uiView.pointOfView = cameraNode
            }
        }
    }

    func makeCoordinator() -> SceneCoordinator {
        SceneCoordinator(gameCoordinator: coordinator)
    }

    class SceneCoordinator: NSObject, SCNSceneRendererDelegate {
        let gameCoordinator: GameCoordinator
        private var lastUpdateTime: TimeInterval = 0

        init(gameCoordinator: GameCoordinator) {
            self.gameCoordinator = gameCoordinator
        }

        func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
            let deltaTime = lastUpdateTime == 0 ? 0 : time - lastUpdateTime
            lastUpdateTime = time

            guard let scene = gameCoordinator.activeScene else { return }
            scene.update(deltaTime: deltaTime)
        }
    }
}

#Preview {
    GameContainerView(coordinator: GameCoordinator())
}
