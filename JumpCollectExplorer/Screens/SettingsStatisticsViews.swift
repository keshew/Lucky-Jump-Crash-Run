import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss
    @State private var showingResetConfirmation = false

    var body: some View {
        ZStack {
            ArtworkBackground(name: "background_night_forest", overlay: 0.70)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    settingsHeader
                    profileHero

                    PremiumSettingsSection(
                        title: "AUDIO & FEEDBACK",
                        subtitle: "Shape the atmosphere",
                        artwork: "powerup_golden_egg"
                    ) {
                        SettingsToggleRow(icon: "music.note", title: "Music", subtitle: "Adventure soundtrack", tint: .purple, isOn: binding(\.musicEnabled))
                        SettingsDivider()
                        SettingsToggleRow(icon: "speaker.wave.2.fill", title: "Sound Effects", subtitle: "Jumps, coins and hazards", tint: GameColors.cyan, isOn: binding(\.soundEnabled))
                        SettingsDivider()
                        SettingsToggleRow(icon: "iphone.radiowaves.left.and.right", title: "Haptics", subtitle: "Physical landing feedback", tint: GameColors.green, isOn: binding(\.hapticsEnabled))
                    }

                    PremiumSettingsSection(
                        title: "GAMEPLAY",
                        subtitle: "Tune the way Tommy moves",
                        artwork: "powerup_wings"
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 12) {
                                SettingsIcon(symbol: "move.3d", tint: GameColors.green)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Control Sensitivity").font(.system(size: 15, weight: .bold, design: .rounded))
                                    Text("\(Int(store.save.controlSensitivity * 100))% response")
                                        .font(.system(size: 10, weight: .bold, design: .rounded))
                                        .foregroundColor(.white.opacity(0.50))
                                }
                                Spacer()
                            }

                            Slider(value: binding(\.controlSensitivity), in: 0.7...1.4, step: 0.1)
                                .tint(GameColors.green)

                            HStack {
                                Text("STEADY")
                                Spacer()
                                Text("RESPONSIVE")
                            }
                            .font(.system(size: 8, weight: .black, design: .rounded))
                            .foregroundColor(.white.opacity(0.36))
                        }

                        SettingsDivider()
                        SettingsToggleRow(icon: "waveform.path", title: "Camera Shake", subtitle: "Impact during hazards", tint: .orange, isOn: binding(\.cameraShake))
                        SettingsDivider()
                        SettingsToggleRow(icon: "sparkles", title: "Reduced Effects", subtitle: "Calmer visual experience", tint: .pink, isOn: binding(\.reducedEffects))

                        Button {
                            store.save.onboardingCompleted = false
                            store.persist()
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                store.launchState = .onboarding
                            }
                        } label: {
                            SettingsActionRow(icon: "arrow.counterclockwise", title: "Replay Onboarding", subtitle: "View the introduction again", tint: GameColors.cyan, accessory: "play.fill")
                        }
                        .buttonStyle(.plain)
                    }

                    PremiumSettingsSection(
                        title: "PRIVACY & DATA",
                        subtitle: "Everything stays on your device",
                        artwork: "powerup_shield"
                    ) {
                        NavigationLink {
                            PrivacyDataView()
                        } label: {
                            SettingsActionRow(icon: "hand.raised.fill", title: "Privacy & Data", subtitle: "Storage and data details", tint: GameColors.cyan, accessory: "chevron.right")
                        }
                        .buttonStyle(.plain)

                        SettingsDivider()

                        Button { showingResetConfirmation = true } label: {
                            SettingsActionRow(icon: "trash.fill", title: "Reset Progress", subtitle: "Erase campaign and records", tint: .red, accessory: "chevron.right")
                        }
                        .buttonStyle(.plain)
                    }

                    Text("LUCKY JUMP: CRASH RUN  •  VERSION 1.0 (1)")
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .tracking(0.8)
                        .foregroundColor(.white.opacity(0.36))
                        .padding(.vertical, 8)
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .alert("Reset all progress?", isPresented: $showingResetConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) { store.resetProgress() }
        } message: {
            Text("Coins, levels, characters and records will be permanently removed.")
        }
    }

    private var settingsHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("SETTINGS")
                    .font(.system(size: 30, weight: .black, design: .rounded))
                Text("Make the adventure yours")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.62))
            }
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .black))
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial.opacity(0.86))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(.white.opacity(0.18), lineWidth: 1))
            }
            .foregroundColor(.white)
        }
    }

    private var profileHero: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 7) {
                Text("ADVENTURE PROFILE")
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .tracking(1.1)
                    .foregroundColor(GameColors.green)
                Text("Ready for the\nnext jump")
                    .font(.system(size: 23, weight: .black, design: .rounded))
                HStack(spacing: 6) {
                    Label("LEVEL \(store.save.level)", systemImage: "star.fill")
                    Text("•")
                    Text("LOCAL SAVE")
                }
                .font(.system(size: 9, weight: .black, design: .rounded))
                .foregroundColor(.white.opacity(0.58))
            }
            .padding(.leading, 20)

            Spacer(minLength: 0)

            ZStack {
                Circle().fill(GameColors.green.opacity(0.15)).frame(width: 130, height: 130).blur(radius: 10)
                Image("character_explorer")
                    .resizable().scaledToFit().frame(width: 150, height: 150)
                    .shadow(color: .black.opacity(0.35), radius: 12, y: 8)
                    .offset(y: 8)
            }
            .frame(width: 154, height: 154)
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(colors: [GameColors.panelLight.opacity(0.88), GameColors.panel.opacity(0.96)], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 28).stroke(LinearGradient(colors: [.white.opacity(0.26), .white.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1))
        .shadow(color: .black.opacity(0.28), radius: 18, y: 10)
    }

    private func binding<T>(_ path: WritableKeyPath<PlayerSave, T>) -> Binding<T> {
        Binding(
            get: { store.save[keyPath: path] },
            set: { store.save[keyPath: path] = $0; store.persist() }
        )
    }
}

