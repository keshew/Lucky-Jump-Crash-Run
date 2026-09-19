import SwiftUI
import SpriteKit

struct GameContainerView: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.scenePhase) private var scenePhase
    let configuration: RunConfiguration
    let showTutorial: Bool
    @State private var currentConfiguration: RunConfiguration
    @State private var scene: GameScene
    @State private var paused = false
    @State private var result: RunResult?
    @State private var pendingFailure: RunResult?
    @State private var reviveUsed = false
    @State private var hud = GameHUDSnapshot()
    @State private var sceneVersion = UUID()

    init(configuration: RunConfiguration, showTutorial: Bool) {
        self.configuration = configuration
        self.showTutorial = showTutorial
        _currentConfiguration = State(initialValue: configuration)
        _scene = State(initialValue: GameScene(configuration: configuration, showTutorial: showTutorial))
    }

    var body: some View {
        ZStack {
            SpriteView(scene: scene, options: [.ignoresSiblingOrder])
                .id(sceneVersion)
                .ignoresSafeArea()

            VStack {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(currentConfiguration.dailyChallenge ? "DAILY" : (currentConfiguration.endless ? "ENDLESS" : "LEVEL \(currentConfiguration.level)"))
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                        Text(currentConfiguration.world.name)
                            .font(.system(size: 17, weight: .black, design: .rounded))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial.opacity(0.80))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.16), lineWidth: 1))
                    .shadow(color: .black.opacity(0.20), radius: 10, y: 6)
                    Spacer()
                    Button {
                        scene.pauseAudio()
                        scene.isPaused = true
                        paused = true
                    } label: {
                        Image("ui_pause_button")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 54, height: 54)
                            .shadow(color: .black.opacity(0.28), radius: 10, y: 6)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 18)
                .padding(.top, 6)

                HStack(spacing: 7) {
                    MetricChip(icon: "star.fill", label: "SCORE", value: hud.score.formatted(), tint: GameColors.yellow)
                    MetricChip(icon: "arrow.up", label: "HEIGHT", value: "\(hud.height)m", tint: GameColors.cyan)
                    MetricChip(icon: "circle.fill", label: "COINS", value: hud.coins.formatted(), tint: GameColors.yellow)
                }
                .padding(.horizontal, 14)
                .padding(.top, 7)

                if hud.combo > 1 || !hud.powerups.isEmpty || !hud.worldEffect.isEmpty {
                    VStack(spacing: 6) {
                        if hud.combo > 1 {
                            Text("COMBO  ×\(hud.combo)")
                                .font(.system(size: 14, weight: .black, design: .rounded))
                                .foregroundStyle(LinearGradient(colors: [GameColors.yellow, .orange], startPoint: .leading, endPoint: .trailing))
                        }
                        if !hud.powerups.isEmpty || !hud.worldEffect.isEmpty {
                            Text([hud.powerups, hud.worldEffect].filter { !$0.isEmpty }.joined(separator: "  •  "))
                                .font(.system(size: 10, weight: .black, design: .rounded))
                                .foregroundColor(.white.opacity(0.86))
                        }
                    }
                    .padding(.horizontal, 15)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial.opacity(0.76))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(.white.opacity(0.13), lineWidth: 1))
                    .transition(.scale.combined(with: .opacity))
                }
                Spacer()
            }

            if paused {
                PauseOverlay(
                    configuration: currentConfiguration,
                    snapshot: hud,
                    resume: { paused = false; scene.isPaused = false; scene.resumeAudio() },
                    restart: { replaceScene(with: currentConfiguration) },
                    exit: { scene.pauseAudio(); scene.isPaused = false; store.closeRun() }
                )
            }

            if let failure = pendingFailure {
                ReviveOverlay(
                    result: failure,
                    feathers: store.availableRescueFeathers,
                    revive: {
                        guard !reviveUsed, store.useRescueFeather() else { return }
                        reviveUsed = true
                        pendingFailure = nil
                        scene.revive()
                    },
                    finish: {
                        pendingFailure = nil
                        finalize(failure)
                    }
                )
            }

            if let result {
                ResultsOverlay(
                    result: result,
                    earnedFeathers: GameRules.earnedFeathers(result: result, configuration: currentConfiguration),
                    primaryTitle: result.completed && !currentConfiguration.endless && !currentConfiguration.dailyChallenge && currentConfiguration.level < 20 ? "NEXT LEVEL" : "TRY AGAIN",
                    replay: {
                        var nextConfiguration = currentConfiguration
                        if result.completed && !currentConfiguration.endless && !currentConfiguration.dailyChallenge && currentConfiguration.level < 20 {
                            nextConfiguration = RunConfiguration(world: currentConfiguration.world, level: currentConfiguration.level + 1, endless: false)
                        }
                        replaceScene(with: nextConfiguration)
                    },
                    exit: { scene.pauseAudio(); store.closeRun() }
                )
            }
        }
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
        .onAppear { connectScene(scene) }
        .onChange(of: scene) { newScene in connectScene(newScene) }
        .onChange(of: scenePhase) { phase in
            if phase != .active, result == nil, pendingFailure == nil {
                scene.pauseAudio()
                scene.isPaused = true
                paused = true
            }
        }
    }

    private func replaceScene(with configuration: RunConfiguration) {
        scene.pauseAudio()
        currentConfiguration = configuration
        result = nil
        pendingFailure = nil
        paused = false
        reviveUsed = false
        hud = GameHUDSnapshot()
        let newScene = GameScene(configuration: configuration, showTutorial: false)
        connectScene(newScene)
        scene = newScene
        sceneVersion = UUID()
    }

    private func connectScene(_ scene: GameScene) {
        scene.controlSensitivity = store.save.controlSensitivity
        scene.reducedEffects = store.save.reducedEffects
        scene.hapticsEnabled = store.save.hapticsEnabled
        scene.soundEnabled = store.save.soundEnabled
        scene.musicEnabled = store.save.musicEnabled
        scene.cameraShakeEnabled = store.save.cameraShake
        scene.onFinished = { finished in
            guard result == nil, pendingFailure == nil else { return }
            if !finished.completed && !reviveUsed && store.availableRescueFeathers > 0 {
                pendingFailure = finished
            } else {
                finalize(finished)
            }
        }
        scene.onHUDChanged = { snapshot in
            hud = snapshot
        }
        scene.emitHUD()
    }

    private func finalize(_ finished: RunResult) {
        if showTutorial && !store.save.gameplayTutorialCompleted {
            store.save.gameplayTutorialCompleted = true
        }
        store.finishRun(finished, configuration: currentConfiguration)
        result = finished
    }
}

