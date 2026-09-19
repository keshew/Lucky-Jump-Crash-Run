import SwiftUI

struct LevelPreparationView: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss
    let configuration: RunConfiguration
    @State private var selectedBoost: StartBoost = .none

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill").font(.title2).foregroundColor(.white.opacity(0.55))
                    }
                    Spacer()
                    CoinBadge(value: store.save.coins)
                }

                ZStack(alignment: .bottom) {
                    Image("platform_normal").resizable().scaledToFit().frame(width: 310)
                    Image("character_turkey_default").resizable().scaledToFit().frame(width: 190, height: 190).offset(y: -42)
                }
                .frame(height: 220)

                VStack(spacing: 5) {
                    Text(configuration.dailyChallenge ? "DAILY CHALLENGE" : (configuration.endless ? "ENDLESS FLIGHT" : "LEVEL \(configuration.level)"))
                        .font(.system(size: 30, weight: .black, design: .rounded))
                    Text(configuration.world.name)
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .foregroundColor(.white.opacity(0.65))
                }

                if !configuration.endless {
                    let definition = LevelCatalog.definition(world: configuration.world, level: configuration.level)
                    VStack(alignment: .leading, spacing: 11) {
                        Text("OBJECTIVES").font(.system(size: 13, weight: .black, design: .rounded)).foregroundColor(.white.opacity(0.55))
                        ObjectiveRow(icon: "flag.checkered", text: "Reach \(configuration.targetHeight) meters", reward: "Required")
                        ObjectiveRow(icon: "scope", text: "Make \(definition.perfectTarget) perfect landings", reward: configuration.dailyChallenge ? "Bonus" : "+1 feather")
                        ObjectiveRow(icon: "circle.fill", text: "Collect \(definition.coinTarget) coins", reward: configuration.dailyChallenge ? "Bonus" : "+1 feather")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .gamePanel()
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("STARTING BOOST").font(.system(size: 13, weight: .black, design: .rounded)).foregroundColor(.white.opacity(0.55))
                    ForEach(StartBoost.allCases) { boost in
                        Button { selectedBoost = boost } label: {
                            HStack(spacing: 13) {
                                boostArtwork(boost)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(boost.title).font(.system(.subheadline, design: .rounded, weight: .bold))
                                    Text(boost.detail).font(.system(size: 11, design: .rounded)).foregroundColor(.white.opacity(0.52))
                                }
                                Spacer()
                                if boost.price > 0 {
                                    Text(boost.price.formatted()).font(.system(.subheadline, design: .rounded, weight: .black))
                                    Image(systemName: "circle.fill").font(.caption).foregroundColor(GameColors.yellow)
                                }
                                Image(systemName: selectedBoost == boost ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(selectedBoost == boost ? GameColors.green : .white.opacity(0.3))
                            }
                            .foregroundColor(.white)
                            .padding(12)
                            .background(selectedBoost == boost ? GameColors.green.opacity(0.10) : .white.opacity(0.035))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                }
                .gamePanel()

                Button {
                    guard store.save.coins >= selectedBoost.price else {
                        store.showToast("Not enough coins")
                        return
                    }
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
                        _ = store.startPreparedRun(configuration, boost: selectedBoost)
                    }
                } label: {
                    Text(selectedBoost.price == 0 ? "START LEVEL" : "START • \(selectedBoost.price) COINS")
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .padding(20)
        }
        .background(ArtworkBackground(name: worldBackgroundAsset(configuration.world.id), overlay: 0.80))
    }

    @ViewBuilder private func boostArtwork(_ boost: StartBoost) -> some View {
        let name: String? = boost == .shield ? "powerup_shield" : (boost == .wings ? "powerup_wings" : (boost == .goldenEgg ? "powerup_golden_egg" : nil))
        if let name {
            Image(name).resizable().scaledToFit().frame(width: 42, height: 42)
        } else {
            Image(systemName: boost.symbol).font(.system(size: 21, weight: .bold)).frame(width: 42).foregroundColor(.white.opacity(0.65))
        }
    }
}

private struct ObjectiveRow: View {
    let icon: String
    let text: String
    let reward: String
    var body: some View {
        HStack(spacing: 11) {
            Image(systemName: icon).foregroundColor(GameColors.green).frame(width: 24)
            Text(text).font(.system(.subheadline, design: .rounded, weight: .semibold))
            Spacer()
            Text(reward).font(.system(size: 11, weight: .bold, design: .rounded)).foregroundColor(.white.opacity(0.5))
        }
    }
}
