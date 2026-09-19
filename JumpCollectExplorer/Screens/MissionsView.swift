import SwiftUI

struct MissionsView: View {
    @EnvironmentObject private var store: GameStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    ScreenHeader(title: "Missions", subtitle: "Complete goals and earn rewards")
                    Spacer()
                    Image("daily_gift").resizable().scaledToFit().frame(width: 92, height: 92).shadow(radius: 12)
                }

                ForEach(store.missions) { mission in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(mission.title).font(.system(size: 18, weight: .black, design: .rounded))
                                Text(mission.detail).font(.system(.subheadline, design: .rounded)).foregroundColor(.white.opacity(0.62))
                            }
                            Spacer()
                            Image("coin").resizable().scaledToFit().frame(width: 34, height: 34)
                            CoinBadge(value: mission.reward)
                        }

                        ProgressView(value: Double(mission.progress), total: Double(mission.target))
                            .tint(GameColors.green)
                        Text("\(mission.progress) / \(mission.target)")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.55))

                        if mission.progress >= mission.target {
                            Button {
                                store.claimMission(mission)
                            } label: {
                                Text(mission.claimed ? "REWARD CLAIMED" : "CLAIM +\(mission.reward) COINS")
                            }
                            .buttonStyle(PrimaryButtonStyle(color: mission.claimed ? .gray : GameColors.green))
                            .disabled(mission.claimed)
                        }
                    }
                    .gamePanel()
                }

                VStack(alignment: .leading, spacing: 12) {
                    Label("Achievements", systemImage: "trophy.fill")
                        .font(.system(size: 21, weight: .black, design: .rounded))
                        .foregroundColor(GameColors.yellow)
                    ForEach(store.achievements) { achievement in
                        AchievementRow(achievement: achievement) {
                            store.claimAchievement(achievement)
                        }
                    }
                }
                .gamePanel()
            }
            .padding(18)
        }
        .background(ArtworkBackground(name: "background_frozen_peaks", overlay: 0.82))
    }
}

private struct AchievementRow: View {
    let achievement: GameAchievement
    let claim: () -> Void
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: achievement.progress >= achievement.target ? "checkmark.seal.fill" : "circle.dashed")
                    .foregroundColor(achievement.progress >= achievement.target ? GameColors.green : .white.opacity(0.35))
                VStack(alignment: .leading, spacing: 2) {
                    Text(achievement.title).font(.system(.subheadline, design: .rounded, weight: .bold))
                    Text(achievement.detail).font(.system(size: 11, design: .rounded)).foregroundColor(.white.opacity(0.5))
                }
                Spacer()
                Text("\(achievement.progress)/\(achievement.target)").font(.caption.monospacedDigit()).foregroundColor(.white.opacity(0.55))
            }
            if achievement.progress >= achievement.target {
                Button(achievement.claimed ? "CLAIMED" : "CLAIM +\(achievement.reward)", action: claim)
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(achievement.claimed ? Color.gray.opacity(0.35) : GameColors.green.opacity(0.75))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .disabled(achievement.claimed)
            }
        }
        .padding(.vertical, 7)
    }
}
