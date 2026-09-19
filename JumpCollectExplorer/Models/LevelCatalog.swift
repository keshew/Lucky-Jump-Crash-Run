import Foundation

struct LevelDefinition: Equatable {
    let worldID: String
    let level: Int
    let title: String
    let targetHeight: Int
    let perfectTarget: Int
    let coinTarget: Int
    let minimumGap: Double
    let maximumGap: Double
    let hazardInterval: ClosedRange<Double>
    let difficulty: Double
    let checkpointHeight: Int?
}

enum LevelCatalog {
    static func definition(world: GameWorld, level: Int) -> LevelDefinition {
        let safeLevel = min(20, max(1, level))
        let worldIndex = GameWorld.all.firstIndex(where: { $0.id == world.id }) ?? 0
        let difficulty = min(1, Double((safeLevel - 1) + worldIndex * 5) / 30.0)
        let target = 1_350 + safeLevel * 95 + worldIndex * 180
        let titles = titleSet(for: world.id)

        return LevelDefinition(
            worldID: world.id,
            level: safeLevel,
            title: titles[(safeLevel - 1) % titles.count],
            targetHeight: target,
            perfectTarget: 4 + safeLevel / 4,
            coinTarget: 28 + safeLevel * 3,
            minimumGap: 96 + difficulty * 8,
            maximumGap: 118 + difficulty * 34,
            hazardInterval: (max(300, 620 - difficulty * 170))...(max(430, 790 - difficulty * 150)),
            difficulty: difficulty,
            checkpointHeight: safeLevel >= 8 ? target / 2 : nil
        )
    }

    static var allCampaignLevels: [LevelDefinition] {
        GameWorld.all.flatMap { world in
            (1...20).map { definition(world: world, level: $0) }
        }
    }

    private static func titleSet(for worldID: String) -> [String] {
        switch worldID {
        case "ice": return ["First Frost", "Cold Current", "Crystal Steps", "White Wind", "Frozen Route"]
        case "fire": return ["Hot Landing", "Ash Trail", "Burning Sky", "Lava Leap", "Volcanic Rise"]
        case "night": return ["Moonlit Path", "Hidden Glow", "Storm Signs", "Vanishing Trail", "Midnight Crown"]
        default: return ["First Feathers", "Cloud Path", "Floating Garden", "High Route", "Castle in the Sky"]
        }
    }
}

enum GameRules {
    static func earnedFeathers(result: RunResult, configuration: RunConfiguration) -> Int {
        guard result.completed, !configuration.endless, !configuration.dailyChallenge else { return 0 }
        let definition = LevelCatalog.definition(world: configuration.world, level: configuration.level)
        return min(3, 1 + (result.perfects >= definition.perfectTarget ? 1 : 0) + (result.coins >= definition.coinTarget ? 1 : 0))
    }

    static func experience(height: Int, perfects: Int) -> Int {
        max(10, height / 10 + perfects * 5)
    }

    static func playerLevel(experience: Int) -> Int {
        max(1, min(50, experience / 1_000 + 1))
    }
}

struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0x9E3779B97F4A7C15 : seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var value = state
        value = (value ^ (value >> 30)) &* 0xBF58476D1CE4E5B9
        value = (value ^ (value >> 27)) &* 0x94D049BB133111EB
        return value ^ (value >> 31)
    }
}

