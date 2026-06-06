// Fields — cell-centred volume fields and their boundary conditions.
//
// These mirror OpenFOAM's `volScalarField` / `volVectorField` plus the
// `fvPatchField` boundary-condition hierarchy, but specialised to the four BC
// types the cavity needs.
//
// Real source for reference (this repo):
//   src/finiteVolume/fields/volFields/
//   src/finiteVolume/fields/fvPatchFields/

// MARK: - Boundary conditions

public enum VectorBC {
    case fixedValue(Vector2)   // Dirichlet: known wall velocity (e.g. movingWall)
    case noSlip                // == fixedValue(.zero)
    case zeroGradient
    case empty                 // 2D front/back (unused by the 2D solver)

    var fixedVectorValue: Vector2? {
        switch self {
        case .fixedValue(let v): return v
        case .noSlip:            return .zero
        default:                 return nil
        }
    }
}

public enum ScalarBC {
    case fixedValue(Double)
    case zeroGradient
    case empty
}

// MARK: - Volume vector field (e.g. U)

public final class VolVectorField {
    public let name: String
    public let dimensions: DimensionSet
    public var internalField: [Vector2]
    /// One BC per patch, indexed by patch id.
    public let patchBCs: [VectorBC]
    public unowned let mesh: StructuredMesh

    public init(name: String, dimensions: DimensionSet, mesh: StructuredMesh,
                initial: Vector2, patchBCs: [VectorBC]) {
        self.name = name
        self.dimensions = dimensions
        self.mesh = mesh
        self.internalField = [Vector2](repeating: initial, count: mesh.nCells)
        self.patchBCs = patchBCs
    }

    /// Value at a boundary face: the fixed value for Dirichlet patches, or the
    /// owning cell value for zeroGradient (`correctBoundaryConditions` style).
    public func boundaryValue(_ bf: BoundaryFace) -> Vector2 {
        switch patchBCs[bf.patch] {
        case .fixedValue(let v): return v
        case .noSlip:            return .zero
        case .zeroGradient:      return internalField[bf.cell]
        case .empty:             return internalField[bf.cell]
        }
    }
}

// MARK: - Volume scalar field (e.g. p)

public final class VolScalarField {
    public let name: String
    public let dimensions: DimensionSet
    public var internalField: [Double]
    public let patchBCs: [ScalarBC]
    public unowned let mesh: StructuredMesh

    public init(name: String, dimensions: DimensionSet, mesh: StructuredMesh,
                initial: Double, patchBCs: [ScalarBC]) {
        self.name = name
        self.dimensions = dimensions
        self.mesh = mesh
        self.internalField = [Double](repeating: initial, count: mesh.nCells)
        self.patchBCs = patchBCs
    }

    public func boundaryValue(_ bf: BoundaryFace) -> Double {
        switch patchBCs[bf.patch] {
        case .fixedValue(let v): return v
        case .zeroGradient:      return internalField[bf.cell]
        case .empty:             return internalField[bf.cell]
        }
    }
}

// MARK: - Surface scalar field (e.g. the flux phi = U.Sf)

/// Values living on faces. `internal` has one entry per internal face, `boundary`
/// one per boundary face — the same split OpenFOAM's `surfaceScalarField` uses.
public struct SurfaceScalarField {
    public var internalField: [Double]
    public var boundaryField: [Double]

    public init(mesh: StructuredMesh, value: Double = 0) {
        internalField = [Double](repeating: value, count: mesh.internalFaces.count)
        boundaryField = [Double](repeating: value, count: mesh.boundaryFaces.count)
    }
}
