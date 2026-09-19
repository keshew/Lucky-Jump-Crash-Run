import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var store: GameStore
    @State private var page = 0

    private let pages: [(art: String, title: String, text: String, color: Color)] = [
        ("onboarding_steer", "Guide Every Jump", "Hold the left or right side of the screen to steer Tommy through the sky.", .cyan),
        ("onboarding_perfect", "Land with Precision", "Hit the center of an island for a Perfect landing. Build a combo to earn more coins.", GameColors.green),
        ("onboarding_routes", "Choose Your Route", "Avoid rotten islands, take risky paths and climb all the way to the finish.", .orange)
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button("Skip") { store.completeOnboarding() }
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
                    .padding()
            }

            TabView(selection: $page) {
                ForEach(pages.indices, id: \.self) { index in
                    VStack(spacing: 28) {
                        Spacer()

                        Image(pages[index].art).resizable().scaledToFit()
                            .frame(maxWidth: 350).frame(height: 350)
                            .shadow(color: pages[index].color.opacity(0.35), radius: 24, y: 14)

                        VStack(spacing: 14) {
                            Text(pages[index].title)
                                .font(.system(size: 30, weight: .black, design: .rounded))
                            Text(pages[index].text)
                                .font(.system(size: 17, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.72))
                                .multilineTextAlignment(.center)
                                .lineSpacing(5)
                                .padding(.horizontal, 34)
                        }

                        Spacer()
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            HStack(spacing: 9) {
                ForEach(pages.indices, id: \.self) { index in
                    Capsule()
                        .fill(index == page ? GameColors.green : .white.opacity(0.2))
                        .frame(width: index == page ? 28 : 9, height: 9)
                        .animation(.spring(), value: page)
                }
            }
            .padding(.bottom, 24)

            Button {
                if page < pages.count - 1 {
                    withAnimation { page += 1 }
                } else {
                    store.completeOnboarding()
                }
            } label: {
                Text(page == pages.count - 1 ? "START ADVENTURE" : "CONTINUE")
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
        .background(
            ArtworkBackground(name: "background_sky_gardens", overlay: 0.72)
        )
    }
}
