import AVFoundation
import SwiftUI

private struct SoundEffectsEnabledKey: EnvironmentKey {
    static let defaultValue = true
}

extension EnvironmentValues {
    var soundEffectsEnabled: Bool {
        get { self[SoundEffectsEnabledKey.self] }
        set { self[SoundEffectsEnabledKey.self] = newValue }
    }
}

@MainActor
final class SoundEffectPlayer {
    static let shared = SoundEffectPlayer()
    private var players: [String: AVAudioPlayer] = [:]

    private init() {}

    func play(_ fileName: String, volume: Float = 0.5) {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: nil) else { return }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = volume
            player.prepareToPlay()
            players[fileName] = player
            player.play()
        } catch {
            assertionFailure("Unable to play sound effect: \(fileName)")
        }
    }
}