private struct ReviveOverlay: View {
    let result: RunResult
    let feathers: Int
    let revive: () -> Void
    let finish: () -> Void

    var body: some View {
        ZStack {
            GameOverlayBackdrop(tint: GameColors.yellow)

            VStack(spacing: 0) {
                Text("ONE MORE CHANCE")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .tracking(1.7)
                    .foregroundColor(GameColors.yellow)
                    .padding(.top, 22)

                ZStack {
                    Circle()
                        .fill(GameColors.yellow.opacity(0.13))
                        .frame(width: 185, height: 185)
                        .blur(radius: 12)
                    Image("powerup_rescue_feather")
                        .resizable().scaledToFit()
                        .frame(width: 150, height: 150)
                        .shadow(color: GameColors.yellow.opacity(0.35), radius: 20, y: 10)
                }
                .frame(height: 170)

                Text("SAVE TOMMY?")
                    .font(.system(size: 31, weight: .black, design: .rounded))

                Text("Return to the last safe platform and keep climbing. Your combo will reset.")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.66))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 22)
                    .padding(.top, 7)

                HStack(spacing: 0) {
                    OverlayStat(icon: "arrow.up", title: "HEIGHT", value: "\(result.height)m", tint: GameColors.cyan)
                    Divider().overlay(.white.opacity(0.12)).frame(height: 42)
                    OverlayStat(icon: "star.fill", title: "SCORE", value: result.score.formatted(), tint: GameColors.yellow)
                }
                .padding(.vertical, 13)
                .background(.black.opacity(0.18))
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .padding(.horizontal, 18)
                .padding(.top, 18)

                Button(action: revive) {
                    HStack(spacing: 10) {
                        Image("powerup_rescue_feather").resizable().scaledToFit().frame(width: 30, height: 30)
                        Text("USE FEATHER")
                        Spacer()
                        Text("\(feathers) LEFT").font(.system(size: 11, weight: .black, design: .rounded)).opacity(0.72)
                    }
                    .padding(.horizontal, 16)
                }
                .buttonStyle(PrimaryButtonStyle(color: GameColors.yellow))
                .padding(.horizontal, 18)
                .padding(.top, 16)

                OverlayTextButton(title: "END RUN", icon: "xmark", action: finish)
                    .padding(.vertical, 14)
            }
            .foregroundColor(.white)
            .gameOverlayCard(tint: GameColors.yellow)
            .padding(.horizontal, 22)
        }
    }
}

