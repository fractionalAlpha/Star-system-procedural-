import Foundation

enum GalacticComponent: String, CaseIterable, Codable, Sendable {
    case thinDisk
    case thickDisk
    case bulge
    case halo
    case globularCluster
}

struct GalacticRegionModel: Sendable {
    let baseNumberDensity: Double // stars per cubic parsec at solar radius
    let radialScaleLength: Double // kpc
    let verticalScaleHeight: Double // pc
    let ageRange: ClosedRange<Double> // Gyr
    let metallicityMean: Double
    let metallicitySigma: Double
    let velocityDispersion: Vector3D // km/s
    let binaryFraction: Double

    func density(atRadius radius: Double, height: Double) -> Double {
        let radialFactor = exp(-(radius - 8.2) / radialScaleLength)
        let verticalFactor = exp(-abs(height * 1000.0) / verticalScaleHeight)
        return baseNumberDensity * radialFactor * verticalFactor
    }
}

struct DustModel: Sendable {
    let extinctionCoefficient: Double // mag per kiloparsec in the mid-plane
    let scaleHeight: Double // pc

    func visualExtinction(distance: Double, height: Double) -> Double {
        let attenuation = exp(-abs(height * 1000.0) / scaleHeight)
        return extinctionCoefficient * distance * attenuation
    }
}

struct SimulationConfig: Sendable {
    let component: GalacticComponent
    let volume: Double // cubic parsec
    let galactocentricRadius: Double // kpc
    let midplaneHeight: Double // kpc
    let distanceFromObserver: Double // kpc
    let seed: UInt64?
    let desiredStellarMass: Double?
    let includeBinaries: Bool
}

struct Vector3D: Codable, Sendable {
    let x: Double
    let y: Double
    let z: Double

    init(x: Double, y: Double, z: Double) {
        self.x = x
        self.y = y
        self.z = z
    }
}

struct StellarSystem: Codable, Sendable {
    struct Companion: Codable, Sendable {
        let mass: Double
        let semiMajorAxisAU: Double
        let eccentricity: Double
        let periodYears: Double
    }

    let component: GalacticComponent
    let positionPC: Vector3D
    let velocityKMS: Vector3D
    let mass: Double
    let ageGyr: Double
    let metallicity: Double
    let stage: StellarStage
    let luminositySolar: Double
    let temperatureKelvin: Double
    let radiusSolar: Double
    let absoluteMagnitudeV: Double
    let apparentMagnitudeV: Double
    let spectralType: String
    let extinctionAV: Double
    let companions: [Companion]
}
