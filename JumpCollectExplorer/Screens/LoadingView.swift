import SwiftUI

struct LoadingView: View {
    @State private var bouncing = false
    @State private var progress: CGFloat = 0.08

    var body: some View {
        ZStack {
            ArtworkBackground(name: "splash_key_art", overlay: 0.34)

            VStack(spacing: 26) {
                Spacer()

                Image("logo_jump_collect_explore")
                    .resizable().scaledToFit().frame(maxWidth: 330)
                    .shadow(color: .black.opacity(0.45), radius: 18, y: 10)
                    .offset(y: bouncing ? -8 : 8)

                Spacer()

                VStack(spacing: 12) {
                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            Capsule().fill(.white.opacity(0.13))
                            Capsule().fill(GameColors.green).frame(width: proxy.size.width * progress)
                        }
                    }
                    .frame(height: 10)

                    Text("Preparing your adventure...")
                        .font(.system(.footnote, design: .rounded, weight: .semibold))
                        .foregroundColor(.white.opacity(0.72))
                }
                .padding(.horizontal, 48)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true)) { bouncing = true }
            withAnimation(.easeInOut(duration: 1.25)) { progress = 1 }
        }
    }
}
