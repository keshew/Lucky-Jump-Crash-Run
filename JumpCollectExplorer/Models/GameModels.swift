import Foundation
import SwiftUI

enum AppRoute: String, CaseIterable, Identifiable {
    case home, worlds, missions, collection, shop
    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: return "Home"
        case .worlds: return "Worlds"
        case .missions: return "Missions"
        case .collection: return "Collection"
        case .shop: return "Shop"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .worlds: return "map.fill"
        case .missions: return "checklist"
        case .collection: return "person.3.fill"
        case .shop: return "cart.fill"
        }
    }
}

struct PlayerSave: Codable {
    var onboardingCompleted = false
    var gameplayTutorialCompleted = false
    var coins = 500
    var experience = 0
    var level = 1
    var selectedCharacterID = "tommy"
    var unlockedCharacterIDs = ["tommy"]
    var completedLevels: [String: Int] = [:]
    var bestHeight: Int = 0
    var bestScore: Int = 0
    var totalJumps: Int = 0
    var totalPerfects: Int = 0
    var totalCoinsCollected: Int = 0
    var gamesPlayed: Int = 0
    var dailyRewardDay: Int = 0
    var dailyRewardClaimedDate: Date?
    var musicEnabled = true
    var soundEnabled = true
    var hapticsEnabled = true
    var reducedEffects = false
    var cameraShake = true
    var controlSensitivity = 1.0
    var claimedMissionIDs: [String]?
    var rescueFeathers: Int?
    var missionDayStamp: String?
    var dailyPerfects: Int?
    var dailyRuns: Int?
    var dailyBestHeight: Int?
    var claimedAchievementIDs: [String]?
    var totalChestsOpened: Int?
}

enum StartBoost: String, CaseIterable, Identifiable, Codable {
    case none, shield, wings, goldenEgg
    var id: String { rawValue }

    var title: String {
        switch self {
        case .none: return "No Boost"
        case .shield: return "Shield"
        case .wings: return "Wings"
        case .goldenEgg: return "Double Coins"
        }
    }

    var detail: String {
        switch self {
        case .none: return "Start without a bonus"
        case .shield: return "Blocks one hazard hit"
        case .wings: return "Slower falling for 12 seconds"
        case .goldenEgg: return "Double coins for 15 seconds"
        }
    }

    var symbol: String {
        switch self {
        case .none: return "nosign"
        case .shield: return "shield.fill"
        case .wings: return "wind"
        case .goldenEgg: return "dollarsign.circle.fill"
        }
    }

    var price: Int {
        switch self {
        case .none: return 0
        case .shield: return 100
        case .wings: return 150
        case .goldenEgg: return 200
        }
    }
}

struct GameWorld: Identifiable, Hashable {
    let id: String
    let name: String
    let subtitle: String
    let symbol: String
    let color: Color
    let requiredFeathers: Int
    let mechanic: String

    static let all: [GameWorld] = [
        .init(id: "sky", name: "Sky Gardens", subtitle: "Floating islands above the clouds", symbol: "cloud.sun.fill", color: .cyan, requiredFeathers: 0, mechanic: "Moving and rotten islands"),
        .init(id: "ice", name: "Frozen Peaks", subtitle: "Slippery paths and cold winds", symbol: "snowflake", color: .blue, requiredFeathers: 30, mechanic: "Ice and wind gusts"),
        .init(id: "fire", name: "Fire Archipelago", subtitle: "Fragile ground over hot lava", symbol: "flame.fill", color: .orange, requiredFeathers: 70, mechanic: "Breaking islands and fire birds"),
        .init(id: "night", name: "Enchanted Night Forest", subtitle: "A mysterious world in the moonlight", symbol: "moon.stars.fill", color: .purple, requiredFeathers: 120, mechanic: "Vanishing islands and storms")
    ]
}

struct GameCharacter: Identifiable, Hashable {
    let id: String
    let name: String
    let symbol: String
    let color: Color
    let price: Int
    let requirement: String

    static let all: [GameCharacter] = [
        .init(id: "tommy", name: "Tommy", symbol: "bird.fill", color: .red, price: 0, requirement: "Your first explorer"),
        .init(id: "pirate", name: "Pirate", symbol: "flag.fill", color: .brown, price: 2_000, requirement: "Buy for 2,000 coins"),
        .init(id: "explorer", name: "Explorer", symbol: "safari.fill", color: .green, price: 3_000, requirement: "Buy for 3,000 coins"),
        .init(id: "snow", name: "Snow Turkey", symbol: "snowflake", color: .cyan, price: 4_000, requirement: "Buy for 4,000 coins"),
        .init(id: "fire", name: "Fire Turkey", symbol: "flame.fill", color: .orange, price: 5_000, requirement: "Buy for 5,000 coins"),
        .init(id: "wizard", name: "Night Wizard", symbol: "wand.and.stars", color: .purple, price: 6_000, requirement: "Buy for 6,000 coins"),
        .init(id: "robot", name: "Robo Turkey", symbol: "gearshape.2.fill", color: .gray, price: 7_000, requirement: "Buy for 7,000 coins"),
        .init(id: "gold", name: "Golden Turkey", symbol: "crown.fill", color: .yellow, price: 10_000, requirement: "Buy for 10,000 coins")
    ]
}

struct GameMission: Identifiable {
    let id: String
    let title: String
    let detail: String
    let progress: Int
    let target: Int
    let reward: Int
    let claimed: Bool
}

struct GameAchievement: Identifiable {
    let id: String
    let title: String
    let detail: String
    let progress: Int
    let target: Int
    let reward: Int
    let claimed: Bool
}

struct RunConfiguration: Equatable, Identifiable {
    var world: GameWorld
    var level: Int
    var endless: Bool
    var boost: StartBoost = .none
    var dailyChallenge = false
    var seed: UInt64?

    var targetHeight: Int {
        if endless { return Int.max }
        if dailyChallenge { return 2_200 }
        return LevelCatalog.definition(world: world, level: level).targetHeight
    }
    var identifier: String { "\(world.id)-\(level)" }
    var id: String { dailyChallenge ? "daily-\(seed ?? 0)" : (endless ? "\(world.id)-endless" : identifier) }
}

struct RunResult: Identifiable, Equatable {
    let id = UUID()
    let completed: Bool
    let score: Int
    let height: Int
    let coins: Int
    let perfects: Int
    let maxCombo: Int
    let reason: String
    var rescueFeathersFound: Int = 0
    var chestsOpened: Int = 0
}
