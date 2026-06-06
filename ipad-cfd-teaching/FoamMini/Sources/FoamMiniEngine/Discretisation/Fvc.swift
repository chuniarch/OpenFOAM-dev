// Fvc — EXPLICIT finite-volume calculus: each operator evaluates a quantity
// from a *known* field and returns a field (no matrix). Mirrors `Foam::fvc::`.
//
//   fvc::grad        -> Gauss cell gradient of p
//   fvc::interpolate -> cell -> face linear interpolation
//   fvc::flux        -> face-normal volumetric flux of a vector field, U_f . Sf
//
// Real source for reference (this repo):
//   src/finiteVolume/finiteVolume/fvc/   (fvcGrad, fvcDiv, fvcFlux)

public struct Fvc {
    public let mesh: StructuredMesh

    public init(mesh: StructuredMesh) { self.mesh = mesh }

    // MARK: grad(p) — Gauss gradient,  (1/V) Σ_f p_f Sf
    public func grad(_ p: VolScalarField) -> [Vector2] {
        let V = mesh.cellVolume
        var g = [Vector2](repeating: .zero, count: mesh.nCells)
        for (_, face) in mesh.internalFaces.enumerated() {
            let pf = 0.5 * (p.internalField[face.owner] + p.internalField[face.neighbour])
            g[face.owner]    += pf * face.sf          // Sf points o -> n (outward for o)
            g[face.neighbour] -= pf * face.sf          // inward for n
        }
        for bf in mesh.boundaryFaces {
            let pf = p.boundaryValue(bf)               // zeroGradient -> p_cell
            g[bf.cell] += pf * bf.sf
        }
        for c in g.indices { g[c] = g[c] / V }
        return g
    }

    // MARK: interpolate(cell field) -> face field (linear, weight 0.5)
    public func interpolate(_ field: [Double]) -> [Double] {
        var out = [Double](repeating: 0, count: mesh.internalFaces.count)
        for (f, face) in mesh.internalFaces.enumerated() {
            out[f] = 0.5 * (field[face.owner] + field[face.neighbour])
        }
        return out
    }

    // MARK: flux(HbyA) -> phiHbyA,  interpolate(HbyA)_f . Sf
    //
    // Boundary flux is the known wall flux U_b . Sf, which is zero for all cavity
    // walls (no penetration), giving a globally conservative phiHbyA.
    public func flux(_ field: [Vector2], boundaryVelocity: (BoundaryFace) -> Vector2) -> SurfaceScalarField {
        var phi = SurfaceScalarField(mesh: mesh)
        for (f, face) in mesh.internalFaces.enumerated() {
            let vf = 0.5 * (field[face.owner] + field[face.neighbour])
            phi.internalField[f] = vf.dot(face.sf)
        }
        for (b, bf) in mesh.boundaryFaces.enumerated() {
            phi.boundaryField[b] = boundaryVelocity(bf).dot(bf.sf)
        }
        return phi
    }
}