private struct PremiumSettingsSection<Content: View>: View {
    let title: String
    let subtitle: String
    let artwork: String
    let content: Content

    init(title: String, subtitle: String, artwork: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.artwork = artwork
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(spacing: 11) {
                Image(artwork).resizable().scaledToFit().frame(width: 42, height: 42)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.system(size: 12, weight: .black, design: .rounded)).tracking(0.8)
                    Text(subtitle).font(.system(size: 10, weight: .medium, design: .rounded)).foregroundColor(.white.opacity(0.48))
                }
                Spacer()
            }
            content
        }
        .foregroundColor(.white)
        .padding(17)
        .background(.ultraThinMaterial.opacity(0.78))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(LinearGradient(colors: [.white.opacity(0.22), .white.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1))
        .shadow(color: .black.opacity(0.24), radius: 16, y: 9)
    }
}

private struct SettingsToggleRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let tint: Color
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: 12) {
                SettingsIcon(symbol: icon, tint: tint)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.system(size: 14, weight: .bold, design: .rounded))
                    Text(subtitle).font(.system(size: 10, weight: .medium, design: .rounded)).foregroundColor(.white.opacity(0.46))
                }
            }
        }
        .toggleStyle(SwitchToggleStyle(tint: GameColors.green))
    }
}

private struct SettingsActionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let tint: Color
    let accessory: String

    var body: some View {
        HStack(spacing: 12) {
            SettingsIcon(symbol: icon, tint: tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 14, weight: .bold, design: .rounded))
                Text(subtitle).font(.system(size: 10, weight: .medium, design: .rounded)).foregroundColor(.white.opacity(0.46))
            }
            Spacer()
            Image(systemName: accessory).font(.system(size: 12, weight: .black)).foregroundColor(tint.opacity(0.9))
        }
        .foregroundColor(.white)
        .contentShape(Rectangle())
    }
}

private struct SettingsIcon: View {
    let symbol: String
    let tint: Color

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 15, weight: .bold))
            .foregroundColor(tint)
            .frame(width: 38, height: 38)
            .background(tint.opacity(0.13))
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct SettingsDivider: View {
    var body: some View {
        Rectangle().fill(.white.opacity(0.09)).frame(height: 1).padding(.leading, 50)
    }
}

