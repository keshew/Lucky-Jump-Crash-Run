import SpriteKit

private enum GameSound: String {
    case land = "sfx_land.wav"
    case perfect = "sfx_perfect.wav"
    case spring = "sfx_spring.wav"
    case rotten = "sfx_rotten.wav"
    case hazard = "sfx_hazard.wav"
    case hit = "sfx_hit.wav"
    case shield = "sfx_shield.wav"
    case powerup = "sfx_powerup.wav"
    case chest = "sfx_chest.wav"
    case coin = "sfx_coin.wav"
    case checkpoint = "sfx_checkpoint.wav"
    case levelComplete = "sfx_level_complete.wav"
    case gameOver = "sfx_game_over.wav"
    case revive = "sfx_revive.wav"
}

struct GameHUDSnapshot: Equatable {
    var score = 0
    var height = 0
    var coins = 0
    var combo = 1
    var powerups = ""
    var worldEffect = ""
}

final class GameScene: SKScene {
    enum PlatformKind: String {
        case normal, small, moving, rotten, fragile, spring, ice, sticky, vanishing, finish
    }

    enum PowerupKind: String, CaseIterable {
        case shield, magnet, wings, goldenEgg, rocket, rescueFeather

        var title: String {
            switch self {
            case .shield: return "SHIELD"
            case .magnet: return "COIN MAGNET"
            case .wings: return "WINGS"
            case .goldenEgg: return "DOUBLE COINS"
            case .rocket: return "ROCKET BOOST"
            case .rescueFeather: return "RESCUE FEATHER"
            }
        }
    }

    private let configuration: RunConfiguration
    private let tutorialEnabled: Bool
    private let levelDefinition: LevelDefinition
    private var randomGenerator: SeededGenerator
    private let worldNode = SKNode()
    private let character = SKNode()
    private let scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
    private let heightLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
    private let coinLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
    private let comboLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
    private let powerupLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
    private let worldEffectLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
    private var velocity = CGVector(dx: 0, dy: 0)
    private var horizontalInput: CGFloat = 0
    private var previousTime: TimeInterval = 0
    private var highestPlatformY: CGFloat = 90
    private var lastPlatformX: CGFloat = 0
    private var traveledHeight: CGFloat = 0
    private var score = 0
    private var coins = 0
    private var perfects = 0
    private var perfectStreak = 0
    private var maxCombo = 1
    private var finished = false
    private var tutorialStep = 0
    private var tutorialLabel: SKLabelNode?
    private var generatedPlatformCount = 0
    private var nextHazardHeight: CGFloat = 520
    private var shieldActive = false
    private var magnetUntil: TimeInterval = 0
    private var wingsUntil: TimeInterval = 0
    private var goldenUntil: TimeInterval = 0
    private var sceneTime: TimeInterval = 0
    private var emergencyPlatform: SKNode?
    private var startingBoostApplied = false
    private let musicPlayer = ProceduralMusicPlayer()
    private var windUntil: TimeInterval = 0
    private var windDirection: CGFloat = 0
    private var invulnerableUntil: TimeInterval = 0
    private var rescueFeathersFound = 0
    private var chestsOpened = 0
    private var checkpointReached = false
    private var finishCreated = false
    private var lastHUDSnapshot = GameHUDSnapshot()

    var controlSensitivity = 1.0
    var reducedEffects = false
    var hapticsEnabled = true
    var soundEnabled = true
    var musicEnabled = true {
        didSet { updateMusic() }
    }
    var cameraShakeEnabled = true
    var onFinished: ((RunResult) -> Void)?
    var onHUDChanged: ((GameHUDSnapshot) -> Void)?

