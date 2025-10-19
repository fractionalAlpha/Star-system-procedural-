# Star System Procedural Generator

This Swift command-line tool generates a procedurally sampled stellar population consistent with simplified models of Milky Way structure and stellar evolution. Starting from basic inputs such as galactic component, location, and sampled volume (or total stellar mass), it adds the necessary astrophysical ingredients to synthesise realistic star systems: density profiles, star-formation histories, metallicity gradients, initial mass functions, kinematics, multiplicity statistics, dust extinction, and stellar evolution tracks.

## Building

```bash
swift build
```

## Running

By default the generator samples a 1000 pc³ patch of the thin disk located at the Solar radius and one kiloparsec from the observer:

```bash
swift run Star-system-procedural-
```

The executable accepts several arguments to tune the sampled environment:

```
--component       thinDisk | thickDisk | bulge | halo | globularCluster
--volume          Cubic parsecs to sample (default: 1000)
--radius          Galactocentric radius in kpc (default: 8.2)
--height          Height above the galactic mid-plane in kpc (default: 0)
--distance        Distance from the observer in kpc (default: 1.0)
--stellar-mass    Target stellar mass for the sample in solar masses (optional)
--seed            RNG seed for reproducible output
--no-binaries     Disable sampling of binary companions
```

Example: synthesize a bulge population 2 kpc from the Galactic centre with a total stellar mass budget of 500 Msun.

```bash
swift run Star-system-procedural- --component bulge --radius 2.0 --distance 8.0 --stellar-mass 500 --seed 42
```

The program prints JSON describing every generated stellar system, including spatial coordinates, velocities, stellar parameters, magnitudes, extinction, and any companions.

## SwiftUI App

A SwiftUI front-end is also available on Apple platforms. It exposes the same sampling controls in an interactive form and renders the generated systems in a list.

```bash
swift run StarSystemProceduralUI
```

> **Note:** The SwiftUI target requires macOS 13 or iOS 17 (or newer) where the `SwiftUI` framework is available.

## Project Structure

- `Sources/StarSystemCore/` – Shared astrophysics models, samplers, and generator logic used by both executables
- `Sources/Star-system-procedural-/main.swift` – CLI entry point wiring arguments into the core generator
- `Sources/StarSystemProceduralUI/StarSystemProceduralUIApp.swift` – SwiftUI interface for interactive exploration

These modules implement the extended plan discussed previously, enabling a reproducible, physics-informed stellar population generator with both command-line and graphical front-ends.
