import SwiftUI
import SceneKit
import Combine

@Observable
final class GameCoordinator {

    var currentPhase: GamePhase = .mainMenu
    var currentLevel: Int = 1
    var playerProgress: PlayerProgress

    private(set) var activeScene: BaseGameScene?
    private var sceneCache: [String: BaseGameScene] = [:]

    let audioManager: AudioManager
    let inputManager: InputManager
    let dataManager: GameDataManager

    var currentDelivery: DeliveryOrder?
    var selectedVehicle: VehicleType = .vespa
    var loadedCargo: [CargoItem] = []
    var harvestedItems: [CargoItem] = []

    var currentScore: Int = 0
    var timeBonus: Int = 0
    var cargoBonus: Int = 0

    private var cancellables = Set<AnyCancellable>()

    init() {
        self.playerProgress = PlayerProgress()
        self.audioManager = AudioManager()
        self.inputManager = InputManager()
        self.dataManager = GameDataManager()

        loadPlayerProgress()
    }

    func transitionTo(_ phase: GamePhase) {
        let previousPhase = currentPhase

        exitPhase(previousPhase)

        currentPhase = phase
        enterPhase(phase)

        audioManager.handlePhaseTransition(from: previousPhase, to: phase)
    }

    private func exitPhase(_ phase: GamePhase) {
        switch phase {
        case .driving:
            break
        case .farm:
            break
        default:
            break
        }
    }

    private func enterPhase(_ phase: GamePhase) {
        switch phase {
        case .mainMenu:
            unloadAllScenes()

        case .farm:
            loadScene(FarmScene.self, identifier: "farm")

        case .loading:
            break

        case .driving:
            loadScene(DrivingScene.self, identifier: "driving_\(currentLevel)")

        case .delivery:
            break

        case .paused:
            activeScene?.isPaused = true

        case .gameOver(let result):
            processDeliveryResult(result)
        }
    }

    private func loadScene<T: BaseGameScene>(_ sceneType: T.Type, identifier: String) {
        if let cached = sceneCache[identifier] as? T {
            activeScene = cached
            activeScene?.isPaused = false
        } else {
            let scene = T(coordinator: self)
            sceneCache[identifier] = scene
            activeScene = scene
        }
        activeScene?.prepareScene()
    }

    private func unloadAllScenes() {
        sceneCache.removeAll()
        activeScene = nil
    }

    func startNewGame() {
        currentLevel = 1
        currentScore = 0
        harvestedItems = []
        loadedCargo = []
        transitionTo(.farm(.exploring))
    }

    func startNewDelivery(order: DeliveryOrder) {
        currentDelivery = order
        loadedCargo = []
        currentScore = 0
        transitionTo(.loading(.selectingVehicle))
    }

    func selectVehicle(_ type: VehicleType) {
        selectedVehicle = type
    }

    func proceedToCargoLoading() {
        transitionTo(.loading(.loadingCargo))
    }

    func loadCargoItem(_ item: CargoItem) {
        let maxSlots = selectedVehicle == .vespa ?
            GameConfiguration.Gameplay.maxCargoVespa :
            GameConfiguration.Gameplay.maxCargoApe

        if loadedCargo.count < maxSlots {
            loadedCargo.append(item)
            if let index = harvestedItems.firstIndex(where: { $0.id == item.id }) {
                harvestedItems.remove(at: index)
            }
        }
    }

    func unloadCargoItem(_ item: CargoItem) {
        if let index = loadedCargo.firstIndex(where: { $0.id == item.id }) {
            loadedCargo.remove(at: index)
            harvestedItems.append(item)
        }
    }

    func confirmRouteAndStartDriving() {
        transitionTo(.loading(.confirmingRoute))

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.transitionTo(.driving(.countdown))
        }
    }

    func startRacing() {
        transitionTo(.driving(.racing))
    }

    func cargoItemLost(_ item: CargoItem) {
        if let index = loadedCargo.firstIndex(where: { $0.id == item.id }) {
            loadedCargo[index].isLost = true
        }
        audioManager.play(.cargoFall)
    }

    func completeDelivery(timeElapsed: TimeInterval) {
        let delivered = loadedCargo.filter { !$0.isLost }
        let lost = loadedCargo.filter { $0.isLost }

        let result = calculateScore(
            delivered: delivered,
            lost: lost,
            time: timeElapsed
        )

        transitionTo(.gameOver(result: result))
    }

    private func calculateScore(
        delivered: [CargoItem],
        lost: [CargoItem],
        time: TimeInterval
    ) -> DeliveryResult {
        let basePoints = delivered.reduce(0) { $0 + $1.pointValue }
        let timeBonus = GameConfiguration.Scoring.calculateTimeBonus(
            elapsed: time,
            target: GameConfiguration.Gameplay.baseDeliveryTime
        )
        let perfectBonus = lost.isEmpty ? GameConfiguration.Gameplay.perfectDeliveryBonus : 0

        let total = basePoints + timeBonus + perfectBonus
        let stars = GameConfiguration.Scoring.calculateStars(for: total)

        return DeliveryResult(
            timeElapsed: time,
            cargoDelivered: delivered.count,
            cargoLost: lost.count,
            bonusPoints: timeBonus + perfectBonus,
            totalScore: total,
            starRating: stars
        )
    }

    func harvestCrop(_ crop: CropType) {
        for _ in 0..<crop.harvestAmount {
            let cargoType = CargoType.from(crop: crop)
            let item = CargoItem(type: cargoType)
            harvestedItems.append(item)
        }
        audioManager.play(.harvest)
    }

    private func loadPlayerProgress() {
        playerProgress = dataManager.loadProgress() ?? PlayerProgress()
    }

    private func processDeliveryResult(_ result: DeliveryResult) {
        playerProgress.totalScore += result.totalScore
        playerProgress.completedDeliveries += 1

        if result.starRating == 3 {
            playerProgress.perfectDeliveries += 1
        }

        if result.totalScore > playerProgress.highScore {
            playerProgress.highScore = result.totalScore
        }

        dataManager.saveProgress(playerProgress)
    }

    func resumeFromPause() {
        if case .paused(let previousPhase) = currentPhase {
            activeScene?.isPaused = false
            currentPhase = previousPhase
        }
    }

    func restartLevel() {
        loadedCargo = []
        currentScore = 0
        if let delivery = currentDelivery {
            startNewDelivery(order: delivery)
        }
    }

    func returnToMainMenu() {
        transitionTo(.mainMenu)
    }

    func nextLevel() {
        currentLevel += 1
        startNewGame()
    }
}