private struct PauseOverlay: View {
    let configuration: RunConfiguration
    let snapshot: GameHUDSnapshot
    let resume: () -> Void
    let restart: () -> Void
    let exit: () -> Void

    var body: some View {
        ZStack {
            GameOverlayBackdrop(tint: GameColors.cyan)

            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(configuration.endless ? "ENDLESS RUN" : "\(configuration.world.name.uppercased())  •  LEVEL \(configuration.level)")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .foregroundColor(GameColors.cyan)
                        Text("GAME PAUSED")
                            .font(.system(size: 27, weight: .black, design: .rounded))
                    }
                    Spacer()
                    Image("ui_pause_button")
                        .resizable().scaledToFit().frame(width: 58, height: 58)
                        .shadow(color: GameColors.cyan.opacity(0.32), radius: 13, y: 7)
                }
                .padding(.horizontal, 22).padding(.top, 22)

                ZStack {
                    Circle().fill(GameColors.cyan.opacity(0.12)).frame(width: 190, height: 190).blur(radius: 16)
                    Image("platform_normal").resizable().scaledToFit().frame(width: 230).offset(y: 54)
                    Image("character_turkey_default")
                        .resizable().scaledToFit().frame(width: 170, height: 170)
                        .shadow(color: .black.opacity(0.34), radius: 10, y: 8).offset(y: -8)
                }
                .frame(height: 200)

                HStack(spacing: 0) {
                    OverlayStat(icon: "star.fill", title: "SCORE", value: snapshot.score.formatted(), tint: GameColors.yellow)
                    Divider().overlay(.white.opacity(0.12)).frame(height: 42)
                    OverlayStat(icon: "arrow.up", title: "HEIGHT", value: "\(snapshot.height)m", tint: GameColors.cyan)
                    Divider().overlay(.white.opacity(0.12)).frame(height: 42)
                    OverlayStat(icon: "circle.fill", title: "COINS", value: snapshot.coins.formatted(), tint: GameColors.yellow)
                }
                .padding(.vertical, 13)
                .background(.black.opacity(0.18))
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .padding(.horizontal, 18)

                Button(action: resume) {
                    Label("CONTINUE", systemImage: "play.fill")
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, 18).padding(.top, 16)

                HStack(spacing: 8) {
                    OverlayTextButton(title: "RESTART", icon: "arrow.clockwise", action: restart)
                    Rectangle().fill(.white.opacity(0.12)).frame(width: 1, height: 18)
                    OverlayTextButton(title: "EXIT RUN", icon: "house.fill", action: exit)
                }
                .padding(.vertical, 15)
            }
            .foregroundColor(.white)
            .gameOverlayCard(tint: GameColors.cyan)
            .padding(.horizontal, 22)
        }
    }
}

private struct ResultsOverlay: View {
    let result: RunResult
    let earnedFeathers: Int
    let primaryTitle: String
    let replay: () -> Void
    let exit: () -> Void

