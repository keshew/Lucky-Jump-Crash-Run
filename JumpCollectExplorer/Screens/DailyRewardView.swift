import SwiftUI

struct DailyRewardView: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss
    private let rewards = [100, 150, 200, 250, 300, 400, 500]

    var body: some View {
        ZStack {
            ArtworkBackground(name: "background_sky_gardens", overlay: 0.78)
            VStack(spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("DAILY REWARD")
                        .font(.system(size: 27, weight: .black, design: .rounded))
                    Text("Return every day for a bigger prize")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.white.opacity(0.62))
                }
                Spacer()
                Button { dismiss() } label: { Image(systemName: "xmark.circle.fill").font(.title2) }
                    .foregroundColor(.white.opacity(0.55))
            }

            Image("daily_gift").resizable().scaledToFit().frame(height: 120).shadow(radius: 16)

            HStack(spacing: 7) {
                ForEach(rewards.indices, id: \.self) { index in
                    let completed = index < store.save.dailyRewardDay
                    let current = index == store.save.dailyRewardDay
                    VStack(spacing: 7) {
                        Text("DAY \(index + 1)").font(.system(size: 9, weight: .black, design: .rounded))
                        Image(completed ? "coin" : "daily_gift").resizable().scaledToFit().frame(height: 25)
                            .opacity(completed || current ? 1 : 0.35)
                        Text(rewards[index].formatted()).font(.system(size: 11, weight: .bold, design: .rounded))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(current ? GameColors.yellow.opacity(0.12) : .white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 13))
                }
            }

            Button {
                store.claimDailyReward()
                dismiss()
            } label: {
                Text(store.claimedDailyRewardToday ? "COME BACK TOMORROW" : "CLAIM \(rewards[store.save.dailyRewardDay % rewards.count]) COINS")
            }
            .buttonStyle(PrimaryButtonStyle(color: store.claimedDailyRewardToday ? .gray : GameColors.green))
            .disabled(store.claimedDailyRewardToday)
            }
            .padding(22)
        }
    }
}
