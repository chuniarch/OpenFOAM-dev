# FoamMini — M0 teaching engine

A minimal, readable **finite-volume incompressible CFD engine** in Swift that
solves the **lid-driven cavity** with the **icoFoam / PISO** algorithm. It is the
headless numerical core (milestone **M0**) for the iPad CFD teaching app described
in `../../doc/ipad-cfd-teaching/architecture.md`.

Its top-level structure is a deliberate, near-line-for-line analogue of OpenFOAM's
`applications/legacy/incompressible/icoFoam/icoFoam.C`, so it can later drive the
app's "function → real OpenFOAM source" mapping panel.

## ⚠️ Build status

This package was **authored in an environment without a Swift toolchain** (and
`swift.org` was network-blocked), so it has **not yet been compiled or run here**.
Build and test it on macOS / Linux with Swift 5.9+:

```bash
cd ipad-cfd-teaching/FoamMini
swift build
swift test          # runs the cavity verification tests
swift run foammini  # prints a convergence trace + centreline profile
```

Expect to iterate on the first build (this is M0). Report any compiler errors and
we will fix them.

## Layout (mirrors the architecture doc)

```
Sources/FoamMiniEngine/
  Core/          Vector2, DimensionSet, StructuredMesh, Fields
  Matrix/        FvMatrix (LDU: FvVectorMatrix, FvScalarMatrix, A()/H())
  Discretisation/ Fvm (implicit: ddt/div/laplacian), Fvc (explicit: grad/flux/interpolate)
  Solvers/       LinearSolver (CG + Gauss-Seidel), PisoControl, IcoFoam
  Case/          CavityCase (the tutorial preset)
Sources/foammini/  CLI
Tests/             cavity verification
```

## Engine ↔ real OpenFOAM (this repo)

| FoamMini | OpenFOAM | Source |
|---|---|---|
| `IcoFoam.step()` | the icoFoam time loop | `applications/legacy/incompressible/icoFoam/icoFoam.C` |
| `Fvm.ddt/div/laplacian` | `fvm::ddt/div/laplacian` | `src/finiteVolume/finiteVolume/fvm/` |
| `Fvc.grad/flux/interpolate` | `fvc::grad/flux/interpolate` | `src/finiteVolume/finiteVolume/fvc/` |
| `FvVectorMatrix.A()/H()` | `fvMatrix::A()/H()` | `src/finiteVolume/fvMatrices/` |
| `StructuredMesh` | `fvMesh` / `polyMesh` | `src/finiteVolume/fvMesh/` |
| `CavityCase` | the cavity tutorial | `tutorials/legacy/incompressible/icoFoam/cavity/cavity` |

## Known simplifications (future milestones)

- Orthogonal mesh ⇒ no non-orthogonal correctors.
- Rhie–Chow transient flux correction (`fvc::ddtCorr`) omitted; the face-based
  pressure Laplacian supplies the p–U coupling, adequate at this Re≈10.
- Linear solver preconditioner is Jacobi, not DIC.
- Dimensions are carried for display but not enforced in arithmetic.
