import Foundation

struct FlexibleGenerator: RandomNumberGenerator, Sendable {
    private var generator: SeededGenerator

    init(seed: UInt64?) {
        if let seed { generator = SeededGenerator(seed: seed) }
        else {
            var system = SystemRandomNumberGenerator()
            generator = SeededGenerator(seed: system.next())
        }
    }

    mutating func next() -> UInt64 {
        return generator.next()
    }
}

struct SeededGenerator: RandomNumberGenerator, Sendable {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed != 0 ? seed : 0x9e3779b97f4a7c15
    }

    mutating func next() -> UInt64 {
        state &+= 0x9e3779b97f4a7c15
        var z = state
        z = (z ^ (z >> 30)) &* 0xbf58476d1ce4e5b9
        z = (z ^ (z >> 27)) &* 0x94d049bb133111eb
        return z ^ (z >> 31)
    }
}

extension RandomNumberGenerator {
    mutating func nextUniform() -> Double {
        Double(next()) / Double(UInt64.max)
    }

    mutating func nextGaussian(mean: Double = 0, sigma: Double = 1) -> Double {
        var u1: Double = 0
        var u2: Double = 0
        repeat {
            u1 = nextUniform()
        } while u1 <= .leastNonzeroMagnitude
        u2 = nextUniform()
        let z0 = sqrt(-2.0 * log(u1)) * cos(2.0 * Double.pi * u2)
        return z0 * sigma + mean
    }

    mutating func sampleExponential(scale: Double) -> Double {
        let u = max(nextUniform(), 1e-12)
        return -scale * log(1 - u)
    }
}
