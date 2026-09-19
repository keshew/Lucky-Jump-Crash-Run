import SwiftUI

enum GameColors {
    static let background = Color(red: 0.025, green: 0.055, blue: 0.10)
    static let backgroundTop = Color(red: 0.055, green: 0.15, blue: 0.24)
    static let panel = Color(red: 0.055, green: 0.12, blue: 0.18)
    static let panelLight = Color(red: 0.10, green: 0.21, blue: 0.29)
    static let green = Color(red: 0.36, green: 0.91, blue: 0.39)
    static let greenDark = Color(red: 0.10, green: 0.61, blue: 0.31)
    static let yellow = Color(red: 1.0, green: 0.78, blue: 0.24)
    static let cyan = Color(red: 0.32, green: 0.83, blue: 1.0)
}

struct PremiumBackground: View {
    var accent: Color = .cyan
    var body: some View {
        ZStack {
            LinearGradient(colors: [GameColors.backgroundTop, GameColors.background], startPoint: .topLeading, endPoint: .bottomTrailing)
            Circle().fill(accent.opacity(0.14)).frame(width: 360, height: 360).blur(radius: 45).offset(x: 170, y: -330)
            Circle().fill(GameColors.green.opacity(0.08)).frame(width: 300, height: 300).blur(radius: 55).offset(x: -190, y: 390)
        }
        .ignoresSafeArea()
    }
}

struct ArtworkBackground: View {
    let name: String
    var overlay: Double = 0.48

    var body: some View {
        GeometryReader { proxy in
            Image(name)
                .resizable()
                .scaledToFill()
                .frame(width: proxy.size.width, height: proxy.size.height)
                .clipped()
                .overlay(
                    LinearGradient(
                        colors: [.black.opacity(0.16), GameColors.background.opacity(overlay), GameColors.background.opacity(0.94)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
        .ignoresSafeArea()
    }
}

struct ArtworkTile: View {
    let name: String
    var height: CGFloat = 150

    var body: some View {
        Image(name)
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .shadow(color: .black.opacity(0.35), radius: 14, y: 10)
    }
}

func worldBackgroundAsset(_ id: String) -> String {
    switch id {
    case "ice": return "background_frozen_peaks"
    case "fire": return "background_fire_archipelago"
    case "night": return "background_night_forest"
    default: return "background_sky_gardens"
    }
}

func characterAsset(_ id: String) -> String {
    switch id {
    case "pirate": return "character_pirate"
    case "explorer": return "character_explorer"
    default: return "character_turkey_default"
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.soundEffectsEnabled) private var soundEffectsEnabled
    var color: Color = GameColors.green

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 19, weight: .black, design: .rounded))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [color.opacity(configuration.isPressed ? 0.78 : 1), color == GameColors.green ? GameColors.greenDark : color.opacity(0.72)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(alignment: .top) {
                RoundedRectangle(cornerRadius: 18).stroke(.white.opacity(0.32), lineWidth: 1)
                    .padding(1)
            }
            .shadow(color: color.opacity(0.32), radius: 16, y: 8)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { isPressed in
                if isPressed && soundEffectsEnabled {
                    SoundEffectPlayer.shared.play("sfx_ui_tap.wav", volume: 0.42)
                }
            }
    }
}

struct PanelModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(
                LinearGradient(colors: [GameColors.panelLight.opacity(0.92), GameColors.panel.opacity(0.96)], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(LinearGradient(colors: [.white.opacity(0.20), .white.opacity(0.04)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1))
            .shadow(color: .black.opacity(0.28), radius: 18, y: 10)
    }
}

extension View {
    func gamePanel() -> some View { modifier(PanelModifier()) }
}

struct CoinBadge: View {
    let value: Int
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "circle.fill").foregroundColor(GameColors.yellow)
            Text(value.formatted()).fontWeight(.bold)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial.opacity(0.82))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.14), lineWidth: 1))
    }
}

struct GlassIconButton: View {
    @Environment(\.soundEffectsEnabled) private var soundEffectsEnabled
    let icon: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .black))
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial.opacity(0.85))
                .clipShape(Circle())
                .overlay(Circle().stroke(.white.opacity(0.18), lineWidth: 1))
                .shadow(color: .black.opacity(0.24), radius: 10, y: 6)
        }
        .foregroundColor(.white)
        .simultaneousGesture(TapGesture().onEnded {
            if soundEffectsEnabled {
                SoundEffectPlayer.shared.play("sfx_ui_tap.wav", volume: 0.42)
            }
        })
    }
}

struct MetricChip: View {
    let icon: String
    let label: String
    let value: String
    let tint: Color
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon).font(.system(size: 13, weight: .black)).foregroundColor(tint)
            VStack(alignment: .leading, spacing: 0) {
                Text(label).font(.system(size: 8, weight: .black, design: .rounded)).foregroundColor(.white.opacity(0.52)).tracking(0.6)
                Text(value).font(.system(size: 14, weight: .black, design: .rounded)).monospacedDigit()
            }
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial.opacity(0.78))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.14), lineWidth: 1))
        .shadow(color: .black.opacity(0.18), radius: 8, y: 5)
    }
}
