import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: GameStore

    private var selectedCharacter: GameCharacter {
        GameCharacter.all.first { $0.id == store.save.selectedCharacterID } ?? GameCharacter.all[0]
    }

    private var nextLevel: Int { store.nextLevel(in: store.selectedWorld) }

    var body: some View {
        ZStack {
            ArtworkBackground(name: worldBackgroundAsset(store.selectedWorld.id), overlay: 0.55)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    topBar.padding(.horizontal, 18)

                    featuredRun
                        .padding(.horizontal, 18)
                        .padding(.top, 16)

                    runModes
                        .padding(.horizontal, 18)
                        .padding(.top, 18)
                        .padding(.bottom, 24)
                }
                .padding(.top, 8)
            }
        }
    }

    private var topBar: some View {
        HStack(spacing: 10) {
            Button { store.showingStatistics = true } label: {
                HStack(spacing: 9) {
                    Image(characterAsset(selectedCharacter.id))
                        .resizable().scaledToFit()
                        .frame(width: 48, height: 48)
                        .background(Circle().fill(.white.opacity(0.12)))
                    VStack(alignment: .leading, spacing: 1) {
                        Text(selectedCharacter.name.uppercased())
                            .font(.system(size: 13, weight: .black, design: .rounded))
                        Text("PLAYER LEVEL \(store.save.level)")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.62))
                    }
                }
            }
            .foregroundColor(.white)

            Spacer(minLength: 5)

            HStack(spacing: 5) {
                Image("coin").resizable().scaledToFit().frame(width: 23, height: 23)
                Text(store.save.coins.formatted())
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .monospacedDigit()
            }
            .padding(.leading, 8).padding(.trailing, 12)
            .frame(height: 42)
            .background(.ultraThinMaterial.opacity(0.86))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(.white.opacity(0.20), lineWidth: 1))

            GlassIconButton(icon: "gearshape.fill") { store.showingSettings = true }
        }
    }

    private var featuredRun: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("CONTINUE JOURNEY")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .tracking(1.3).foregroundColor(GameColors.yellow)
                    Text(store.selectedWorld.name)
                        .font(.system(size: 24, weight: .black, design: .rounded))
                    Text("LEVEL \(nextLevel)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.64))
                }
                Spacer()
                VStack(spacing: 2) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 16, weight: .black)).foregroundColor(GameColors.green)
                    Text(store.availableRescueFeathers.formatted())
                        .font(.system(size: 13, weight: .black, design: .rounded))
                }
                .frame(width: 48, height: 48)
                .background(.black.opacity(0.24)).clipShape(Circle())
                .overlay(Circle().stroke(.white.opacity(0.14), lineWidth: 1))
            }
            .padding(.horizontal, 20).padding(.top, 19)

            ZStack {
                Circle()
                    .fill(store.selectedWorld.color.opacity(0.20))
                    .frame(width: 235, height: 235).blur(radius: 20)
                Image("platform_normal")
                    .resizable().scaledToFit().frame(width: 280).offset(y: 72)
                Image(characterAsset(selectedCharacter.id))
                    .resizable().scaledToFit().frame(width: 218, height: 218)
                    .shadow(color: .black.opacity(0.38), radius: 13, y: 10).offset(y: -6)
                VStack {
                    Spacer()
                    HStack(spacing: 6) {
                        ForEach(0..<5, id: \.self) { index in
                            Capsule()
                                .fill(index < min(nextLevel, 5) ? GameColors.green : .white.opacity(0.20))
                                .frame(width: index == min(nextLevel, 5) - 1 ? 26 : 9, height: 7)
                        }
                    }
                }
            }
            .frame(height: 255).padding(.horizontal, 12)

            Button { store.prepareLevel(level: nextLevel) } label: {
                HStack(spacing: 12) {
                    ZStack {
                        Circle().fill(.white.opacity(0.22)).frame(width: 38, height: 38)
                        Image(systemName: "play.fill").font(.system(size: 16, weight: .black))
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        Text("PLAY LEVEL \(nextLevel)")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                        Text("Jump, collect and climb higher")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.72))
                    }
                    Spacer()
                    Image(systemName: "chevron.right").font(.system(size: 16, weight: .black))
                }
                .padding(.horizontal, 16)
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(12)
        }
        .foregroundColor(.white)
        .background(LinearGradient(colors: [.black.opacity(0.15), GameColors.panel.opacity(0.90)], startPoint: .top, endPoint: .bottom))
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 30).stroke(LinearGradient(colors: [.white.opacity(0.36), .white.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.2))
        .shadow(color: .black.opacity(0.35), radius: 24, y: 16)
    }

    private var runModes: some View {
        VStack(spacing: 12) {
            HStack {
                Text("MORE WAYS TO PLAY")
                    .font(.system(size: 12, weight: .black, design: .rounded)).tracking(1.1)
                Spacer()
                Text("NEW REWARDS DAILY")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundColor(GameColors.yellow.opacity(0.9))
            }
            .foregroundColor(.white.opacity(0.78)).padding(.horizontal, 4)

            HStack(spacing: 12) {
                Button { store.prepareLevel(endless: true) } label: {
                    HomeModeCard(artwork: "character_explorer", eyebrow: "GO FOR A RECORD", title: "ENDLESS", detail: "BEST \(store.save.bestHeight)M", tint: .purple)
                }
                Button { store.showingDailyReward = true } label: {
                    HomeModeCard(artwork: "daily_gift", eyebrow: store.claimedDailyRewardToday ? "COME BACK TOMORROW" : "READY TO OPEN", title: "DAILY GIFT", detail: store.claimedDailyRewardToday ? "CLAIMED" : "CLAIM NOW", tint: GameColors.yellow)
                }
            }

            Button { store.prepareDailyChallenge() } label: {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 15).fill(GameColors.cyan.opacity(0.16)).frame(width: 56, height: 56)
                        Image("platform_checkpoint").resizable().scaledToFit().frame(width: 54, height: 54)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text("DAILY CHALLENGE").font(.system(size: 15, weight: .black, design: .rounded))
                        Text("One route. One day. Your best score.")
                            .font(.system(size: 11, weight: .medium, design: .rounded)).foregroundColor(.white.opacity(0.58))
                    }
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 15, weight: .black)).frame(width: 34, height: 34)
                        .background(.white.opacity(0.09)).clipShape(Circle())
                }
                .foregroundColor(.white).padding(13)
                .background(.ultraThinMaterial.opacity(0.84))
                .clipShape(RoundedRectangle(cornerRadius: 22))
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(.white.opacity(0.15), lineWidth: 1))
            }
        }
    }
}

private struct HomeModeCard: View {
    let artwork: String
    let eyebrow: String
    let title: String
    let detail: String
    let tint: Color

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(colors: [tint.opacity(0.24), GameColors.panel.opacity(0.95)], startPoint: .topLeading, endPoint: .bottomTrailing)
            Image(artwork)
                .resizable().scaledToFit().frame(width: 104, height: 104)
                .offset(x: 68, y: -48).opacity(0.94)
            VStack(alignment: .leading, spacing: 3) {
                Text(eyebrow)
                    .font(.system(size: 8, weight: .black, design: .rounded)).foregroundColor(tint)
                    .lineLimit(1).minimumScaleFactor(0.75)
                Text(title).font(.system(size: 15, weight: .black, design: .rounded))
                Text(detail)
                    .font(.system(size: 10, weight: .bold, design: .rounded)).foregroundColor(.white.opacity(0.58))
            }
            .padding(14)
        }
        .foregroundColor(.white).frame(maxWidth: .infinity).frame(height: 146)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(.white.opacity(0.15), lineWidth: 1))
        .shadow(color: .black.opacity(0.22), radius: 13, y: 8)
    }
}
