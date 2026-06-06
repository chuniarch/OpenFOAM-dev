// DimensionSet — the 7 SI base-dimension exponents, mirroring OpenFOAM's
// `dimensionSet` (e.g. velocity is written `[0 1 -1 0 0 0 0]`).
//
// For M0 this is a *teaching annotation*: fields carry their dimensions so the
// UI (and tests) can display/verify them, but arithmetic does not yet enforce
// dimensional consistency. Enforcing it is a good later exercise that maps
// directly onto OpenFOAM's compile-time dimension checking.
//
// Order: [mass, length, time, temperature, moles, current, luminousIntensity]

public struct DimensionSet: Equatable {
    public var exponents: [Int]   // length 7

    public init(_ e: [Int]) {
        precondition(e.count == 7, "DimensionSet requires 7 exponents")
        exponents = e
    }

    // Common dimensions used by the cavity case.
    public static let dimless          = DimensionSet([0, 0, 0, 0, 0, 0, 0])
    public static let velocity         = DimensionSet([0, 1, -1, 0, 0, 0, 0])  // m/s
    public static let pressureKinematic = DimensionSet([0, 2, -2, 0, 0, 0, 0]) // p/rho, m^2/s^2
    public static let kinematicViscosity = DimensionSet([0, 2, -1, 0, 0, 0, 0]) // nu, m^2/s
    public static let flux             = DimensionSet([0, 3, -1, 0, 0, 0, 0])  // phi = U.Sf, m^3/s

    public static func + (a: DimensionSet, b: DimensionSet) -> DimensionSet {
        DimensionSet(zip(a.exponents, b.exponents).map(+))
    }

    /// Bracketed form matching OpenFOAM field headers, e.g. "[0 1 -1 0 0 0 0]".
    public var bracketed: String {
        "[" + exponents.map(String.init).joined(separator: " ") + "]"
    }
}
