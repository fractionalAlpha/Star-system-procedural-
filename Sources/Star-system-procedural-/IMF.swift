import Foundation

struct InitialMassFunction {
    static func sampleMass<R: RandomNumberGenerator>(generator: inout R) -> Double {
        // Broken power-law Kroupa IMF approximation between 0.08 and 50 solar masses
        let u = generator.nextUniform()
        let mass: Double
        if u < 0.5 {
            mass = invertPowerLaw(u / 0.5, min: 0.08, max: 0.5, alpha: 1.3)
        } else if u < 0.9 {
            mass = invertPowerLaw((u - 0.5) / 0.4, min: 0.5, max: 1.0, alpha: 2.3)
        } else {
            mass = invertPowerLaw((u - 0.9) / 0.1, min: 1.0, max: 50.0, alpha: 2.7)
        }
        return mass
    }

    private static func invertPowerLaw(_ u: Double, min: Double, max: Double, alpha: Double) -> Double {
        let exponent = 1.0 - alpha
        let minTerm = pow(min, exponent)
        let maxTerm = pow(max, exponent)
        let value = minTerm + u * (maxTerm - minTerm)
        return pow(value, 1.0 / exponent)
    }
}
