// swift-tools-version:5.9
import PackageDescription

// FoamMini — M0 engine for the iPad CFD teaching app.
//
// A minimal, readable finite-volume incompressible solver (icoFoam / PISO on a
// 2D lid-driven cavity) whose top-level structure mirrors OpenFOAM's
// `applications/legacy/incompressible/icoFoam/icoFoam.C`.
//
// This is the headless engine only (M0). No UI / Metal yet — those arrive in M1.
let package = Package(
    name: "FoamMini",
    products: [
        .library(name: "FoamMiniEngine", targets: ["FoamMiniEngine"]),
        .executable(name: "foammini", targets: ["foammini"]),
    ],
    targets: [
        .target(name: "FoamMiniEngine"),
        .executableTarget(
            name: "foammini",
            dependencies: ["FoamMiniEngine"]
        ),
        .testTarget(
            name: "FoamMiniEngineTests",
            dependencies: ["FoamMiniEngine"]
        ),
    ]
)
