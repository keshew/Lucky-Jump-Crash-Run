import Foundation
import SwiftUI

@MainActor
final class GameStore: ObservableObject {
    enum LaunchState {
        case loading, onboarding, ready
    }

    @Published var launchState: LaunchState = .loading
    @Published var save = PlayerSave()
    @Published var selectedRoute: AppRoute = .home
    @Published var selectedWorld: GameWorld = GameWorld.all[0]
    @Published var activeRun: RunConfiguration?
    @Published var pendingRun: RunConfiguration?
    @Published var lastResult: RunResult?
    @Published var showingSettings = false
    @Published var showingStatistics = false
    @Published var showingDailyReward = false
    @Published var levelPickerWorld: GameWorld?
    @Published var toast: String?

    private let saveURL: URL
    private var toastTask: Task<Void, Never>?

    init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let directory = base.appendingPathComponent("JumpCollectExplorer", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        saveURL = directory.appendingPathComponent("player-save.json")
        Task { await load() }
    }

    func load() async {
        let minimumDelay = Task {
            try? await Task.sleep(nanoseconds: 1_400_000_000)
        }

        if let data = try? Data(contentsOf: saveURL),
           let decoded = try? JSONDecoder().decode(PlayerSave.self, from: data) {
            save = decoded
        }
#if DEBUG
        let debugArguments = ProcessInfo.processInfo.arguments
        if debugArguments.contains("-debugSkipOnboarding") {
            save.onboardingCompleted = true
        }
#endif
        ensureDailyMissionCycle()

        await minimumDelay.value
        launchState = save.onboardingCompleted ? .ready : .onboarding
#if DEBUG
        if debugArguments.contains("-debugAutoPlay") {
            activeRun = RunConfiguration(world: GameWorld.all[0], level: 1, endless: false)
        }
#endif
    }

    func completeOnboarding() {
        save.onboardingCompleted = true
        persist()
        withAnimation(.easeInOut(duration: 0.35)) { launchState = .ready }
    }

    func startLevel(world: GameWorld? = nil, level: Int = 1, endless: Bool = false) {
        activeRun = RunConfiguration(world: world ?? selectedWorld, level: level, endless: endless)
        lastResult = nil
    }

    func prepareLevel(world: GameWorld? = nil, level: Int = 1, endless: Bool = false) {
        pendingRun = RunConfiguration(world: world ?? selectedWorld, level: level, endless: endless)
    }

    func prepareDailyChallenge() {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        let yearPart = (components.year ?? 0) * 10_000
        let monthPart = (components.month ?? 0) * 100
        let dayPart = components.day ?? 0
        let seed = UInt64(yearPart + monthPart + dayPart)
        let worldIndex = Int(seed % UInt64(GameWorld.all.count))
        pendingRun = RunConfiguration(world: GameWorld.all[worldIndex], level: 12, endless: false, dailyChallenge: true, seed: seed)
    }

    func startPreparedRun(_ configuration: RunConfiguration, boost: StartBoost) -> Bool {
        guard save.coins >= boost.price else {
            showToast("Not enough coins")
            return false
        }
        save.coins -= boost.price
        persist()
        var run = configuration
        run.boost = boost
        pendingRun = nil
        activeRun = run
        lastResult = nil
        return true
    }

    func finishRun(_ result: RunResult, configuration: RunConfiguration) {
        ensureDailyMissionCycle()
        save.gamesPlayed += 1
        save.totalJumps += max(1, result.height / 90)
        save.totalPerfects += result.perfects
        save.totalCoinsCollected += result.coins
        save.dailyPerfects = (save.dailyPerfects ?? 0) + result.perfects
        save.dailyRuns = (save.dailyRuns ?? 0) + 1
        save.dailyBestHeight = max(save.dailyBestHeight ?? 0, result.height)
        save.coins += result.coins
        save.rescueFeathers = availableRescueFeathers + result.rescueFeathersFound
        save.totalChestsOpened = (save.totalChestsOpened ?? 0) + result.chestsOpened
        save.bestHeight = max(save.bestHeight, result.height)
        save.bestScore = max(save.bestScore, result.score)
        save.experience += GameRules.experience(height: result.height, perfects: result.perfects)
        updatePlayerLevel()

        if result.completed && !configuration.endless && !configuration.dailyChallenge {
            let feathers = GameRules.earnedFeathers(result: result, configuration: configuration)
            save.completedLevels[configuration.identifier] = max(save.completedLevels[configuration.identifier] ?? 0, feathers)
        }

        lastResult = result
        persist()
    }

    func closeRun() {
        activeRun = nil
        lastResult = nil
    }

    var featherCount: Int { save.completedLevels.values.reduce(0, +) }

    func isWorldUnlocked(_ world: GameWorld) -> Bool {
        featherCount >= world.requiredFeathers
    }

    func isLevelUnlocked(_ level: Int, in world: GameWorld) -> Bool {
        guard isWorldUnlocked(world) else { return false }
        return level == 1 || save.completedLevels["\(world.id)-\(level - 1)"] != nil
    }

    func nextLevel(in world: GameWorld) -> Int {
        for level in 1...20 where save.completedLevels["\(world.id)-\(level)"] == nil {
            return level
        }
        return 20
    }