    var body: some View {
        ZStack {
            GameOverlayBackdrop(tint: result.completed ? GameColors.green : .orange)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Text(result.completed ? "ADVENTURE PROGRESS" : "RUN SUMMARY")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .tracking(1.6)
                        .foregroundColor(result.completed ? GameColors.green : .orange)
                        .padding(.top, 22)

                    ZStack {
                        Circle()
                            .fill((result.completed ? GameColors.green : Color.orange).opacity(0.14))
                            .frame(width: 195, height: 195).blur(radius: 15)
                        if result.completed {
                            Image("platform_finish").resizable().scaledToFit().frame(width: 235).offset(y: 50)
                            Image("treasure_chest_open")
                                .resizable().scaledToFit().frame(width: 145, height: 145).offset(y: -8)
                        } else {
                            Image("platform_rotten").resizable().scaledToFit().frame(width: 230).offset(y: 55)
                            Image("character_turkey_default")
                                .resizable().scaledToFit().frame(width: 155, height: 155).offset(y: -8)
                                .saturation(0.72)
                        }
                    }
                    .frame(height: 185)

                    Text(result.completed ? "LEVEL COMPLETE!" : "RUN OVER")
                        .font(.system(size: 30, weight: .black, design: .rounded))
                    Text(result.reason.uppercased())
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .tracking(0.8).foregroundColor(.white.opacity(0.52))
                        .padding(.top, 4)

                    if result.completed {
                        HStack(spacing: 9) {
                            ForEach(0..<3) { index in
                                ZStack {
                                    Circle()
                                        .fill(index < earnedFeathers ? GameColors.green.opacity(0.18) : .white.opacity(0.06))
                                        .frame(width: 43, height: 43)
                                    Image(systemName: index < earnedFeathers ? "leaf.fill" : "leaf")
                                        .font(.system(size: 20, weight: .black))
                                        .foregroundColor(index < earnedFeathers ? GameColors.green : .white.opacity(0.20))
                                }
                            }
                        }
                        .padding(.top, 12)
                        .accessibilityLabel("\(earnedFeathers) of 3 feathers earned")
                    }

                    VStack(spacing: 0) {
                        HStack(spacing: 0) {
                            OverlayStat(icon: "star.fill", title: "SCORE", value: result.score.formatted(), tint: GameColors.yellow)
                            Divider().overlay(.white.opacity(0.12)).frame(height: 42)
                            OverlayStat(icon: "arrow.up", title: "HEIGHT", value: "\(result.height)m", tint: GameColors.cyan)
                            Divider().overlay(.white.opacity(0.12)).frame(height: 42)
                            OverlayStat(icon: "circle.fill", title: "COINS", value: "+\(result.coins)", tint: GameColors.yellow)
                        }
                        .padding(.vertical, 13)

                        Rectangle().fill(.white.opacity(0.10)).frame(height: 1).padding(.horizontal, 14)

                        HStack(spacing: 0) {
                            OverlayStat(icon: "scope", title: "PERFECT", value: result.perfects.formatted(), tint: GameColors.green)
                            Divider().overlay(.white.opacity(0.12)).frame(height: 42)
                            OverlayStat(icon: "bolt.fill", title: "BEST COMBO", value: "×\(result.maxCombo)", tint: .orange)
                            if result.chestsOpened > 0 {
                                Divider().overlay(.white.opacity(0.12)).frame(height: 42)
                                OverlayStat(icon: "shippingbox.fill", title: "CHESTS", value: result.chestsOpened.formatted(), tint: .purple)
                            }
                        }
                        .padding(.vertical, 13)
                    }
                    .background(.black.opacity(0.18))
                    .clipShape(RoundedRectangle(cornerRadius: 19))
                    .padding(.horizontal, 18).padding(.top, 15)

                    Button(action: replay) {
                        HStack {
                            Image(systemName: primaryTitle == "NEXT LEVEL" ? "arrow.up.right" : "arrow.clockwise")
                            Text(primaryTitle)
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle(color: result.completed ? GameColors.green : .orange))
                    .padding(.horizontal, 18).padding(.top, 16)

                    OverlayTextButton(title: "BACK TO HOME", icon: "house.fill", action: exit)
                        .padding(.vertical, 14)
                }
                .foregroundColor(.white)
                .gameOverlayCard(tint: result.completed ? GameColors.green : .orange)
                .padding(.horizontal, 18)
                .padding(.vertical, 26)
            }
        }
    }
}

private struct OverlayStat: View {
    let icon: String
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 8, weight: .black)).foregroundColor(tint)
                Text(title).font(.system(size: 8, weight: .black, design: .rounded)).foregroundColor(.white.opacity(0.48))
            }
            Text(value).font(.system(size: 17, weight: .black, design: .rounded)).monospacedDigit()
        }
        .frame(maxWidth: .infinity)
    }
}

private struct OverlayTextButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundColor(.white.opacity(0.66))
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct GameOverlayBackdrop: View {
    let tint: Color

    var body: some View {
        ZStack {
            Color.black.opacity(0.64)
            Rectangle().fill(.ultraThinMaterial.opacity(0.50))
            Circle().fill(tint.opacity(0.18)).frame(width: 350, height: 350).blur(radius: 70).offset(y: -270)
            Circle().fill(GameColors.cyan.opacity(0.08)).frame(width: 280, height: 280).blur(radius: 70).offset(x: -180, y: 360)
        }
        .ignoresSafeArea()
    }
}

private struct GameOverlayCardModifier: ViewModifier {
    let tint: Color

    func body(content: Content) -> some View {
        content
            .background(
                LinearGradient(
                    colors: [GameColors.panelLight.opacity(0.97), GameColors.background.opacity(0.985)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .stroke(LinearGradient(colors: [tint.opacity(0.62), .white.opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.2)
            )
            .shadow(color: tint.opacity(0.15), radius: 28, y: 12)
            .shadow(color: .black.opacity(0.50), radius: 35, y: 22)
    }
}

private extension View {
    func gameOverlayCard(tint: Color) -> some View {
        modifier(GameOverlayCardModifier(tint: tint))
    }
}
