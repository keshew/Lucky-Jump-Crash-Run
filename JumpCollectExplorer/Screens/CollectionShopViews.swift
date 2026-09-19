import SwiftUI

struct CharacterCollectionView: View {
    @EnvironmentObject private var store: GameStore
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ScreenHeader(title: "Collection", subtitle: "Choose your explorer")
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(GameCharacter.all) { character in
                        CharacterCard(character: character, isShop: false)
                    }
                }
            }
            .padding(18)
        }
        .background(ArtworkBackground(name: "background_night_forest", overlay: 0.78))
    }
}

struct ShopView: View {
    @EnvironmentObject private var store: GameStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .bottom) {
                    ScreenHeader(title: "Shop", subtitle: "Spend coins from your adventures")
                    Spacer()
                    CoinBadge(value: store.save.coins)
                }

                ForEach(GameCharacter.all.filter { $0.price > 0 }) { character in
                    CharacterCard(character: character, isShop: true)
                }
            }
            .padding(18)
        }
        .background(ArtworkBackground(name: "background_fire_archipelago", overlay: 0.82))
    }
}

private struct CharacterCard: View {
    @EnvironmentObject private var store: GameStore
    let character: GameCharacter
    let isShop: Bool

    private var unlocked: Bool { store.save.unlockedCharacterIDs.contains(character.id) }
    private var selected: Bool { store.save.selectedCharacterID == character.id }

    var body: some View {
        VStack(spacing: 13) {
            ZStack {
                Circle().fill(LinearGradient(colors: [character.color.opacity(0.40), .black.opacity(0.12)], startPoint: .top, endPoint: .bottom)).frame(width: isShop ? 124 : 104, height: isShop ? 124 : 104)
                Image(characterAsset(character.id))
                    .resizable().scaledToFit()
                    .frame(width: isShop ? 138 : 116, height: isShop ? 138 : 116)
                    .saturation(unlocked ? 1 : 0)
                    .opacity(unlocked ? 1 : 0.52)
                if !unlocked { Image(systemName: "lock.fill").foregroundColor(.white).offset(x: 28, y: 25) }
            }

            VStack(spacing: 3) {
                Text(character.name).font(.system(size: 16, weight: .black, design: .rounded))
                Text(unlocked ? (selected ? "Selected" : "Unlocked") : character.requirement)
                    .font(.system(size: 11, design: .rounded))
                    .foregroundColor(.white.opacity(0.58))
                    .multilineTextAlignment(.center)
            }

            Button {
                unlocked ? store.select(character) : store.buy(character)
            } label: {
                if unlocked {
                    Text(selected ? "SELECTED" : "SELECT")
                } else {
                    Label(character.price.formatted(), systemImage: "circle.fill")
                }
            }
            .font(.system(size: 12, weight: .black, design: .rounded))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(selected ? Color.gray.opacity(0.4) : character.color.opacity(0.8))
            .clipShape(RoundedRectangle(cornerRadius: 11))
            .disabled(selected)
        }
        .gamePanel()
    }
}
