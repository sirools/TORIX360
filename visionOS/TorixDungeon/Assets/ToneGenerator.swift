import Foundation

/// Fabrique des sons placeholder (fichiers WAV) par synthèse, pour ne dépendre d'aucun asset.
/// À remplacer par de vrais sons (bundle ou NAS) plus tard.
enum ToneGenerator {
    static let sampleRate: Double = 44_100

    /// Petit carillon : les notes s'enchaînent en arpège et s'éteignent doucement.
    static func chime(notes: [Double], noteSpacing: Double = 0.09, duration: Double = 1.4) -> Data {
        let count = Int(duration * sampleRate)
        var samples = [Float](repeating: 0, count: count)
        for (index, frequency) in notes.enumerated() {
            let start = min(Int(Double(index) * noteSpacing * sampleRate), count)
            for n in start..<count {
                let t = Double(n - start) / sampleRate
                let attack = min(t / 0.004, 1)
                let envelope = attack * exp(-t * 4.0)
                let tone = sin(2 * .pi * frequency * t) + 0.25 * sin(2 * .pi * 2.01 * frequency * t)
                samples[n] += Float(envelope * tone)
            }
        }
        return wav(normalized(samples, peak: 0.7))
    }

    /// Bourdon grave qui boucle sans couture (les fréquences tombent juste sur la durée).
    static func drone(duration: Double = 8) -> Data {
        let count = Int(duration * sampleRate)
        var samples = [Float](repeating: 0, count: count)
        for n in 0..<count {
            let t = Double(n) / sampleRate
            let swell = 0.65 + 0.35 * sin(2 * .pi * 0.25 * t)   // 2 respirations sur 8 s
            let value = sin(2 * .pi * 55 * t)
                + 0.6 * sin(2 * .pi * 82.5 * t)
                + 0.25 * sin(2 * .pi * 110 * t + 0.7)
            samples[n] = Float(swell * value)
        }
        return wav(normalized(samples, peak: 0.45))
    }

    // MARK: - WAV PCM 16 bits mono

    private static func normalized(_ samples: [Float], peak: Float) -> [Float] {
        let maxValue = samples.map { abs($0) }.max() ?? 1
        guard maxValue > 0 else { return samples }
        let gain = peak / maxValue
        return samples.map { $0 * gain }
    }

    private static func wav(_ samples: [Float]) -> Data {
        let pcm: [Int16] = samples.map { Int16(max(-1, min(1, $0)) * Float(Int16.max)) }
        let dataSize = UInt32(pcm.count * 2)
        let rate = UInt32(sampleRate)

        var data = Data()
        func append<T: FixedWidthInteger>(_ value: T) {
            var littleEndian = value.littleEndian
            withUnsafeBytes(of: &littleEndian) { data.append(contentsOf: $0) }
        }
        data.append(contentsOf: Array("RIFF".utf8))
        append(UInt32(36) + dataSize)
        data.append(contentsOf: Array("WAVE".utf8))
        data.append(contentsOf: Array("fmt ".utf8))
        append(UInt32(16))          // taille du bloc fmt
        append(UInt16(1))           // PCM
        append(UInt16(1))           // mono
        append(rate)
        append(rate * 2)            // octets par seconde
        append(UInt16(2))           // octets par échantillon
        append(UInt16(16))          // bits par échantillon
        data.append(contentsOf: Array("data".utf8))
        append(dataSize)
        pcm.withUnsafeBufferPointer { buffer in
            data.append(contentsOf: UnsafeRawBufferPointer(buffer))
        }
        return data
    }
}
