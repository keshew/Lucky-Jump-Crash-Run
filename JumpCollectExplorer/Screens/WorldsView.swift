import SwiftUI

struct WorldsView: View {
    @EnvironmentObject private var store: GameStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ScreenHeader(title: "Worlds", subtitle: "Choose your next adventure")

                ForEach(GameWorld.all) { world in
                    let unlocked = store.isWorldUnlocked(world)
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(spacing: 16) {
                            ZStack {
                                Image(worldBackgroundAsset(world.id)).resizable().scaledToFill().frame(width: 96, height: 96).clipShape(RoundedRectangle(cornerRadius: 20))
                                LinearGradient(colors: [.clear, .black.opacity(0.55)], startPoint: .top, endPoint: .bottom).clipShape(RoundedRectangle(cornerRadius: 20))
                                Image(systemName: world.symbol).font(.system(size: 31, weight: .bold)).foregroundColor(.white).shadow(radius: 8)
                            }
                            .frame(width: 96, height: 96)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(world.name).font(.system(size: 21, weight: .black, design: .rounded))
                                Text(world.subtitle).font(.system(size: 13, design: .rounded)).foregroundColor(.white.opacity(0.62))
                                Text(world.mechanic).font(.system(size: 12, weight: .bold, design: .rounded)).foregroundColor(world.color)
                            }
                        }

                        if unlocked {
                            Button {
                                store.selectedWorld = world
                                store.levelPickerWorld = world
                            } label: {
                                Text("VIEW 20 LEVELS")
                            }
                            .buttonStyle(PrimaryButtonStyle(color: world.color))
                        } else {
                            HStack {
                                Image(systemName: "lock.fill")
                                Text("\(store.featherCount) / \(world.requiredFeathers) feathers")
                                Spacer()
                            }
                            .font(.system(.subheadline, design: .rounded, weight: .bold))
                            .foregroundColor(.white.opacity(0.55))
                        }
                    }
                    .gamePanel()
                }
            }
            .padding(18)
        }
        .background(ArtworkBackground(name: "background_sky_gardens", overlay: 0.72))
    }
}

struct LevelPickerView: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss
    let world: GameWorld
    private let columns = [GridItem(.adaptive(minimum: 68), spacing: 12)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 15) {
                    Image(worldBackgroundAsset(world.id)).resizable().scaledToFill()
                        .frame(width: 82, height: 82)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(world.name).font(.system(size: 24, weight: .black, design: .rounded))
                        Text(world.mechanic).font(.system(.subheadline, design: .rounded)).foregroundColor(.secondary)
                    }
                }

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(1...20, id: \.self) { level in
                        let unlocked = store.isLevelUnlocked(level, in: world)
                        let feathers = store.save.completedLevels["\(world.id)-\(level)"] ?? 0
                        Button {
                            guard unlocked else { return }
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                store.prepareLevel(world: world, level: level)
                            }
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: unlocked ? "\(level).circle.fill" : "lock.fill")
                                    .font(.system(size: 28, weight: .bold))
                                HStack(spacing: 2) {
                                    ForEach(0..<3) { index in
                                        Image(systemName: index < feathers ? "leaf.fill" : "leaf")
                                    }
                                }
                                .font(.system(size: 9, weight: .bold))
                            }
                            .foregroundColor(unlocked ? world.color : .gray)
                            .frame(maxWidth: .infinity)
                            .frame(height: 82)
                            .background(GameColors.panel)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .disabled(!unlocked)
                    }
                }
            }
            .padding(18)
        }
        .background(ArtworkBackground(name: worldBackgroundAsset(world.id), overlay: 0.76))
        .navigationTitle("Select Level")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Done") { dismiss() } } }
    }
}

struct ScreenHeader: View {
    let title: String
    let subtitle: String
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.system(size: 32, weight: .black, design: .rounded))
            Text(subtitle).font(.system(.subheadline, design: .rounded)).foregroundColor(.white.opacity(0.58))
        }
        .padding(.top, 8)
    }
}
