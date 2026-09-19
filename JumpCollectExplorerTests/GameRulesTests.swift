import XCTest
@testable import JumpCollectExplorer

final class GameRulesTests: XCTestCase {
    func testCampaignContainsEightyValidDefinitions() {
        let levels = LevelCatalog.allCampaignLevels
        XCTAssertEqual(levels.count, 80)
        XCTAssertTrue(levels.allSatisfy { $0.targetHeight > 1_000 })
        XCTAssertTrue(levels.allSatisfy { $0.minimumGap < $0.maximumGap })
        XCTAssertTrue(levels.allSatisfy { $0.perfectTarget > 0 && $0.coinTarget > 0 })
    }

    func testTargetHeightIncreasesInsideEveryWorld() {
        for world in GameWorld.all {
            let heights = (1...20).map { LevelCatalog.definition(world: world, level: $0).targetHeight }
            XCTAssertEqual(heights, heights.sorted())
            XCTAssertEqual(Set(heights).count, 20)
        }
    }

    func testFeathersUseLevelSpecificObjectives() {
        let world = GameWorld.all[0]
        let configuration = RunConfiguration(world: world, level: 10, endless: false)
        let definition = LevelCatalog.definition(world: world, level: 10)
        let complete = RunResult(
            completed: true,
            score: 10_000,
            height: definition.targetHeight,
            coins: definition.coinTarget,
            perfects: definition.perfectTarget,
            maxCombo: 3,
            reason: "test"
        )
        XCTAssertEqual(GameRules.earnedFeathers(result: complete, configuration: configuration), 3)

        let basic = RunResult(completed: true, score: 100, height: definition.targetHeight, coins: 0, perfects: 0, maxCombo: 1, reason: "test")
        XCTAssertEqual(GameRules.earnedFeathers(result: basic, configuration: configuration), 1)
    }

    func testNonCampaignRunsDoNotAwardFeathers() {
        let world = GameWorld.all[0]
        let result = RunResult(completed: true, score: 1, height: 3_000, coins: 500, perfects: 50, maxCombo: 5, reason: "test")
        XCTAssertEqual(GameRules.earnedFeathers(result: result, configuration: RunConfiguration(world: world, level: 1, endless: true)), 0)
        XCTAssertEqual(GameRules.earnedFeathers(result: result, configuration: RunConfiguration(world: world, level: 1, endless: false, dailyChallenge: true)), 0)
    }

    func testSeededGeneratorIsReproducible() {
        var first = SeededGenerator(seed: 42)
        var second = SeededGenerator(seed: 42)
        let firstValues = (0..<100).map { _ in first.next() }
        let secondValues = (0..<100).map { _ in second.next() }
        XCTAssertEqual(firstValues, secondValues)
    }

    func testPlayerLevelIsClamped() {
        XCTAssertEqual(GameRules.playerLevel(experience: 0), 1)
        XCTAssertEqual(GameRules.playerLevel(experience: 10_000), 11)
        XCTAssertEqual(GameRules.playerLevel(experience: 1_000_000), 50)
    }
}