    var missions: [GameMission] {
        let stamp = Self.dayStamp
        let claimed = Set(save.claimedMissionIDs ?? [])
        return [
            .init(id: "\(stamp)-perfect", title: "Precision Flight", detail: "Make 15 perfect landings today", progress: min(save.dailyPerfects ?? 0, 15), target: 15, reward: 200, claimed: claimed.contains("\(stamp)-perfect")),
            .init(id: "\(stamp)-height", title: "Reach the Clouds", detail: "Climb 2,000 meters in one run", progress: min(save.dailyBestHeight ?? 0, 2_000), target: 2_000, reward: 300, claimed: claimed.contains("\(stamp)-height")),
            .init(id: "\(stamp)-runs", title: "Keep Exploring", detail: "Complete 5 runs today", progress: min(save.dailyRuns ?? 0, 5), target: 5, reward: 150, claimed: claimed.contains("\(stamp)-runs"))
        ]
    }

    var availableRescueFeathers: Int { save.rescueFeathers ?? 2 }

    var achievements: [GameAchievement] {
        let claimed = Set(save.claimedAchievementIDs ?? [])
        return [
            .init(id: "first-flight", title: "First Flight", detail: "Complete your first run", progress: min(save.gamesPlayed, 1), target: 1, reward: 100, claimed: claimed.contains("first-flight")),
            .init(id: "perfect-ten", title: "Perfect Ten", detail: "Make 10 perfect landings", progress: min(save.totalPerfects, 10), target: 10, reward: 250, claimed: claimed.contains("perfect-ten")),
            .init(id: "sky-high", title: "Sky High", detail: "Reach 1,000 meters", progress: min(save.bestHeight, 1_000), target: 1_000, reward: 400, claimed: claimed.contains("sky-high")),
            .init(id: "collector", title: "Treasure Hunter", detail: "Collect 5,000 coins", progress: min(save.totalCoinsCollected, 5_000), target: 5_000, reward: 600, claimed: claimed.contains("collector")),
            .init(id: "chests", title: "Chest Seeker", detail: "Open 20 treasure chests", progress: min(save.totalChestsOpened ?? 0, 20), target: 20, reward: 500, claimed: claimed.contains("chests")),
            .init(id: "veteran", title: "Seasoned Explorer", detail: "Complete 25 runs", progress: min(save.gamesPlayed, 25), target: 25, reward: 750, claimed: claimed.contains("veteran"))
        ]
    }

    func useRescueFeather() -> Bool {
        guard availableRescueFeathers > 0 else { return false }
        save.rescueFeathers = availableRescueFeathers - 1
        persist()
        return true
    }

    func claimMission(_ mission: GameMission) {
        guard mission.progress >= mission.target, !mission.claimed else { return }
        var claimed = save.claimedMissionIDs ?? []
        guard !claimed.contains(mission.id) else { return }
        claimed.append(mission.id)
        save.claimedMissionIDs = claimed
        save.coins += mission.reward
        persist()
        showToast("Mission complete: +\(mission.reward) coins")
    }

    func claimAchievement(_ achievement: GameAchievement) {
        guard achievement.progress >= achievement.target, !achievement.claimed else { return }
        var claimed = save.claimedAchievementIDs ?? []
        guard !claimed.contains(achievement.id) else { return }
        claimed.append(achievement.id)
        save.claimedAchievementIDs = claimed
        save.coins += achievement.reward
        persist()
        showToast("Achievement unlocked: +\(achievement.reward) coins")
    }

    func buy(_ character: GameCharacter) {
        guard !save.unlockedCharacterIDs.contains(character.id) else {
            select(character)
            return
        }
        guard save.coins >= character.price else {
            showToast("Not enough coins")
            return
        }
        save.coins -= character.price
        save.unlockedCharacterIDs.append(character.id)
        save.selectedCharacterID = character.id
        persist()
        showToast("\(character.name) unlocked!")
    }

    func select(_ character: GameCharacter) {
        guard save.unlockedCharacterIDs.contains(character.id) else { return }
        save.selectedCharacterID = character.id
        persist()
        showToast("\(character.name) selected")
    }

    func claimDailyReward() {
        guard !claimedDailyRewardToday else { return }
        let rewards = [100, 150, 200, 250, 300, 400, 500]
        let reward = rewards[save.dailyRewardDay % rewards.count]
        save.coins += reward
        save.dailyRewardDay = (save.dailyRewardDay + 1) % rewards.count
        save.dailyRewardClaimedDate = Date()
        persist()
        showToast("Daily reward: +\(reward) coins")
    }

    var claimedDailyRewardToday: Bool {
        guard let date = save.dailyRewardClaimedDate else { return false }
        return Calendar.current.isDateInToday(date)
    }

    func resetProgress() {
        save = PlayerSave(onboardingCompleted: true)
        selectedWorld = GameWorld.all[0]
        persist()
        showToast("Progress reset")
    }

    func persist() {
        guard let data = try? JSONEncoder().encode(save) else { return }
        try? data.write(to: saveURL, options: .atomic)
    }

    func showToast(_ message: String) {
        toastTask?.cancel()
        toast = message
        toastTask = Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            if !Task.isCancelled { toast = nil }
        }
    }

    private func updatePlayerLevel() {
        save.level = GameRules.playerLevel(experience: save.experience)
    }

    private func ensureDailyMissionCycle() {
        guard save.missionDayStamp != Self.dayStamp else { return }
        save.missionDayStamp = Self.dayStamp
        save.dailyPerfects = 0
        save.dailyRuns = 0
        save.dailyBestHeight = 0
        persist()
    }

    private static var dayStamp: String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd"
        return formatter.string(from: Date())
    }
}
