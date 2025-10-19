#if canImport(SwiftUI)
import SwiftUI
import StarSystemCore

struct ContentView: View {
    @StateObject private var viewModel = SimulationViewModel()

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
                        SimulationNumberRow(title: "Volume (pc³)", value: $viewModel.volume)
                        SimulationNumberRow(title: "Radius (kpc)", value: $viewModel.radius)
                        SimulationNumberRow(title: "Height (kpc)", value: $viewModel.height)
                        SimulationNumberRow(title: "Distance (kpc)", value: $viewModel.distance)
                    }

                    Section("Sampling Options") {
                        Toggle("Include binaries", isOn: $viewModel.includeBinaries)
                        SimulationTextRow(
                            title: "Target stellar mass (M☉)",
                            text: $viewModel.desiredMassInput,
                            placeholder: "Optional",
                            keyboard: .numbersAndPunctuation
                        )
                        SimulationTextRow(
                            title: "Seed",
                            text: $viewModel.seedInput,
                            placeholder: "Optional",
                            keyboard: .numberPad
                        )
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

private struct SimulationNumberRow<Value: BinaryFloatingPoint>: View where Value.Stride: BinaryFloatingPoint {
    let title: String
    @Binding var value: Value

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            TextField(title, value: doubleBinding, formatter: Self.numberFormatter)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 160)
#if os(iOS)
                .keyboardType(.numbersAndPunctuation)
#endif
        }
    }

    private var doubleBinding: Binding<Double?> {
        Binding<Double?>(
            get: { Double(value) },
            set: { newValue in
                guard let newValue else { return }
                value = Value(newValue)
            }
        )
    }

    private static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.allowsFloats = true
        formatter.generatesDecimalNumbers = false
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 6
        formatter.usesGroupingSeparator = false
        formatter.isLenient = true
        formatter.zeroSymbol = nil
        formatter.nilSymbol = ""
        return formatter
    }()
}

private struct SimulationTextRow: View {
    enum KeyboardStyle {
        case numbersAndPunctuation
        case numberPad
    }

    let title: String
    @Binding var text: String
    let placeholder: String
    let keyboard: KeyboardStyle

    init(title: String, text: Binding<String>, placeholder: String, keyboard: KeyboardStyle = .numbersAndPunctuation) {
        self.title = title
        self._text = text
        self.placeholder = placeholder
        self.keyboard = keyboard
    }

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            TextField(placeholder, text: $text)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 160)
#if os(iOS)
                .keyboardType(keyboard.uiKeyboardType)
#endif
        }
    }
}

#if os(iOS)
private extension SimulationTextRow.KeyboardStyle {
    var uiKeyboardType: UIKeyboardType {
        switch self {
        case .numbersAndPunctuation:
            return .numbersAndPunctuation
        case .numberPad:
            return .numberPad
        }
    }
}
#endif

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

#Preview {
    ContentView()
}
#endif
