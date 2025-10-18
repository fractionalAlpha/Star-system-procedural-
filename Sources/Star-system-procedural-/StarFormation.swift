import Foundation

struct StellarPopulationSampler {
    static func models() -> [GalacticComponent: GalacticRegionModel] {
        return [
            .thinDisk: GalacticRegionModel(
                baseNumberDensity: 0.08,
                radialScaleLength: 2.6,
                verticalScaleHeight: 300.0,
                ageRange: 0.0...10.0,
                metallicityMean: 0.0,
                metallicitySigma: 0.2,
                velocityDispersion: Vector3D(x: 30, y: 20, z: 15),
                binaryFraction: 0.44
            ),
            .thickDisk: GalacticRegionModel(
                baseNumberDensity: 0.003,
                radialScaleLength: 3.6,
                verticalScaleHeight: 900.0,
                ageRange: 8.0...12.0,
                metallicityMean: -0.5,
                metallicitySigma: 0.3,
                velocityDispersion: Vector3D(x: 60, y: 45, z: 35),
                binaryFraction: 0.35
            ),
            .bulge: GalacticRegionModel(
                baseNumberDensity: 0.4,
                radialScaleLength: 1.0,
                verticalScaleHeight: 400.0,
                ageRange: 8.0...12.0,
                metallicityMean: -0.1,
                metallicitySigma: 0.4,
                velocityDispersion: Vector3D(x: 110, y: 90, z: 80),
                binaryFraction: 0.3
            ),
            .halo: GalacticRegionModel(
                baseNumberDensity: 0.0001,
                radialScaleLength: 15.0,
                verticalScaleHeight: 5000.0,
                ageRange: 10.0...13.0,
                metallicityMean: -1.5,
                metallicitySigma: 0.4,
                velocityDispersion: Vector3D(x: 140, y: 120, z: 100),
                binaryFraction: 0.15
            ),
            .globularCluster: GalacticRegionModel(
                baseNumberDensity: 1.5,
                radialScaleLength: 0.5,
                verticalScaleHeight: 20.0,
                ageRange: 10.0...13.0,
                metallicityMean: -1.0,
                metallicitySigma: 0.2,
                velocityDispersion: Vector3D(x: 10, y: 10, z: 10),
                binaryFraction: 0.05
            )
        ]
    }

    static func dustModel(for component: GalacticComponent) -> DustModel {
        switch component {
        case .thinDisk:
            return DustModel(extinctionCoefficient: 1.8, scaleHeight: 150.0)
        case .thickDisk:
            return DustModel(extinctionCoefficient: 0.9, scaleHeight: 300.0)
        case .bulge:
            return DustModel(extinctionCoefficient: 2.4, scaleHeight: 120.0)
        case .halo:
            return DustModel(extinctionCoefficient: 0.3, scaleHeight: 800.0)
        case .globularCluster:
            return DustModel(extinctionCoefficient: 0.6, scaleHeight: 60.0)
        }
    }

    static func sampleAge<R: RandomNumberGenerator>(for component: GalacticComponent, generator: inout R) -> Double {
        switch component {
        case .thinDisk:
            // Exponentially declining star-formation history
            let tau = 6.0
            let age = generator.sampleExponential(scale: tau)
            return min(max(age, 0.1), 10.0)
        case .thickDisk:
            return clamp(generator.nextGaussian(mean: 10.0, sigma: 1.0), to: 8.0...12.0)
        case .bulge:
            return clamp(generator.nextGaussian(mean: 9.5, sigma: 1.5), to: 6.0...13.0)
        case .halo:
            return clamp(generator.nextGaussian(mean: 12.0, sigma: 0.7), to: 10.0...13.5)
        case .globularCluster:
            return clamp(generator.nextGaussian(mean: 12.5, sigma: 0.5), to: 11.0...13.5)
        }
    }

    static func sampleMetallicity<R: RandomNumberGenerator>(for component: GalacticComponent, radius: Double, generator: inout R) -> Double {
        let gradientPerKpc: Double
        switch component {
        case .thinDisk:
            gradientPerKpc = -0.07
        case .thickDisk:
            gradientPerKpc = -0.03
        case .bulge:
            gradientPerKpc = 0.02
        case .halo:
            gradientPerKpc = -0.01
        case .globularCluster:
            gradientPerKpc = -0.005
        }

        let models = self.models()
        let base = models[component]!
        let mean = base.metallicityMean + gradientPerKpc * (radius - 8.2)
        let metallicity = generator.nextGaussian(mean: mean, sigma: base.metallicitySigma)
        return max(-2.5, min(0.5, metallicity))
    }

    static func sampleVelocity<R: RandomNumberGenerator>(for component: GalacticComponent, generator: inout R) -> Vector3D {
        let dispersions = models()[component]!.velocityDispersion
        let vx = generator.nextGaussian(mean: 0, sigma: dispersions.x)
        let vy = generator.nextGaussian(mean: 0, sigma: dispersions.y)
        let vz = generator.nextGaussian(mean: 0, sigma: dispersions.z)
        return Vector3D(x: vx, y: vy, z: vz)
    }

    static func sampleBinaryCompanions<R: RandomNumberGenerator>(for component: GalacticComponent, primaryMass: Double, generator: inout R) -> [StellarSystem.Companion] {
        let binaryFraction = models()[component]!.binaryFraction
        if generator.nextUniform() > binaryFraction {
            return []
        }

        let companionMassRatio = pow(generator.nextUniform(), 0.5)
        let mass = max(0.08, min(primaryMass * companionMassRatio, primaryMass))
        let semiMajorAxis = pow(10.0, generator.nextGaussian(mean: log10(30.0), sigma: 0.8))
        let eccentricity = min(0.95, max(0.0, generator.nextGaussian(mean: 0.4, sigma: 0.2)))
        let periodYears = sqrt(pow(semiMajorAxis, 3) / max(primaryMass + mass, 0.1))
        return [StellarSystem.Companion(mass: mass, semiMajorAxisAU: semiMajorAxis, eccentricity: eccentricity, periodYears: periodYears)]
    }

    private static func clamp(_ value: Double, to range: ClosedRange<Double>) -> Double {
        return min(max(value, range.lowerBound), range.upperBound)
    }
}