private struct PrivacyDataView: View {
    var body: some View {
        ZStack {
            ArtworkBackground(name: "background_night_forest", overlay: 0.82)
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    Image("powerup_shield")
                        .resizable().scaledToFit().frame(height: 150)
                        .shadow(color: GameColors.cyan.opacity(0.28), radius: 18, y: 10)
                    Text("YOUR DATA IS YOURS")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                    Text("Lucky Jump: Crash Run works without an account and keeps gameplay data on this device.")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.65))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 14)

                    PrivacyCard(icon: "internaldrive.fill", title: "LOCAL PROGRESS", text: "Settings, unlocked characters, campaign progress and records are stored locally on this device.")
                    PrivacyCard(icon: "wifi.slash", title: "NO TRACKING", text: "This version contains no advertising SDK, tracking SDK or external analytics service.")
                    PrivacyCard(icon: "airplane", title: "OFFLINE READY", text: "Gameplay and campaign progress remain available without an internet connection.")
                    PrivacyCard(icon: "trash.fill", title: "REMOVE DATA", text: "Use Reset Progress in Settings to permanently remove locally stored game progress.", tint: .red)
                }
                .foregroundColor(.white)
                .padding(18)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("Privacy & Data")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

private struct PrivacyCard: View {
    let icon: String
    let title: String
    let text: String
    var tint: Color = GameColors.cyan

    var body: some View {
        HStack(alignment: .top, spacing: 13) {
            SettingsIcon(symbol: icon, tint: tint)
            VStack(alignment: .leading, spacing: 5) {
                Text(title).font(.system(size: 11, weight: .black, design: .rounded)).foregroundColor(tint)
                Text(text).font(.system(size: 12, weight: .medium, design: .rounded)).foregroundColor(.white.opacity(0.66))
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.ultraThinMaterial.opacity(0.76))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.13), lineWidth: 1))
    }
}

struct StatisticsView: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss
    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ZStack {
            ArtworkBackground(name: "background_sky_gardens", overlay: 0.74)
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("STATISTICS").font(.system(size: 30, weight: .black, design: .rounded))
                            Text("Your adventure in numbers").font(.system(size: 12, design: .rounded)).foregroundColor(.white.opacity(0.62))
                        }
                        Spacer()
                        Button { dismiss() } label: {
                            Image(systemName: "xmark").font(.system(size: 15, weight: .black)).frame(width: 44, height: 44)
                                .background(.ultraThinMaterial.opacity(0.86)).clipShape(Circle())
                        }
                    }

                    Image("character_turkey_default")
                        .resizable().scaledToFit().frame(height: 180)
                        .shadow(color: .black.opacity(0.32), radius: 14, y: 9)

                    LazyVGrid(columns: columns, spacing: 12) {
                        StatMetricCard(label: "BEST HEIGHT", value: "\(store.save.bestHeight) m", icon: "arrow.up", tint: GameColors.cyan)
                        StatMetricCard(label: "BEST SCORE", value: store.save.bestScore.formatted(), icon: "star.fill", tint: GameColors.yellow)
                        StatMetricCard(label: "GAMES PLAYED", value: store.save.gamesPlayed.formatted(), icon: "gamecontroller.fill", tint: .purple)
                        StatMetricCard(label: "TOTAL JUMPS", value: store.save.totalJumps.formatted(), icon: "arrow.up.forward", tint: GameColors.green)
                        StatMetricCard(label: "PERFECT LANDINGS", value: store.save.totalPerfects.formatted(), icon: "scope", tint: .orange)
                        StatMetricCard(label: "COINS COLLECTED", value: store.save.totalCoinsCollected.formatted(), icon: "circle.fill", tint: GameColors.yellow)
                        StatMetricCard(label: "CHESTS OPENED", value: (store.save.totalChestsOpened ?? 0).formatted(), icon: "shippingbox.fill", tint: .pink)
                        StatMetricCard(label: "FEATHERS", value: store.featherCount.formatted(), icon: "leaf.fill", tint: GameColors.green)
                    }
                }
                .foregroundColor(.white)
                .padding(18)
                .padding(.bottom, 28)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

private struct StatMetricCard: View {
    let label: String
    let value: String
    let icon: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SettingsIcon(symbol: icon, tint: tint)
            Text(value).font(.system(size: 22, weight: .black, design: .rounded)).minimumScaleFactor(0.7).lineLimit(1)
            Text(label).font(.system(size: 9, weight: .black, design: .rounded)).foregroundColor(.white.opacity(0.50))
        }
        .frame(maxWidth: .infinity, minHeight: 122, alignment: .leading)
        .padding(15)
        .background(.ultraThinMaterial.opacity(0.78))
        .clipShape(RoundedRectangle(cornerRadius: 21))
        .overlay(RoundedRectangle(cornerRadius: 21).stroke(.white.opacity(0.14), lineWidth: 1))
    }
}
