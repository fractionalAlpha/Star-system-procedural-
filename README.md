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

## Project Structure

- `Sources/Star-system-procedural-/main.swift` – CLI entry point and orchestration
- `Sources/Star-system-procedural-/Astrophysics.swift` – Stellar evolution approximations
- `Sources/Star-system-procedural-/GalacticModels.swift` – Core data models
- `Sources/Star-system-procedural-/StarFormation.swift` – Galactic component distributions and dust model
- `Sources/Star-system-procedural-/IMF.swift` – Initial mass function sampler
- `Sources/Star-system-procedural-/Random.swift` – Seedable random number generator utilities

These modules implement the extended plan discussed previously, enabling a reproducible, physics-informed stellar population generator.
