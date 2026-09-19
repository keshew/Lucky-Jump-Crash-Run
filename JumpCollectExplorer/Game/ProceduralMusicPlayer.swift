import AVFoundation

final class ProceduralMusicPlayer {
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private var prepared = false
    private var buffer: AVAudioPCMBuffer?
    private var currentWorldID = ""

    func start(worldID: String) {
        if currentWorldID != worldID || buffer == nil {
            currentWorldID = worldID
            buffer = makeBuffer(worldID: worldID)
        }
        guard !player.isPlaying, let buffer else { return }

        if !prepared {
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: buffer.format)
            engine.mainMixerNode.outputVolume = 0.18
            prepared = true
        }

        do {
            if !engine.isRunning { try engine.start() }
            player.scheduleBuffer(buffer, at: nil, options: .loops)
            player.play()
        } catch {
            player.stop()
        }
    }

    func stop() {
        player.stop()
        engine.pause()
    }

    private func makeBuffer(worldID: String) -> AVAudioPCMBuffer? {
        let sampleRate = 44_100.0
        let duration = 4.0
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
              let samples = buffer.floatChannelData?[0] else { return nil }
        buffer.frameLength = frameCount

        let notes: [Double]
        switch worldID {
        case "ice": notes = [293.66, 369.99, 440.00, 369.99]
        case "fire": notes = [146.83, 174.61, 220.00, 196.00]
        case "night": notes = [220.00, 261.63, 329.63, 246.94]
        default: notes = [261.63, 329.63, 392.00, 329.63]
        }

        for frame in 0..<Int(frameCount) {
            let time = Double(frame) / sampleRate
            let segment = min(notes.count - 1, Int(time) % notes.count)
            let frequency = notes[segment]
            let phase = 2 * Double.pi * frequency * time
            let harmonic = sin(phase) * 0.050 + sin(phase * 0.5) * 0.028 + sin(phase * 2) * 0.012
            let pulse = 0.78 + 0.22 * sin(2 * Double.pi * 0.5 * time)
            samples[frame] = Float(harmonic * pulse)
        }
        return buffer
    }
}

