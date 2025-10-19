import Foundation

public enum GalacticComponent: String, CaseIterable, Codable, Sendable {
    case thinDisk
    case thickDisk
    case bulge
    case halo
    case globularCluster
}

public struct GalacticRegionModel: Sendable {
    public let baseNumberDensity: Double // stars per cubic parsec at solar radius
    public let radialScaleLength: Double // kpc
    public let verticalScaleHeight: Double // pc
    public let ageRange: ClosedRange<Double> // Gyr
    public let metallicityMean: Double
    public let metallicitySigma: Double
    public let velocityDispersion: Vector3D // km/s
    public let binaryFraction: Double

    public func density(atRadius radius: Double, height: Double) -> Double {
        let radialFactor = exp(-(radius - 8.2) / radialScaleLength)
        let verticalFactor = exp(-abs(height * 1000.0) / verticalScaleHeight)
        return baseNumberDensity * radialFactor * verticalFactor
    }
}

public struct DustModel: Sendable {
    public let extinctionCoefficient: Double // mag per kiloparsec in the mid-plane
    public let scaleHeight: Double // pc

    public func visualExtinction(distance: Double, height: Double) -> Double {
        let attenuation = exp(-abs(height * 1000.0) / scaleHeight)
        return extinctionCoefficient * distance * attenuation
    }
}

public struct SimulationConfig: Sendable {
    public let component: GalacticComponent
    public let volume: Double // cubic parsec
    public let galactocentricRadius: Double // kpc
    public let midplaneHeight: Double // kpc
    public let distanceFromObserver: Double // kpc
    public let seed: UInt64?
    public let desiredStellarMass: Double?
    public let includeBinaries: Bool

    public init(component: GalacticComponent, volume: Double, galactocentricRadius: Double, midplaneHeight: Double, distanceFromObserver: Double, seed: UInt64?, desiredStellarMass: Double?, includeBinaries: Bool) {
        self.component = component
        self.volume = volume
        self.galactocentricRadius = galactocentricRadius
        self.midplaneHeight = midplaneHeight
        self.distanceFromObserver = distanceFromObserver
        self.seed = seed
        self.desiredStellarMass = desiredStellarMass
        self.includeBinaries = includeBinaries
    }
}

public struct Vector3D: Codable, Sendable {
    public let x: Double
    public let y: Double
    public let z: Double

    public init(x: Double, y: Double, z: Double) {
        self.x = x
        self.y = y
        self.z = z
    }
}

public struct StellarSystem: Codable, Sendable {
    public struct Companion: Codable, Sendable {
        public let mass: Double
        public let semiMajorAxisAU: Double
        public let eccentricity: Double
        public let periodYears: Double
    }

    public let component: GalacticComponent
    public let positionPC: Vector3D
    public let velocityKMS: Vector3D
    public let mass: Double
    public let ageGyr: Double
    public let metallicity: Double
    public let stage: StellarStage
    public let luminositySolar: Double
    public let temperatureKelvin: Double
    public let radiusSolar: Double
    public let absoluteMagnitudeV: Double
    public let apparentMagnitudeV: Double
    public let spectralType: String
    public let extinctionAV: Double
    public let companions: [Companion]

    public init(component: GalacticComponent, positionPC: Vector3D, velocityKMS: Vector3D, mass: Double, ageGyr: Double, metallicity: Double, stage: StellarStage, luminositySolar: Double, temperatureKelvin: Double, radiusSolar: Double, absoluteMagnitudeV: Double, apparentMagnitudeV: Double, spectralType: String, extinctionAV: Double, companions: [Companion]) {
        self.component = component
        self.positionPC = positionPC
        self.velocityKMS = velocityKMS
        self.mass = mass
        self.ageGyr = ageGyr
        self.metallicity = metallicity
        self.stage = stage
        self.luminositySolar = luminositySolar
        self.temperatureKelvin = temperatureKelvin
        self.radiusSolar = radiusSolar
        self.absoluteMagnitudeV = absoluteMagnitudeV
        self.apparentMagnitudeV = apparentMagnitudeV
        self.spectralType = spectralType
        self.extinctionAV = extinctionAV
        self.companions = companions
    }
}
