// Fvm — IMPLICIT finite-volume discretisation: each operator returns a *matrix*
// contribution. Mirrors OpenFOAM's `Foam::fvm::` namespace.
//
//   fvm::ddt        -> transient term, into diag + source
//   fvm::div        -> convection (Gauss linear / central differencing)
//   fvm::laplacian  -> diffusion (Gauss linear, orthogonal)
//
// The whole point of `fvm` vs `fvc` (Fvc.swift) is: `fvm` assembles matrix
// coefficients for the *unknown* field (the implicit part, the left-hand side),
// whereas `fvc` evaluates a quantity from a *known* field (explicit, RHS).
//
// Real source for reference (this repo):
//   src/finiteVolume/finiteVolume/fvm/   (fvmDdt, fvmDiv, fvmLaplacian)
//
// Sign convention used throughout: the matrix `M` and `source` are assembled so
// the assembled equation reads `M x = source`. Each term moves its known
// (constant) part to `source`.

public struct Fvm {
    public let mesh: StructuredMesh
    public let dt: Double

    public init(mesh: StructuredMesh, dt: Double) {
        self.mesh = mesh
        self.dt = dt
    }

    // MARK: ddt(U) — Euler implicit transient term
    //
    //   d/dt(U) * V  ≈  V/dt * (U - U_old)
    // contributes  V/dt  to the diagonal and  V/dt * U_old  to the source.
    public func ddt(_ U: VolVectorField) -> FvVectorMatrix {
        var m = FvVectorMatrix(mesh: mesh)
        let rDtV = mesh.cellVolume / dt
        for c in 0..<mesh.nCells {
            m.coeffs.diag[c] += rDtV
            m.source[c] += rDtV * U.internalField[c]   // U_old = current value
        }
        return m
    }

    // MARK: div(phi, U) — convection, central differencing (Gauss linear)
    //
    // For internal face f (owner o -> neighbour n) with volumetric flux F = phi:
    //   face value U_f = 0.5(U_o + U_n)  and the term contributes  F * U_f.
    // Boundary convective fluxes are zero for the cavity (no through-flow walls).
    public func div(_ phi: SurfaceScalarField, _ U: VolVectorField) -> FvVectorMatrix {
        var m = FvVectorMatrix(mesh: mesh)
        for (f, face) in mesh.internalFaces.enumerated() {
            let F = phi.internalField[f]
            m.coeffs.diag[face.owner]    += 0.5 * F
            m.coeffs.upper[f]            += 0.5 * F
            m.coeffs.diag[face.neighbour] -= 0.5 * F
            m.coeffs.lower[f]            -= 0.5 * F
        }
        // Boundary: F_b = U_b . Sf = 0 on all cavity walls -> no contribution.
        return m
    }

    // MARK: laplacian(gamma, U) — diffusion (Gauss linear, orthogonal)
    //
    //   div(gamma grad U) , face weight w_f = gamma * |Sf| / delta.
    // Internal: contributes Σ w_f (U_n - U_o).
    // Boundary: Dirichlet patches contribute gamma*|Sf|/delta_b * (U_b - U_o).
    public func laplacian(_ gamma: Double, _ U: VolVectorField) -> FvVectorMatrix {
        var m = FvVectorMatrix(mesh: mesh)
        for (f, face) in mesh.internalFaces.enumerated() {
            let w = gamma * face.magSf / face.delta
            m.coeffs.diag[face.owner]    -= w
            m.coeffs.diag[face.neighbour] -= w
            m.coeffs.upper[f]            += w
            m.coeffs.lower[f]            += w
        }
        for bf in mesh.boundaryFaces {
            guard U.patchBCs[bf.patch].fixedVectorValue != nil else { continue } // zeroGradient -> 0
            let w = gamma * bf.magSf / bf.delta
            let Ub = U.boundaryValue(bf)
            m.coeffs.diag[bf.cell] -= w
            m.source[bf.cell] -= w * Ub
        }
        return m
    }

    // MARK: laplacian(gammaField, p) — scalar pressure diffusion
    //
    // `gammaFace` already holds the face-interpolated diffusivity (rAU_f). Built
    // as the SPD form  -L(p)  so a CG solver can be used directly:
    //   diag += w, upper -= w, lower -= w.
    // Boundary pressure BCs are zeroGradient -> boundary faces contribute nothing.
    public func laplacianSPD(_ gammaFace: [Double], _ p: VolScalarField) -> FvScalarMatrix {
        var m = FvScalarMatrix(mesh: mesh)
        for (f, face) in mesh.internalFaces.enumerated() {
            let w = gammaFace[f] * face.magSf / face.delta
            m.coeffs.diag[face.owner]    += w
            m.coeffs.diag[face.neighbour] += w
            m.coeffs.upper[f]            -= w
            m.coeffs.lower[f]            -= w
        }
        return m
    }
}
