import Foundation

public struct StarFieldGenerator {
    public let config: SimulationConfig
    private let models = StellarPopulationSampler.models()

    public init(config: SimulationConfig) {
        self.config = config
    }

    public func run() -> [StellarSystem] {
        var rng = FlexibleGenerator(seed: config.seed)
        guard let regionModel = models[config.component] else { return [] }
        let dustModel = StellarPopulationSampler.dustModel(for: config.component)
        let density = regionModel.density(atRadius: config.galactocentricRadius, height: config.midplaneHeight)

        var starCount = max(1, Int(round(density * config.volume)))
        if let desiredMass = config.desiredStellarMass {
            let averageMass = averageIMFMass(samples: 1024, rng: &rng)
            let expectedCount = Int(round(desiredMass / max(averageMass, 0.1)))
            starCount = max(1, expectedCount)
        }

        var systems: [StellarSystem] = []
        systems.reserveCapacity(starCount)

        for _ in 0..<starCount {
            let mass = InitialMassFunction.sampleMass(generator: &rng)
            let age = StellarPopulationSampler.sampleAge(for: config.component, generator: &rng)
            let metallicity = StellarPopulationSampler.sampleMetallicity(for: config.component, radius: config.galactocentricRadius, generator: &rng)
            let stage = classifyStage(mass: mass, age: age, metallicity: metallicity)
            let luminosity = max(0.0001, StellarEvolution.luminosity(forMass: mass, evolutionaryStage: stage))
            let temperature = StellarEvolution.effectiveTemperature(forMass: mass, evolutionaryStage: stage)
            let radius = StellarEvolution.radius(luminosity: luminosity, effectiveTemperature: temperature)
            let absoluteMag = StellarEvolution.absoluteMagnitude(luminosity: luminosity)

            let position = samplePosition(generator: &rng)
            let velocity = StellarPopulationSampler.sampleVelocity(for: config.component, generator: &rng)

            let distance = max(config.distanceFromObserver * 1000.0, 1.0)
            let extinction = dustModel.visualExtinction(distance: config.distanceFromObserver, height: config.midplaneHeight)
            let apparentMag = absoluteMag + 5 * log10(distance) - 5 + extinction
            let spectralType = StellarEvolution.spectralType(forTemperature: temperature)
            let companions: [StellarSystem.Companion]
            if config.includeBinaries {
                companions = StellarPopulationSampler.sampleBinaryCompanions(for: config.component, primaryMass: mass, generator: &rng)
            } else {
                companions = []
            }

            systems.append(
                StellarSystem(
                    component: config.component,
                    positionPC: position,
                    velocityKMS: velocity,
                    mass: mass,
                    ageGyr: age,
                    metallicity: metallicity,
                    stage: stage,
                    luminositySolar: luminosity,
                    temperatureKelvin: temperature,
                    radiusSolar: radius,
                    absoluteMagnitudeV: absoluteMag,
                    apparentMagnitudeV: apparentMag,
                    spectralType: spectralType,
                    extinctionAV: extinction,
                    companions: companions
                )
            )
        }

        return systems
    }

    private func averageIMFMass(samples: Int, rng: inout FlexibleGenerator) -> Double {
        var total: Double = 0
        var localRNG = rng
        for _ in 0..<samples {
            total += InitialMassFunction.sampleMass(generator: &localRNG)
        }
        rng = localRNG
        return total / Double(samples)
    }

    private func classifyStage(mass: Double, age: Double, metallicity: Double) -> StellarStage {
        let mainSequenceLifetime = StellarEvolution.mainSequenceLifetime(forMass: mass, metallicity: metallicity)
        if age < mainSequenceLifetime {
            return .mainSequence
        }
        if mass > 8.0 {
            return .neutronStar
        }
        if age < mainSequenceLifetime * 1.2 {
            return .subGiant
        }
        if age < mainSequenceLifetime * 5.0 {
            return .redGiant
        }
        return .whiteDwarf
    }

    private func samplePosition<R: RandomNumberGenerator>(generator: inout R) -> Vector3D {
        let radialExtent = pow(config.volume / Double.pi, 1.0 / 3.0)
        let r = radialExtent * sqrt(generator.nextUniform())
        let theta = 2 * Double.pi * generator.nextUniform()
        let zScale = models[config.component]?.verticalScaleHeight ?? 300.0
        let z = generator.nextGaussian(mean: 0, sigma: zScale / 1000.0)
        let x = r * cos(theta)
        let y = r * sin(theta)
        return Vector3D(x: x, y: y, z: z)
    }
}
