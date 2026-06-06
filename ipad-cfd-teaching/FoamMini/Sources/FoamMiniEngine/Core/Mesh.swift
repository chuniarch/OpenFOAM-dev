// StructuredMesh — a 2D uniform Cartesian mesh for the lid-driven cavity.
//
// This is the M0 stand-in for OpenFOAM's `fvMesh`/`polyMesh`. It keeps the same
// essential concepts — cells, internal faces with owner/neighbour addressing,
// face area vectors `Sf`, and boundary `patch`es — but specialised to a regular
// grid so the geometry is trivial to reason about.
//
// Real source for reference (this repo):
//   src/finiteVolume/fvMesh/        (fvMesh)
//   src/OpenFOAM/meshes/polyMesh/   (polyMesh, owner/neighbour addressing)

/// An internal face separating `owner` and `neighbour` cells.
/// `sf` points from owner -> neighbour (outward w.r.t. the owner).
public struct InternalFace {
    public let owner: Int
    public let neighbour: Int
    public let sf: Vector2
    public let magSf: Double
    public let delta: Double   // distance between the two cell centres
}

/// A boundary face on a `patch`. `sf` points out of the domain.
/// `delta` is the cell-centre-to-boundary distance.
public struct BoundaryFace {
    public let cell: Int
    public let sf: Vector2
    public let magSf: Double
    public let delta: Double
    public let patch: Int
}

/// Reference from a cell to one of its internal faces, used by the
/// Gauss-Seidel sweep and by `H()` to gather off-diagonal contributions.
public struct CellFaceRef {
    public let face: Int     // index into `internalFaces`
    public let other: Int    // the cell on the far side of the face
    public let isOwner: Bool // is this cell the face owner?
}

public final class StructuredMesh {
    public let nx: Int
    public let ny: Int
    public let dx: Double
    public let dy: Double
    public let dz: Double          // depth (cancels in 2D, kept for honest Sf/V)
    public let nCells: Int
    public let cellVolume: Double  // uniform

    public let internalFaces: [InternalFace]
    public let boundaryFaces: [BoundaryFace]
    public let patchNames: [String]
    public let cellFaceRefs: [[CellFaceRef]]

    // Patch indices for the cavity.
    public static let movingWall = 0
    public static let fixedWalls = 1

    /// Build the cavity mesh. `length` is the side of the square domain (m).
    public init(nx: Int, ny: Int, length: Double, depth: Double = 0.01) {
        self.nx = nx
        self.ny = ny
        self.dx = length / Double(nx)
        self.dy = length / Double(ny)
        self.dz = depth
        self.nCells = nx * ny
        self.cellVolume = dx * dy * dz
        self.patchNames = ["movingWall", "fixedWalls"]

        func id(_ i: Int, _ j: Int) -> Int { j * nx + i }

        // --- internal faces ---
        var faces: [InternalFace] = []
        faces.reserveCapacity(2 * nCells)
        let axFace = dy * dz   // area of an x-normal face
        let ayFace = dx * dz   // area of a y-normal face

        // x-normal internal faces (between (i,j) and (i+1,j))
        for j in 0..<ny {
            for i in 0..<(nx - 1) {
                faces.append(InternalFace(
                    owner: id(i, j), neighbour: id(i + 1, j),
                    sf: Vector2(axFace, 0), magSf: axFace, delta: dx))
            }
        }
        // y-normal internal faces (between (i,j) and (i,j+1))
        for j in 0..<(ny - 1) {
            for i in 0..<nx {
                faces.append(InternalFace(
                    owner: id(i, j), neighbour: id(i, j + 1),
                    sf: Vector2(0, ayFace), magSf: ayFace, delta: dy))
            }
        }
        self.internalFaces = faces

        // --- boundary faces ---
        var bfaces: [BoundaryFace] = []
        for j in 0..<ny {   // left wall (fixedWalls), outward -x
            bfaces.append(BoundaryFace(cell: id(0, j), sf: Vector2(-axFace, 0),
                                       magSf: axFace, delta: dx / 2, patch: StructuredMesh.fixedWalls))
        }
        for j in 0..<ny {   // right wall (fixedWalls), outward +x
            bfaces.append(BoundaryFace(cell: id(nx - 1, j), sf: Vector2(axFace, 0),
                                       magSf: axFace, delta: dx / 2, patch: StructuredMesh.fixedWalls))
        }
        for i in 0..<nx {   // bottom wall (fixedWalls), outward -y
            bfaces.append(BoundaryFace(cell: id(i, 0), sf: Vector2(0, -ayFace),
                                       magSf: ayFace, delta: dy / 2, patch: StructuredMesh.fixedWalls))
        }
        for i in 0..<nx {   // top wall (movingWall), outward +y
            bfaces.append(BoundaryFace(cell: id(i, ny - 1), sf: Vector2(0, ayFace),
                                       magSf: ayFace, delta: dy / 2, patch: StructuredMesh.movingWall))
        }
        self.boundaryFaces = bfaces

        // --- cell -> internal-face connectivity ---
        var refs = [[CellFaceRef]](repeating: [], count: nCells)
        for (f, face) in faces.enumerated() {
            refs[face.owner].append(CellFaceRef(face: f, other: face.neighbour, isOwner: true))
            refs[face.neighbour].append(CellFaceRef(face: f, other: face.owner, isOwner: false))
        }
        self.cellFaceRefs = refs
    }

    /// Cell-centre coordinate (for probes / output).
    public func centre(_ cell: Int) -> Vector2 {
        let i = cell % nx
        let j = cell / nx
        return Vector2((Double(i) + 0.5) * dx, (Double(j) + 0.5) * dy)
    }
}
