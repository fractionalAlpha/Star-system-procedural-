#if canImport(SwiftUI)
import SwiftUI
import Foundation
import StarSystemCore

@main
struct StarSystemProceduralUIApp: App {
    @StateObject private var viewModel = SimulationViewModel()

    var body: some Scene {
        WindowGroup {
            SimulationView()
                .environmentObject(viewModel)
        }
    }
}

final class SimulationViewModel: ObservableObject {
    @Published var component: GalacticComponent = .thinDisk
    @Published var volume: Double = 1000
    @Published var radius: Double = 8.2
    @Published var height: Double = 0
    @Published var distance: Double = 1.0
    @Published var includeBinaries: Bool = true
    @Published var desiredMassInput: String = ""
    @Published var seedInput: String = ""
    @Published private(set) var systems: [StellarSystem] = []
    @Published private(set) var isGenerating = false
    @Published var errorMessage: String?

    private var desiredMass: Double? {
        guard !desiredMassInput.isEmpty else { return nil }
        return Double(desiredMassInput)
    }

    private var seed: UInt64? {
        guard !seedInput.isEmpty else { return nil }
        return UInt64(seedInput)
    }

    func generate() {
        guard desiredMassInput.isEmpty || desiredMass != nil else {
            errorMessage = "Stellar mass must be a valid number"
            return
        }
        guard seedInput.isEmpty || seed != nil else {
            errorMessage = "Seed must be a valid unsigned integer"
            return
        }

        errorMessage = nil
        isGenerating = true
        let config = SimulationConfig(
            component: component,
            volume: volume,
            galactocentricRadius: radius,
            midplaneHeight: height,
            distanceFromObserver: distance,
            seed: seed,
            desiredStellarMass: desiredMass,
            includeBinaries: includeBinaries
        )

        DispatchQueue.global(qos: .userInitiated).async {
            let generator = StarFieldGenerator(config: config)
            let result = generator.run()
            DispatchQueue.main.async {
                self.systems = result
                self.isGenerating = false
            }
        }
    }
}

struct SimulationView: View {
    @EnvironmentObject private var viewModel: SimulationViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Form {
                    Section("Galactic Component") {
                        Picker("Component", selection: $viewModel.component) {
                            ForEach(GalacticComponent.allCases, id: \.self) { component in
                                Text(component.displayName).tag(component)
                            }
                        }
                    }

                    Section("Spatial Parameters") {
                        HStack {
                            Text("Volume (pc³)")
                            Spacer()
                            TextField("Volume", value: $viewModel.volume, format: .number)
                                .keyboardType(.numbersAndPunctuation)
                                .multilineTextAlignment(.trailing)
                                .frame(maxWidth: 160)
                        }
                        HStack {
                            Text("Radius (kpc)")
                            Spacer()
                            TextField("Radius", value: $viewModel.radius, format: .number)
                                .keyboardType(.numbersAndPunctuation)
                                .multilineTextAlignment(.trailing)
                                .frame(maxWidth: 160)
                        }
                        HStack {
                            Text("Height (kpc)")
                            Spacer()
                            TextField("Height", value: $viewModel.height, format: .number)
                                .keyboardType(.numbersAndPunctuation)
                                .multilineTextAlignment(.trailing)
                                .frame(maxWidth: 160)
                        }
                        HStack {
                            Text("Distance (kpc)")
                            Spacer()
                            TextField("Distance", value: $viewModel.distance, format: .number)
                                .keyboardType(.numbersAndPunctuation)
                                .multilineTextAlignment(.trailing)
                                .frame(maxWidth: 160)
                        }
                    }

                    Section("Sampling Options") {
                        Toggle("Include binaries", isOn: $viewModel.includeBinaries)
                        HStack {
                            Text("Target stellar mass (M☉)")
                            Spacer()
                            TextField("Optional", text: $viewModel.desiredMassInput)
                                .keyboardType(.numbersAndPunctuation)
                                .multilineTextAlignment(.trailing)
                                .frame(maxWidth: 160)
                        }
                        HStack {
                            Text("Seed")
                            Spacer()
                            TextField("Optional", text: $viewModel.seedInput)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(maxWidth: 160)
                        }
                    }
                }
                .frame(maxHeight: 420)

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }

                Button(action: viewModel.generate) {
                    if viewModel.isGenerating {
                        ProgressView()
                    } else {
                        Text("Generate Star Field")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isGenerating)

                StarSystemList(systems: viewModel.systems)
            }
            .padding()
            .navigationTitle("Star System Generator")
        }
    }
}

struct StarSystemList: View {
    let systems: [StellarSystem]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Generated systems: \(systems.count)")
                .font(.headline)
            List {
                ForEach(Array(systems.enumerated()), id: \.offset) { index, system in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("System #\(index + 1)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("Spectral type: \(system.spectralType) — Stage: \(system.stage.rawValue)")
                        Text(String(format: "Mass: %.2f M☉, Age: %.2f Gyr", system.mass, system.ageGyr))
                        Text(String(format: "Apparent V magnitude: %.2f", system.apparentMagnitudeV))
                        if !system.companions.isEmpty {
                            Text("Companions: \(system.companions.count)")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .frame(minHeight: 200)
        }
    }
}

private extension GalacticComponent {
    var displayName: String {
        switch self {
        case .thinDisk:
            return "Thin Disk"
        case .thickDisk:
            return "Thick Disk"
        case .bulge:
            return "Galactic Bulge"
        case .halo:
            return "Halo"
        case .globularCluster:
            return "Globular Cluster"
        }
    }
}
#else
@main
struct StarSystemProceduralUIUnsupportedApp {
    static func main() {
        fatalError("SwiftUI is not available on this platform.")
    }
}
#endif
