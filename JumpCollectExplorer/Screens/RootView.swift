import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: GameStore

    var body: some View {
        ZStack {
            PremiumBackground()

            switch store.launchState {
            case .loading:
                LoadingView()
                    .transition(.opacity)
            case .onboarding:
                OnboardingView()
                    .transition(.opacity.combined(with: .scale(scale: 1.02)))
            case .ready:
                MainShellView()
                    .transition(.opacity)
            }

            if let message = store.toast {
                VStack {
                    Spacer()
                    Text(message)
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .background(.black.opacity(0.86))
                        .clipShape(Capsule())
                        .padding(.bottom, 94)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .animation(.spring(), value: message)
            }
        }
        .environment(\.soundEffectsEnabled, store.save.soundEnabled)
        .fullScreenCover(item: $store.activeRun) { run in
            GameContainerView(configuration: run, showTutorial: !store.save.gameplayTutorialCompleted)
                .environmentObject(store)
        }
        .fullScreenCover(isPresented: $store.showingSettings) {
            NavigationStack { SettingsView() }
                .environmentObject(store)
        }
        .fullScreenCover(isPresented: $store.showingStatistics) {
            NavigationStack { StatisticsView() }
                .environmentObject(store)
        }
        .fullScreenCover(isPresented: $store.showingDailyReward) {
            DailyRewardView()
                .environmentObject(store)
        }
        .fullScreenCover(item: $store.levelPickerWorld) { world in
            NavigationStack { LevelPickerView(world: world) }
                .environmentObject(store)
        }
        .fullScreenCover(item: $store.pendingRun) { run in
            LevelPreparationView(configuration: run)
                .environmentObject(store)
        }
    }
}

struct MainShellView: View {
    @EnvironmentObject private var store: GameStore

    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch store.selectedRoute {
                case .home: HomeView()
                case .worlds: WorldsView()
                case .missions: MissionsView()
                case .collection: CharacterCollectionView()
                case .shop: ShopView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            HStack(spacing: 0) {
                ForEach(AppRoute.allCases) { route in
                    Button {
                        withAnimation(.easeOut(duration: 0.18)) { store.selectedRoute = route }
                    } label: {
                        VStack(spacing: 4) {
                            Image(tabArtwork(route)).resizable().scaledToFit().frame(width: 30, height: 30)
                                .saturation(store.selectedRoute == route ? 1 : 0.35)
                                .opacity(store.selectedRoute == route ? 1 : 0.62)
                            Text(route.title).font(.system(size: 10, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(store.selectedRoute == route ? GameColors.green : .white.opacity(0.55))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 6)
            .background(.ultraThinMaterial.opacity(0.94))
            .overlay(alignment: .top) { Rectangle().fill(LinearGradient(colors: [.white.opacity(0.16), .clear], startPoint: .leading, endPoint: .trailing)).frame(height: 1) }
        }
        .ignoresSafeArea(.keyboard)
    }

    private func tabArtwork(_ route: AppRoute) -> String {
        switch route {
        case .home: return "character_turkey_default"
        case .worlds: return "platform_normal"
        case .missions: return "daily_gift"
        case .collection: return "character_explorer"
        case .shop: return "coin"
        }
    }
}
