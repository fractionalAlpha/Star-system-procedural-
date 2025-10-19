import Foundation

public struct StellarEvolution {
    public static func mainSequenceLifetime(forMass mass: Double, metallicity: Double) -> Double {
        // Lifetime in Gyr, using a mass-metallicity scaling to mimic metallicity dependence
        let metallicityFactor = max(0.3, 1.0 - 0.2 * metallicity)
        return metallicityFactor * 10.0 * pow(mass, -2.5)
    }

    public static func luminosity(forMass mass: Double, evolutionaryStage: StellarStage) -> Double {
        switch evolutionaryStage {
        case .mainSequence:
            if mass < 0.43 {
                return 0.23 * pow(mass, 2.3)
            } else if mass < 2.0 {
                return pow(mass, 4.0)
            } else if mass < 20.0 {
                return 1.4 * pow(mass, 3.5)
            } else {
                return 32000.0 * mass
            }
        case .subGiant, .redGiant:
            return 50.0 * pow(mass, 2.0)
        case .whiteDwarf:
            return 0.01 * pow(mass, 2.0)
        case .neutronStar:
            return 0.0001
        }
    }

    public static func effectiveTemperature(forMass mass: Double, evolutionaryStage: StellarStage) -> Double {
        switch evolutionaryStage {
        case .mainSequence:
            if mass < 0.5 {
                return 3100 + 1500 * mass
            } else if mass < 1.5 {
                return 5200 + 1800 * (mass - 0.5)
            } else if mass < 3.0 {
                return 6800 + 1200 * (mass - 1.5)
            } else {
                return 8000 + 400 * (mass - 3.0)
            }
        case .subGiant:
            return 5200.0
        case .redGiant:
            return 4200.0
        case .whiteDwarf:
            return 8000.0
        case .neutronStar:
            return 1000000.0
        }
    }

    public static func radius(luminosity: Double, effectiveTemperature: Double) -> Double {
        let solarTemperature = 5778.0
        return sqrt(luminosity) * pow(solarTemperature / effectiveTemperature, 2.0)
    }

    public static func absoluteMagnitude(luminosity: Double) -> Double {
        let solarAbsoluteMagnitude = 4.83
        return solarAbsoluteMagnitude - 2.5 * log10(luminosity)
    }

    public static func spectralType(forTemperature temperature: Double) -> String {
        switch temperature {
        case ..<3500:
            return "M"
        case 3500..<5000:
            return "K"
        case 5000..<6000:
            return "G"
        case 6000..<7500:
            return "F"
        case 7500..<10000:
            return "A"
        case 10000..<30000:
            return "B"
        default:
            return "O"
        }
    }
}

public enum StellarStage: String, Codable, Sendable {
    case mainSequence
    case subGiant
    case redGiant
    case whiteDwarf
    case neutronStar
}
