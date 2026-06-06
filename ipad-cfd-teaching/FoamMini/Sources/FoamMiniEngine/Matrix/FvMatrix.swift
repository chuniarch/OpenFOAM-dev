// FvMatrix — sparse matrices in LDU (lower/diagonal/upper) form.
//
// This mirrors OpenFOAM's `lduMatrix` + `fvMatrix`. Coefficients are stored by
// addressing: one `diag` per cell, and one `upper`/`lower` per internal face
// (face f connects owner o and neighbour n; `upper[f]` is the o-row coefficient
// multiplying x[n], `lower[f]` the n-row coefficient multiplying x[o]).
//
// The discretisation namespaces (`Fvm`) build these; the linear solvers consume
// them. `A()` and `H()` expose the diagonal and off-diagonal action used by the
// PISO pressure-velocity coupling, exactly as in `fvMatrix::A()/H()`.
//
// Real source for reference (this repo):
//   src/finiteVolume/fvMatrices/fvMatrix/
//   src/OpenFOAM/matrices/lduMatrix/lduMatrix/

/// Coefficient skeleton shared by scalar and vector equations (the geometry and
/// flux coefficients are identical; only the source/unknown type differs).
public struct LduCoeffs {
    public var diag: [Double]
    public var upper: [Double]   // per internal face
    public var lower: [Double]   // per internal face

    public init(mesh: StructuredMesh) {
        diag = [Double](repeating: 0, count: mesh.nCells)
        upper = [Double](repeating: 0, count: mesh.internalFaces.count)
        lower = [Double](repeating: 0, count: mesh.internalFaces.count)
    }

    public mutating func add(_ o: LduCoeffs) {
        for i in diag.indices { diag[i] += o.diag[i] }
        for f in upper.indices { upper[f] += o.upper[f]; lower[f] += o.lower[f] }
    }

    public mutating func negate() {
        for i in diag.indices { diag[i] = -diag[i] }
        for f in upper.indices { upper[f] = -upper[f]; lower[f] = -lower[f] }
    }
}

// MARK: - Vector equation (momentum, U)

public struct FvVectorMatrix {
    public var coeffs: LduCoeffs
    public var source: [Vector2]
    public unowned let mesh: StructuredMesh

    public init(mesh: StructuredMesh) {
        self.mesh = mesh
        self.coeffs = LduCoeffs(mesh: mesh)
        self.source = [Vector2](repeating: .zero, count: mesh.nCells)
    }

    public static func + (a: FvVectorMatrix, b: FvVectorMatrix) -> FvVectorMatrix {
        var r = a
        r.coeffs.add(b.coeffs)
        for i in r.source.indices { r.source[i] += b.source[i] }
        return r
    }

    public static func - (a: FvVectorMatrix, b: FvVectorMatrix) -> FvVectorMatrix {
        var nb = b
        nb.coeffs.negate()
        for i in nb.source.indices { nb.source[i] = -nb.source[i] }
        return a + nb
    }

    /// Diagonal per unit volume — `fvMatrix::A()`.
    public func A() -> [Double] {
        let V = mesh.cellVolume
        return coeffs.diag.map { $0 / V }
    }

    /// Off-diagonal "H" operator per unit volume — `fvMatrix::H()`:
    ///   H = (source - sum_offdiag * x) / V
    /// Uses the *current* field `x` (called after the momentum predictor, as in
    /// icoFoam, so it reflects the latest velocity).
    public func H(_ x: [Vector2]) -> [Vector2] {
        let V = mesh.cellVolume
        var h = source
        for (f, face) in mesh.internalFaces.enumerated() {
            h[face.owner]    -= coeffs.upper[f] * x[face.neighbour]
            h[face.neighbour] -= coeffs.lower[f] * x[face.owner]
        }
        for i in h.indices { h[i] = h[i] / V }
        return h
    }
}

// MARK: - Scalar equation (pressure, p)

public struct FvScalarMatrix {
    public var coeffs: LduCoeffs
    public var source: [Double]
    public unowned let mesh: StructuredMesh

    public init(mesh: StructuredMesh) {
        self.mesh = mesh
        self.coeffs = LduCoeffs(mesh: mesh)
        self.source = [Double](repeating: 0, count: mesh.nCells)
    }

    /// Pin the solution at `cell` to `value` (OpenFOAM `setReference`), needed
    /// because the cavity pressure equation is all-Neumann (singular otherwise).
    public mutating func setReference(cell: Int, value: Double) {
        let c = coeffs.diag[cell]
        coeffs.diag[cell] += c
        source[cell] += c * value
    }
}
