import Foundation
import StarSystemCore

struct CLI {
    static func parse(arguments: [String]) -> SimulationConfig {
        var component: GalacticComponent = .thinDisk
        var volume: Double = 1000.0
        var radius: Double = 8.2
        var height: Double = 0.0
        var distance: Double = 1.0
        var seed: UInt64?
        var desiredMass: Double?
        var includeBinaries = true

        var index = 1
        while index < arguments.count {
            let arg = arguments[index]
            func requireValue() -> String {
                index += 1
                guard index < arguments.count else {
                    fatalError("Missing value for \(arg)")
                }
                return arguments[index]
            }

            switch arg {
            case "--component":
                let value = requireValue()
                guard let parsed = GalacticComponent(rawValue: value) else {
                    fatalError("Unknown component: \(value)")
                }
                component = parsed
            case "--volume":
                volume = Double(requireValue()) ?? volume
            case "--radius":
                radius = Double(requireValue()) ?? radius
            case "--height":
                height = Double(requireValue()) ?? height
            case "--distance":
                distance = Double(requireValue()) ?? distance
            case "--seed":
                seed = UInt64(requireValue())
            case "--stellar-mass":
                desiredMass = Double(requireValue())
            case "--no-binaries":
                includeBinaries = false
            case "--help":
                printUsageAndExit()
            default:
                fatalError("Unknown argument: \(arg)")
            }
            index += 1
        }

        return SimulationConfig(
            component: component,
            volume: volume,
            galactocentricRadius: radius,
            midplaneHeight: height,
            distanceFromObserver: distance,
            seed: seed,
            desiredStellarMass: desiredMass,
            includeBinaries: includeBinaries
        )
    }

    private static func printUsageAndExit() -> Never {
        print("""
        Star-system-procedural- generator
        Usage: star-generator [--component thinDisk|thickDisk|bulge|halo|globularCluster]
                               [--volume <pc^3>]
                               [--radius <kpc>]
                               [--height <kpc>]
                               [--distance <kpc>]
                               [--stellar-mass <Msun>]
                               [--seed <int>]
                               [--no-binaries]
        """)
        exit(0)
    }
}

let config = CLI.parse(arguments: CommandLine.arguments)
let generator = StarFieldGenerator(config: config)
let systems = generator.run()

let encoder = JSONEncoder()
encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

do {
    let data = try encoder.encode(systems)
    if let string = String(data: data, encoding: .utf8) {
        print(string)
    } else {
        FileHandle.standardError.write(Data("Failed to encode star systems to UTF-8\n".utf8))
        exit(1)
    }
} catch {
    FileHandle.standardError.write(Data("Failed to encode star systems: \(error)\n".utf8))
    exit(1)
}