    init(configuration: RunConfiguration, showTutorial: Bool) {
        self.configuration = configuration
        levelDefinition = LevelCatalog.definition(world: configuration.world, level: configuration.level)
        let worldSeed: UInt64
        switch configuration.world.id {
        case "ice": worldSeed = 20_000
        case "fire": worldSeed = 30_000
        case "night": worldSeed = 40_000
        default: worldSeed = 10_000
        }
        let fallbackSeed = configuration.endless ? UInt64(Date().timeIntervalSince1970 * 1_000) : worldSeed + UInt64(configuration.level)
        randomGenerator = SeededGenerator(seed: configuration.seed ?? fallbackSeed)
        tutorialEnabled = showTutorial && configuration.world.id == "sky" && configuration.level == 1 && !configuration.endless
        super.init(size: UIScreen.main.bounds.size)
        scaleMode = .resizeFill
        switch configuration.world.id {
        case "ice": backgroundColor = UIColor(red: 0.23, green: 0.46, blue: 0.72, alpha: 1)
        case "fire": backgroundColor = UIColor(red: 0.27, green: 0.08, blue: 0.09, alpha: 1)
        case "night": backgroundColor = UIColor(red: 0.08, green: 0.06, blue: 0.25, alpha: 1)
        default: backgroundColor = UIColor(red: 0.20, green: 0.66, blue: 0.93, alpha: 1)
        }
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func didMove(to view: SKView) {
        anchorPoint = .zero
        view.isMultipleTouchEnabled = false
        setupBackground()
        addChild(worldNode)
        setupCharacter()
        setupHUD()
        updateMusic()
        createPlatform(x: size.width / 2, y: 105, width: 190, kind: .normal)
        character.position = CGPoint(x: size.width / 2, y: 168)
        velocity.dy = 650
        generatePlatforms()
        if tutorialEnabled { showTutorial("HOLD LEFT OR RIGHT TO STEER") }
    }

    private func setupBackground() {
        let backgroundName: String
        switch configuration.world.id {
        case "ice": backgroundName = "background_frozen_peaks"
        case "fire": backgroundName = "background_fire_archipelago"
        case "night": backgroundName = "background_night_forest"
        default: backgroundName = "background_sky_gardens"
        }
        let texture = SKTexture(imageNamed: backgroundName)
        let backdrop = SKSpriteNode(texture: texture)
        backdrop.position = CGPoint(x: size.width / 2, y: size.height / 2)
        backdrop.size = size
        backdrop.zPosition = -30
        addChild(backdrop)

        for index in 0..<7 {
            let cloud = SKShapeNode(ellipseOf: CGSize(width: 70 + index % 3 * 24, height: 28 + index % 2 * 9))
            cloud.fillColor = .white.withAlphaComponent(0.18)
            cloud.strokeColor = .clear
            cloud.position = CGPoint(x: CGFloat((index * 83) % max(1, Int(size.width))), y: 110 + CGFloat(index) * 105)
            cloud.zPosition = -10
            addChild(cloud)
        }
    }

    private func gradientTexture() -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 4, height: 900))
        let image = renderer.image { context in
            let colors: [UIColor]
            switch configuration.world.id {
            case "ice": colors = [UIColor(red: 0.16, green: 0.36, blue: 0.60, alpha: 1), UIColor(red: 0.55, green: 0.83, blue: 0.94, alpha: 1)]
            case "fire": colors = [UIColor(red: 0.16, green: 0.035, blue: 0.08, alpha: 1), UIColor(red: 0.68, green: 0.18, blue: 0.08, alpha: 1)]
            case "night": colors = [UIColor(red: 0.035, green: 0.025, blue: 0.16, alpha: 1), UIColor(red: 0.20, green: 0.10, blue: 0.42, alpha: 1)]
            default: colors = [UIColor(red: 0.12, green: 0.44, blue: 0.76, alpha: 1), UIColor(red: 0.39, green: 0.78, blue: 0.94, alpha: 1)]
            }
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let gradient = CGGradient(colorsSpace: colorSpace, colors: colors.map(\.cgColor) as CFArray, locations: [0, 1])!
            context.cgContext.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 0, y: 900), options: [])
        }
        return SKTexture(image: image)
    }

    private func setupCharacter() {
        character.name = "character"
        character.zPosition = 20
        let sprite = SKSpriteNode(imageNamed: "character_turkey_default")
        sprite.name = "characterArtwork"
        sprite.size = CGSize(width: 86, height: 86)
        sprite.position = CGPoint(x: 2, y: 4)
        character.addChild(sprite)
        worldNode.addChild(character)
    }

    private func setupHUD() {
        updateHUD()
    }

    private func createPlatform(x: CGFloat, y: CGFloat, width: CGFloat, kind: PlatformKind) {
        let platform = SKNode()
        platform.name = "platform"
        platform.position = CGPoint(x: x, y: y)
        platform.zPosition = 5
        platform.userData = ["kind": kind.rawValue, "width": width, "landed": false, "rewarded": false]

        let platformAssets: [PlatformKind: String] = [
            .normal: "platform_normal", .small: "platform_small", .moving: "platform_moving",
            .rotten: "platform_rotten", .fragile: "platform_fragile", .spring: "platform_spring",
            .ice: "platform_ice", .sticky: "platform_sticky", .vanishing: "platform_vanishing",
            .finish: "platform_finish"
        ]
        if let assetName = platformAssets[kind] {
            let artwork = SKSpriteNode(imageNamed: assetName)
            artwork.name = "platformArtwork"
            artwork.size = CGSize(width: width + 20, height: max(66, width * 0.62))
            artwork.position.y = -22
            platform.addChild(artwork)
            worldNode.addChild(platform)
            generatedPlatformCount += 1
            if generatedPlatformCount > 5 && generatedPlatformCount % 11 == 0 && kind != .rotten {
                createPowerup(above: platform)
            }
            if generatedPlatformCount > 8 && generatedPlatformCount % 17 == 0 && kind != .rotten {
                createTreasure(above: platform)
            }
            return
        }

        let rock = SKShapeNode(path: islandPath(width: width, height: 46))
        rock.fillColor = kind == .rotten ? UIColor(red: 0.30, green: 0.20, blue: 0.27, alpha: 1) : UIColor(red: 0.42, green: 0.25, blue: 0.12, alpha: 1)
        rock.strokeColor = UIColor.black.withAlphaComponent(0.22)
        rock.lineWidth = 2
        rock.position.y = -20
        platform.addChild(rock)

        let top = SKShapeNode(rectOf: CGSize(width: width, height: 18), cornerRadius: 9)
        switch kind {
        case .rotten: top.fillColor = .systemPurple
        case .spring: top.fillColor = .systemMint
        case .ice: top.fillColor = .systemCyan
        case .sticky: top.fillColor = .systemPink
        case .vanishing: top.fillColor = UIColor.white.withAlphaComponent(0.62)
        case .finish: top.fillColor = .systemYellow
        default: top.fillColor = .systemGreen
        }
        top.strokeColor = UIColor.black.withAlphaComponent(0.18)
        top.lineWidth = 2
        platform.addChild(top)

        if kind == .fragile {
            let crack = SKShapeNode(path: crackPath())
            crack.strokeColor = .white.withAlphaComponent(0.7)
            crack.lineWidth = 2
            platform.addChild(crack)
        }

        if kind == .rotten {
            for offset in [-0.26, 0.10, 0.31] {
                let spot = SKShapeNode(circleOfRadius: 3)
                spot.fillColor = .black.withAlphaComponent(0.5)
                spot.strokeColor = .clear
                spot.position.x = width * offset
                platform.addChild(spot)
            }
        }

        worldNode.addChild(platform)
        generatedPlatformCount += 1
        if generatedPlatformCount > 5 && generatedPlatformCount % 11 == 0 && kind != .rotten && kind != .finish {
            createPowerup(above: platform)
        }
        if generatedPlatformCount > 8 && generatedPlatformCount % 17 == 0 && kind != .rotten && kind != .finish {
            createTreasure(above: platform)
        }
    }

    private func createTreasure(above platform: SKNode) {
        let chest = SKNode()
        chest.name = "treasure"
        chest.position = CGPoint(x: platform.position.x, y: platform.position.y + 48)
        chest.zPosition = 15
        let artwork = SKSpriteNode(imageNamed: "treasure_chest_closed")
        artwork.size = CGSize(width: 48, height: 48)
        chest.addChild(artwork)
        worldNode.addChild(chest)
    }

    private func createPowerup(above platform: SKNode) {
        let kinds = PowerupKind.allCases
        let kind = kinds[randomInt(in: 0...(kinds.count - 1))]
        let pickup = SKNode()
        pickup.name = "powerup"
        pickup.userData = ["kind": kind.rawValue]
        pickup.position = CGPoint(x: platform.position.x, y: platform.position.y + 52)
        pickup.zPosition = 16

        let powerupAssets: [PowerupKind: String] = [
            .shield: "powerup_shield", .magnet: "powerup_magnet", .wings: "powerup_wings",
            .goldenEgg: "powerup_golden_egg", .rocket: "powerup_rocket", .rescueFeather: "powerup_rescue_feather"
        ]
        if let assetName = powerupAssets[kind] {
            let artwork = SKSpriteNode(imageNamed: assetName)
            artwork.size = CGSize(width: 44, height: 44)
            pickup.addChild(artwork)
            pickup.run(.repeatForever(.sequence([.moveBy(x: 0, y: 7, duration: 0.55), .moveBy(x: 0, y: -7, duration: 0.55)])))
            worldNode.addChild(pickup)
            return
        }

        let ring = SKShapeNode(circleOfRadius: 17)
        ring.fillColor = UIColor.black.withAlphaComponent(0.35)
        ring.strokeColor = powerupColor(kind)
        ring.lineWidth = 3
        pickup.addChild(ring)

        let symbol = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        symbol.text = powerupSymbol(kind)
        symbol.fontSize = 18
        symbol.fontColor = powerupColor(kind)
        symbol.verticalAlignmentMode = .center
        pickup.addChild(symbol)
        pickup.run(.repeatForever(.sequence([.moveBy(x: 0, y: 7, duration: 0.55), .moveBy(x: 0, y: -7, duration: 0.55)])))
        worldNode.addChild(pickup)
    }

    private func generatePlatforms() {
        let targetTop = size.height + 260
        while highestPlatformY < targetTop {
            if !configuration.endless && !finishCreated {
                let absoluteHeight = traveledHeight + highestPlatformY
                if absoluteHeight + CGFloat(levelDefinition.maximumGap) >= CGFloat(configuration.targetHeight) {
                    let desiredY = CGFloat(configuration.targetHeight) - traveledHeight
                    highestPlatformY = max(highestPlatformY + 88, desiredY)
                    lastPlatformX = size.width / 2
                    createPlatform(x: lastPlatformX, y: highestPlatformY, width: 230, kind: .finish)
                    finishCreated = true
                    break
                }
            }
            let difficulty = max(CGFloat(levelDefinition.difficulty), min(1, traveledHeight / 2_500))
            let gap = randomCGFloat(in: CGFloat(levelDefinition.minimumGap)...CGFloat(levelDefinition.maximumGap))
            highestPlatformY += gap
            let maxShift = 120 + difficulty * 32
            let proposed = lastPlatformX + randomCGFloat(in: -maxShift...maxShift)
            lastPlatformX = min(max(64, proposed == 0 ? size.width / 2 : proposed), size.width - 64)

            let roll = randomInt(in: 0...99)
            let kind: PlatformKind
            if traveledHeight < 180 {
                kind = .normal
            } else {
                switch configuration.world.id {
                case "ice":
                    if roll < 20 { kind = .ice }
                    else if roll < 34 { kind = .moving }
                    else if roll < 44 { kind = .fragile }
                    else if roll < 58 { kind = .small }
                    else { kind = .normal }
                case "fire":
                    if roll < 21 { kind = .fragile }
                    else if roll < 32 { kind = .rotten }
                    else if roll < 43 { kind = .spring }
                    else if roll < 58 { kind = .small }
                    else { kind = .normal }
                case "night":
                    if roll < 18 { kind = .vanishing }
                    else if roll < 30 { kind = .sticky }
                    else if roll < 41 { kind = .moving }
                    else if roll < 51 { kind = .rotten }
                    else if roll < 64 { kind = .small }
                    else { kind = .normal }
                default:
                    if roll < 12 { kind = .rotten }
                    else if roll < 25 { kind = .moving }
                    else if roll < 35 { kind = .fragile }
                    else if roll < 41 { kind = .spring }
                    else if roll < 56 { kind = .small }
                    else { kind = .normal }
                }
            }

            let width: CGFloat = kind == .small ? 78 : randomCGFloat(in: 112...166)

            // Rotten platforms are optional traps, never part of the only route.
            // Keep the generated route position safe and place the rotten island
            // beside it so every campaign seed always has a valid next landing.
            if kind == .rotten {
                let safeX = lastPlatformX
                let leftSpace = safeX - 58
                let rightSpace = (size.width - 58) - safeX
                let sideDirection: CGFloat = rightSpace >= leftSpace ? 1 : -1
                let sideDistance = randomCGFloat(in: 122...148)
                let rottenX = min(max(58, safeX + sideDirection * sideDistance), size.width - 58)

                createPlatform(
                    x: rottenX,
                    y: highestPlatformY + randomCGFloat(in: -5...9),
                    width: randomCGFloat(in: 88...104),
                    kind: .rotten
                )
                createPlatform(
                    x: safeX,
                    y: highestPlatformY,
                    width: max(128, width),
                    kind: .normal
                )
                lastPlatformX = safeX
            } else {
                createPlatform(x: lastPlatformX, y: highestPlatformY, width: width, kind: kind)
            }
        }
    }

    override func update(_ currentTime: TimeInterval) {
        guard !finished, !isPaused else { return }
        let rawDelta = previousTime == 0 ? 1.0 / 60.0 : currentTime - previousTime
        previousTime = currentTime
        sceneTime = currentTime
        if !startingBoostApplied {
            startingBoostApplied = true
            applyStartingBoost()
        }
        let delta = min(CGFloat(rawDelta), 1.0 / 30.0)

        let acceleration: CGFloat = 1_250 * controlSensitivity
        velocity.dx += horizontalInput * acceleration * delta
        if currentTime < windUntil { velocity.dx += windDirection * 92 * delta }
        if horizontalInput == 0 { velocity.dx *= pow(0.04, delta) }
        velocity.dx = min(max(velocity.dx, -270 * controlSensitivity), 270 * controlSensitivity)

        if horizontalInput != 0,
           let artwork = character.childNode(withName: "characterArtwork") as? SKSpriteNode {
            let targetScale: CGFloat = horizontalInput < 0 ? -1 : 1
            let turnSpeed = min(1, delta * 18)
            artwork.xScale += (targetScale - artwork.xScale) * turnSpeed
        }
        let winged = currentTime < wingsUntil
        velocity.dy -= (winged ? 1_190 : 1_480) * delta

        let oldY = character.position.y
        character.position.x += velocity.dx * delta
        character.position.y += velocity.dy * delta
        character.zRotation = max(-0.18, min(0.18, -velocity.dx / 1_400))

        if character.position.x < -24 {
            character.position.x = size.width + 24
        } else if character.position.x > size.width + 24 {
            character.position.x = -24
        }

        updateMovingPlatforms(delta: delta)
        updateHazards(delta: delta)
        detectPickups()
        detectTreasure()
        if velocity.dy <= 0 { detectLanding(from: oldY) }
        updateCameraIfNeeded()

        if character.position.y < -70 { endRun(completed: false, reason: "Tommy fell below the clouds") }
        updatePowerupHUD()
        worldEffectLabel.text = currentTime < windUntil ? "WIND  \(windDirection < 0 ? "←" : "→")" : ""
        publishHUD()
        checkCheckpoint()
    }

    private func detectLanding(from oldY: CGFloat) {
        let oldBottom = oldY - 24
        let newBottom = character.position.y - 24

        for platform in worldNode.children where platform.name == "platform" {
            guard let width = platform.userData?["width"] as? CGFloat else { continue }
            let topY = platform.position.y + 9
            let withinX = abs(character.position.x - platform.position.x) <= width / 2 + 14
            let crossedTop = oldBottom >= topY - 4 && newBottom <= topY + 6
            guard withinX && crossedTop else { continue }

            let kind = PlatformKind(rawValue: platform.userData?["kind"] as? String ?? "normal") ?? .normal
            land(on: platform, width: width, kind: kind)
            break
        }
    }

    private func land(on platform: SKNode, width: CGFloat, kind: PlatformKind) {
        character.position.y = platform.position.y + 34

        if kind == .rotten {
            perfectStreak = 0
            platform.run(.sequence([.group([.fadeOut(withDuration: 0.28), .moveBy(x: 0, y: -35, duration: 0.28)]), .removeFromParent()]))
            velocity.dy = -180
            showFloatingText("ROTTEN!", color: .systemPurple, at: character.position)
            playSound(.rotten)
            return
        }

        let alreadyRewarded = platform.userData?["rewarded"] as? Bool ?? false
        if alreadyRewarded && kind != .finish {
            velocity.dy = kind == .spring ? 860 : 650
            if kind == .sticky { velocity.dx *= 0.12 }
            if kind == .ice { velocity.dx *= 1.12 }
            platform.run(.sequence([.scaleY(to: 0.80, duration: 0.06), .scaleY(to: 1, duration: 0.12)]))
            return
        }
        platform.userData?["rewarded"] = true

        let precision = abs(character.position.x - platform.position.x) / max(1, width / 2)
        if precision <= 0.30 {
            perfectStreak += 1
            perfects += 1
            let multiplier = comboMultiplier
            coins += 5 * multiplier * coinMultiplier
            score += 100 * multiplier
            maxCombo = max(maxCombo, multiplier)
            showFloatingText("PERFECT  x\(multiplier)", color: .systemYellow, at: character.position)
            spawnCoins(at: platform.position, count: min(5, 2 + multiplier))
            if tutorialStep == 1 { advanceTutorial() }
            playSound(kind == .spring ? .spring : .perfect)
        } else if precision <= 0.78 {
            coins += 2 * coinMultiplier
            score += 20
            showFloatingText("GOOD", color: .white, at: character.position)
            playSound(kind == .spring ? .spring : .land)
        } else {
            coins += 1 * coinMultiplier
            perfectStreak = 0
            score += 10
            showFloatingText("EDGE SAVE", color: .systemOrange, at: character.position)
            playSound(kind == .spring ? .spring : .land)
        }

        let jumpPower: CGFloat = kind == .spring ? 860 : 650
        velocity.dy = jumpPower
        if kind == .sticky { velocity.dx *= 0.12 }
        if kind == .ice { velocity.dx *= 1.12 }
        platform.run(.sequence([.scaleY(to: 0.80, duration: 0.06), .scaleY(to: 1, duration: 0.12)]))

        if kind == .fragile && platform.userData?["landed"] as? Bool == false {
            platform.userData?["landed"] = true
            platform.run(.sequence([.wait(forDuration: 0.16), .group([.fadeOut(withDuration: 0.25), .moveBy(x: 0, y: -45, duration: 0.25)]), .removeFromParent()]))
        }
        if kind == .vanishing && platform.userData?["landed"] as? Bool == false {
            platform.userData?["landed"] = true
            platform.run(.sequence([.wait(forDuration: 0.10), .fadeOut(withDuration: 0.28), .removeFromParent()]))
        }
        if sceneTime < magnetUntil {
            coins += 3 * coinMultiplier
            showFloatingText("MAGNET +\(3 * coinMultiplier)", color: .systemPink, at: CGPoint(x: character.position.x, y: character.position.y + 20))
        }
        updateHUD()
        if hapticsEnabled {
            let generator = UIImpactFeedbackGenerator(style: precision <= 0.30 ? .medium : .light)
            generator.impactOccurred()
        }
        if kind == .finish {
            showFloatingText("FINISH!", color: .systemYellow, at: CGPoint(x: character.position.x, y: character.position.y + 30))
            endRun(completed: true, reason: "You reached the finish island!")
        }
    }

    private var comboMultiplier: Int {
        switch perfectStreak {
        case 0...2: return 1
        case 3...5: return 2
        case 6...9: return 3
        case 10...14: return 4
        default: return 5
        }
    }

    private func updateCameraIfNeeded() {
        let threshold = size.height * 0.56
        guard character.position.y > threshold else { return }
        let shift = character.position.y - threshold
        character.position.y = threshold
        traveledHeight += shift
        highestPlatformY -= shift
        for node in worldNode.children where node !== character {
            node.position.y -= shift
            if node.position.y < -110 { node.removeFromParent() }
        }
        generatePlatforms()
        if traveledHeight >= nextHazardHeight {
            createWorldHazard()
            nextHazardHeight += randomCGFloat(in: CGFloat(levelDefinition.hazardInterval.lowerBound)...CGFloat(levelDefinition.hazardInterval.upperBound))
        }
        score += Int(shift) * 10
        updateHUD()

        if tutorialEnabled && tutorialStep == 0 && traveledHeight > 80 { advanceTutorial() }
        if tutorialEnabled && tutorialStep == 2 && traveledHeight > 360 { advanceTutorial() }
    }

    private func updateMovingPlatforms(delta: CGFloat) {
        for platform in worldNode.children where platform.name == "platform" && platform.userData?["kind"] as? String == PlatformKind.moving.rawValue {
            let direction = platform.userData?["direction"] as? CGFloat ?? 1
            platform.position.x += direction * 72 * delta
            if platform.position.x < 65 {
                platform.position.x = 65
                platform.userData?["direction"] = CGFloat(1)
            } else if platform.position.x > size.width - 65 {
                platform.position.x = size.width - 65
                platform.userData?["direction"] = CGFloat(-1)
            } else if platform.userData?["direction"] == nil {
                platform.userData?["direction"] = randomBool() ? CGFloat(1) : CGFloat(-1)
            }
        }
    }

    private func createWorldHazard() {
        if configuration.world.id == "ice" && randomBool() {
            randomBool() ? createWindGust() : createFallingHazard(icicle: true)
        } else if configuration.world.id == "fire" && randomBool() {
            createFallingHazard(icicle: false)
        } else if configuration.world.id == "night" && randomBool() {
            createLightningHazard()
        } else {
            createFlyingHazard()
        }
    }

    private func createFallingHazard(icicle: Bool) {
        let hazard = SKNode()
        hazard.name = "hazard"
        hazard.position = CGPoint(x: randomCGFloat(in: 35...(size.width - 35)), y: size.height + 45)
        hazard.userData = ["direction": CGFloat(0), "hit": false, "vertical": true, "speed": CGFloat(icicle ? 250 : 210)]
        hazard.zPosition = 18
        let artwork = SKSpriteNode(imageNamed: icicle ? "hazard_icicle" : "hazard_rock")
        artwork.size = icicle ? CGSize(width: 32, height: 70) : CGSize(width: 48, height: 48)
        hazard.addChild(artwork)
        worldNode.addChild(hazard)

        let marker = SKShapeNode(ellipseOf: CGSize(width: 46, height: 13))
        marker.fillColor = .systemRed.withAlphaComponent(0.32)
        marker.strokeColor = .systemRed
        marker.position = CGPoint(x: hazard.position.x, y: size.height * 0.30)
        marker.zPosition = 12
        addChild(marker)
        marker.run(.sequence([.repeat(.sequence([.fadeAlpha(to: 0.25, duration: 0.14), .fadeAlpha(to: 1, duration: 0.14)]), count: 4), .removeFromParent()]))
    }

    private func createWindGust() {
        windDirection = randomBool() ? 1 : -1
        windUntil = sceneTime + 4.5
        let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        label.text = windDirection < 0 ? "WIND FROM THE RIGHT  ←" : "WIND FROM THE LEFT  →"
        label.fontSize = 15
        label.fontColor = .systemCyan
        label.position = CGPoint(x: size.width / 2, y: size.height * 0.72)
        label.zPosition = 100
        addChild(label)
        label.run(.sequence([.repeat(.sequence([.fadeAlpha(to: 0.35, duration: 0.18), .fadeAlpha(to: 1, duration: 0.18)]), count: 3), .fadeOut(withDuration: 0.25), .removeFromParent()]))
    }

    private func createLightningHazard() {
        let x = randomCGFloat(in: 55...(size.width - 55))
        let lightning = SKShapeNode(rectOf: CGSize(width: 12, height: size.height * 0.78), cornerRadius: 5)
        lightning.name = "lightning"
        lightning.fillColor = .systemYellow
        lightning.strokeColor = .white
        lightning.lineWidth = 3
        lightning.position = CGPoint(x: x, y: size.height * 0.45)
        lightning.alpha = 0.16
        lightning.zPosition = 70
        addChild(lightning)
        lightning.run(.sequence([
            .repeat(.sequence([.fadeAlpha(to: 0.45, duration: 0.12), .fadeAlpha(to: 0.12, duration: 0.12)]), count: 3),
            .run { [weak self, weak lightning] in
                guard let self, let lightning else { return }
                lightning.alpha = 1
                if abs(self.character.position.x - x) < 30 {
                    self.handleHazardHit(lightning, direction: x < self.size.width / 2 ? 1 : -1)
                } else {
                    self.playSound(.hazard)
                }
            },
            .wait(forDuration: 0.12),
            .fadeOut(withDuration: 0.18),
            .removeFromParent()
        ]))
    }

    private func createFlyingHazard() {
        let hazard = SKNode()
        hazard.name = "hazard"
        let fromLeft = randomBool()
        hazard.position = CGPoint(x: fromLeft ? -38 : size.width + 38, y: size.height * randomCGFloat(in: 0.48...0.78))
        hazard.userData = ["direction": fromLeft ? CGFloat(1) : CGFloat(-1), "hit": false]
        hazard.zPosition = 17

        let artwork = SKSpriteNode(imageNamed: configuration.world.id == "fire" ? "hazard_fire_bird" : "hazard_bird")
        artwork.size = CGSize(width: 64, height: 54)
        artwork.xScale = fromLeft ? 1 : -1
        hazard.addChild(artwork)
        worldNode.addChild(hazard)

        let warning = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        warning.text = "!"
        warning.fontSize = 24
        warning.fontColor = .systemYellow
        warning.position = CGPoint(x: fromLeft ? 20 : size.width - 20, y: hazard.position.y)
        warning.zPosition = 90
        addChild(warning)
        warning.run(.sequence([.fadeAlpha(to: 0.2, duration: 0.15), .fadeAlpha(to: 1, duration: 0.15), .wait(forDuration: 0.25), .removeFromParent()]))
    }

    private func updateHazards(delta: CGFloat) {
        for hazard in worldNode.children where hazard.name == "hazard" {
            let direction = hazard.userData?["direction"] as? CGFloat ?? 1
            if hazard.userData?["vertical"] as? Bool == true {
                let speed = hazard.userData?["speed"] as? CGFloat ?? 220
                hazard.position.y -= speed * delta
                hazard.zRotation += delta * 2.2
            } else {
                hazard.position.x += direction * 205 * delta
            }
            if abs(hazard.position.x - character.position.x) < 35,
               abs(hazard.position.y - character.position.y) < 34,
               hazard.userData?["hit"] as? Bool == false {
                hazard.userData?["hit"] = true
                handleHazardHit(hazard, direction: direction)
            }
            if hazard.position.x < -90 || hazard.position.x > size.width + 90 || hazard.position.y < -90 { hazard.removeFromParent() }
        }
    }

    private func handleHazardHit(_ hazard: SKNode, direction: CGFloat) {
        if sceneTime < invulnerableUntil {
            hazard.run(.sequence([.fadeOut(withDuration: 0.12), .removeFromParent()]))
            return
        }
        if shieldActive {
            shieldActive = false
            showFloatingText("SHIELD BLOCK", color: .systemCyan, at: character.position)
            hazard.run(.sequence([.scale(to: 1.6, duration: 0.12), .fadeOut(withDuration: 0.16), .removeFromParent()]))
            playSound(.shield)
        } else {
            perfectStreak = 0
            velocity.dx = direction * 360
            velocity.dy = min(velocity.dy, -120)
            showFloatingText("HIT!", color: .systemRed, at: character.position)
            character.run(.sequence([.colorize(with: .white, colorBlendFactor: 1, duration: 0.08), .colorize(withColorBlendFactor: 0, duration: 0.16)]))
            if hapticsEnabled { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
            playSound(.hit)
            shakeCamera()
        }
        updateHUD()
    }

    private func detectPickups() {
        for pickup in worldNode.children where pickup.name == "powerup" {
            guard abs(pickup.position.x - character.position.x) < 32,
                  abs(pickup.position.y - character.position.y) < 38,
                  let raw = pickup.userData?["kind"] as? String,
                  let kind = PowerupKind(rawValue: raw) else { continue }
            activate(kind)
            pickup.name = "collected"
            pickup.run(.sequence([.group([.scale(to: 1.8, duration: 0.16), .fadeOut(withDuration: 0.16)]), .removeFromParent()]))
        }
    }

    private func detectTreasure() {
        for chest in worldNode.children where chest.name == "treasure" {
            guard abs(chest.position.x - character.position.x) < 34,
                  abs(chest.position.y - character.position.y) < 40 else { continue }
            chest.name = "openedTreasure"
            let reward = randomInt(in: 25...55) * coinMultiplier
            coins += reward
            chestsOpened += 1
            score += 250
            showFloatingText("CHEST +\(reward)", color: .systemYellow, at: chest.position)
            playSound(.chest)
            chest.run(.sequence([.group([.scale(to: 1.5, duration: 0.16), .fadeOut(withDuration: 0.20)]), .removeFromParent()]))
            updateHUD()
        }
    }

    private func activate(_ kind: PowerupKind) {
        switch kind {
        case .shield: shieldActive = true
        case .magnet: magnetUntil = sceneTime + 12
        case .wings: wingsUntil = sceneTime + 8
        case .goldenEgg: goldenUntil = sceneTime + 10
        case .rocket:
            velocity.dy = 1_080
            invulnerableUntil = sceneTime + 2.2
        case .rescueFeather:
            rescueFeathersFound += 1
        }
        showFloatingText(kind.title, color: powerupColor(kind), at: character.position)
        if hapticsEnabled { UINotificationFeedbackGenerator().notificationOccurred(.success) }
        playSound(.powerup)
        updatePowerupHUD()
    }

    private var coinMultiplier: Int { sceneTime < goldenUntil ? 2 : 1 }

    private func applyStartingBoost() {
        switch configuration.boost {
        case .none: break
        case .shield:
            shieldActive = true
            showFloatingText("STARTING SHIELD", color: .systemCyan, at: character.position)
        case .wings:
            wingsUntil = sceneTime + 12
            showFloatingText("STARTING WINGS", color: .white, at: character.position)
        case .goldenEgg:
            goldenUntil = sceneTime + 15
            showFloatingText("STARTING 2x COINS", color: .systemYellow, at: character.position)
        }
        updatePowerupHUD()
    }

    private func playSound(_ sound: GameSound) {
        guard soundEnabled else { return }
        run(.playSoundFileNamed(sound.rawValue, waitForCompletion: false))
    }

    private func updateMusic() {
        guard view != nil else { return }
        musicEnabled ? musicPlayer.start(worldID: configuration.world.id) : musicPlayer.stop()
    }

    func pauseAudio() { musicPlayer.stop() }
    func resumeAudio() { if musicEnabled { musicPlayer.start(worldID: configuration.world.id) } }

    private func shakeCamera() {
        guard cameraShakeEnabled, !reducedEffects else { return }
        worldNode.run(.sequence([
            .moveBy(x: -7, y: 0, duration: 0.035),
            .moveBy(x: 13, y: 0, duration: 0.055),
            .moveBy(x: -9, y: 0, duration: 0.05),
            .moveBy(x: 3, y: 0, duration: 0.04)
        ]))
    }

    private func updatePowerupHUD() {
        var active: [String] = []
        if shieldActive { active.append("SHIELD") }
        if sceneTime < magnetUntil { active.append("MAGNET \(max(1, Int(magnetUntil - sceneTime)))s") }
        if sceneTime < wingsUntil { active.append("WINGS \(max(1, Int(wingsUntil - sceneTime)))s") }
        if sceneTime < goldenUntil { active.append("2x COINS \(max(1, Int(goldenUntil - sceneTime)))s") }
        powerupLabel.text = active.joined(separator: "  •  ")
        publishHUD()
    }

    private func checkCheckpoint() {
        guard !checkpointReached,
              !configuration.endless,
              let checkpoint = levelDefinition.checkpointHeight,
              Int(traveledHeight) >= checkpoint else { return }
        checkpointReached = true
        coins += 15
        showFloatingText("CHECKPOINT +15", color: .systemGreen, at: character.position)
        playSound(.checkpoint)
        if hapticsEnabled { UINotificationFeedbackGenerator().notificationOccurred(.success) }
        updateHUD()
    }

    private func powerupColor(_ kind: PowerupKind) -> UIColor {
        switch kind {
        case .shield: return .systemCyan
        case .magnet: return .systemPink
        case .wings: return .white
        case .goldenEgg: return .systemYellow
        case .rocket: return .systemOrange
        case .rescueFeather: return .systemGreen
        }
    }

    private func powerupSymbol(_ kind: PowerupKind) -> String {
        switch kind {
        case .shield: return "S"
        case .magnet: return "M"
        case .wings: return "W"
        case .goldenEgg: return "2x"
        case .rocket: return "R"
        case .rescueFeather: return "F"
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) { updateInput(touches.first) }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) { updateInput(touches.first) }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) { horizontalInput = 0 }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) { horizontalInput = 0 }

    private func updateInput(_ touch: UITouch?) {
        guard let touch else { return }
        horizontalInput = touch.location(in: self).x < size.width / 2 ? -1 : 1
    }

    private func updateHUD() {
        scoreLabel.text = "SCORE  \(score)"
        heightLabel.text = "HEIGHT  \(Int(traveledHeight))m"
        coinLabel.text = "●  \(coins)"
        comboLabel.text = perfectStreak >= 3 ? "COMBO x\(comboMultiplier)" : ""
        publishHUD()
    }

    private func publishHUD() {
        let snapshot = GameHUDSnapshot(
            score: score,
            height: Int(traveledHeight),
            coins: coins,
            combo: comboMultiplier,
            powerups: powerupLabel.text ?? "",
            worldEffect: worldEffectLabel.text ?? ""
        )
        guard snapshot != lastHUDSnapshot else { return }
        lastHUDSnapshot = snapshot
        onHUDChanged?(snapshot)
    }

    func emitHUD() {
        onHUDChanged?(GameHUDSnapshot(
            score: score,
            height: Int(traveledHeight),
            coins: coins,
            combo: comboMultiplier,
            powerups: powerupLabel.text ?? "",
            worldEffect: worldEffectLabel.text ?? ""
        ))
    }

    private func spawnCoins(at point: CGPoint, count: Int) {
        guard !reducedEffects else { return }
        if soundEnabled {
            run(.sequence([
                .wait(forDuration: 0.10),
                .playSoundFileNamed(GameSound.coin.rawValue, waitForCompletion: false)
            ]))
        }
        for index in 0..<count {
            let coin = SKSpriteNode(imageNamed: "coin")
            coin.size = CGSize(width: 22, height: 22)
            coin.position = point
            coin.zPosition = 30
            worldNode.addChild(coin)
            let angle = CGFloat(index) / CGFloat(max(1, count - 1)) * .pi
            let target = CGVector(dx: cos(angle) * 55, dy: 55 + sin(angle) * 35)
            coin.run(.sequence([.group([.move(by: target, duration: 0.30), .scale(to: 1.25, duration: 0.18)]), .group([.fadeOut(withDuration: 0.22), .moveBy(x: 0, y: -18, duration: 0.22)]), .removeFromParent()]))
        }
    }

    private func showFloatingText(_ text: String, color: UIColor, at point: CGPoint) {
        let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        label.text = text
        label.fontSize = 18
        label.fontColor = color
        label.position = CGPoint(x: point.x, y: point.y + 42)
        label.zPosition = 50
        worldNode.addChild(label)
        label.run(.sequence([.group([.moveBy(x: 0, y: 42, duration: 0.55), .fadeOut(withDuration: 0.55)]), .removeFromParent()]))
    }

    private func showTutorial(_ text: String) {
        tutorialLabel?.removeFromParent()
        let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        label.text = text
        label.fontSize = 15
        label.fontColor = .white
        label.position = CGPoint(x: size.width / 2, y: size.height * 0.28)
        label.zPosition = 120
        let panel = SKShapeNode(rectOf: CGSize(width: min(size.width - 36, 340), height: 50), cornerRadius: 18)
        panel.fillColor = .black.withAlphaComponent(0.58)
        panel.strokeColor = .white.withAlphaComponent(0.2)
        panel.position = label.position
        panel.zPosition = 119
        panel.name = "tutorialPanel"
        addChild(panel)
        addChild(label)
        tutorialLabel = label
    }

    private func advanceTutorial() {
        childNode(withName: "tutorialPanel")?.removeFromParent()
        tutorialStep += 1
        switch tutorialStep {
        case 1: showTutorial("LAND IN THE CENTER FOR A PERFECT")
        case 2: showTutorial("AVOID PURPLE ROTTEN ISLANDS")
        default:
            tutorialLabel?.run(.sequence([.fadeOut(withDuration: 0.25), .removeFromParent()]))
            tutorialLabel = nil
        }
    }

    private func endRun(completed: Bool, reason: String) {
        guard !finished else { return }
        finished = true
        horizontalInput = 0
        let result = RunResult(completed: completed, score: score, height: Int(traveledHeight), coins: coins, perfects: perfects, maxCombo: maxCombo, reason: reason, rescueFeathersFound: rescueFeathersFound, chestsOpened: chestsOpened)
        if hapticsEnabled {
            UINotificationFeedbackGenerator().notificationOccurred(completed ? .success : .error)
        }
        playSound(completed ? .levelComplete : .gameOver)
        musicPlayer.stop()
        run(.wait(forDuration: 0.42)) { [weak self] in self?.onFinished?(result) }
    }

    func revive() {
        guard finished else { return }
        finished = false
        playSound(.revive)
        resumeAudio()
        previousTime = 0
        perfectStreak = 0
        horizontalInput = 0
        velocity = CGVector(dx: 0, dy: 650)
        character.position = CGPoint(x: size.width / 2, y: max(190, size.height * 0.30))
        character.alpha = 1

        emergencyPlatform?.removeFromParent()
        createPlatform(x: size.width / 2, y: character.position.y - 38, width: 190, kind: .normal)
        emergencyPlatform = worldNode.children.last
        character.run(.sequence([.repeat(.sequence([.fadeAlpha(to: 0.35, duration: 0.12), .fadeAlpha(to: 1, duration: 0.12)]), count: 5)]))
        showFloatingText("RESCUED!", color: .systemYellow, at: character.position)
        updateHUD()
    }

    private func trianglePath(width: CGFloat, height: CGFloat) -> CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -width / 2, y: -height / 2))
        path.addLine(to: CGPoint(x: width / 2, y: 0))
        path.addLine(to: CGPoint(x: -width / 2, y: height / 2))
        path.closeSubpath()
        return path
    }

    private func islandPath(width: CGFloat, height: CGFloat) -> CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -width / 2, y: 0))
        path.addLine(to: CGPoint(x: width / 2, y: 0))
        path.addLine(to: CGPoint(x: width * 0.28, y: -height))
        path.addLine(to: CGPoint(x: 0, y: -height * 1.22))
        path.addLine(to: CGPoint(x: -width * 0.32, y: -height))
        path.closeSubpath()
        return path
    }

    private func crackPath() -> CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -8, y: 7))
        path.addLine(to: CGPoint(x: -2, y: 1))
        path.addLine(to: CGPoint(x: -5, y: -7))
        path.move(to: CGPoint(x: -2, y: 1))
        path.addLine(to: CGPoint(x: 8, y: -4))
        return path
    }

    private func randomInt(in range: ClosedRange<Int>) -> Int {
        Int.random(in: range, using: &randomGenerator)
    }

    private func randomCGFloat(in range: ClosedRange<CGFloat>) -> CGFloat {
        CGFloat.random(in: range, using: &randomGenerator)
    }

    private func randomBool() -> Bool {
        randomInt(in: 0...1) == 1
    }
}

private extension SKLabelNode {
    func addShadow() {
        let shadow = SKLabelNode(fontNamed: fontName)
        shadow.text = text
        shadow.fontSize = fontSize
        shadow.fontColor = .black.withAlphaComponent(0.35)
        shadow.position = CGPoint(x: 1.5, y: -1.5)
        shadow.zPosition = -1
        addChild(shadow)
    }
}
