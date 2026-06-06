// IcoFoam — transient solver for incompressible, laminar flow (PISO).
//
// The `step()` body is deliberately a near-line-for-line analogue of the real
// solver so that the teaching app's "function -> source" panel can map each
// statement onto OpenFOAM's icoFoam.C:
//   applications/legacy/incompressible/icoFoam/icoFoam.C
//
//     fvVectorMatrix UEqn(fvm::ddt(U) + fvm::div(phi,U) - fvm::laplacian(nu,U));
//     solve(UEqn == -fvc::grad(p));
//     // --- PISO loop
//     rAU = 1/UEqn.A();  HbyA = rAU*UEqn.H();
//     phiHbyA = fvc::flux(HbyA);
//     fvScalarMatrix pEqn(fvm::laplacian(rAU,p) == fvc::div(phiHbyA));
//     U = HbyA - rAU*fvc::grad(p);
//
// Simplifications vs real icoFoam (all noted for later milestones):
//   * orthogonal mesh -> nNonOrthogonalCorrectors not needed.
//   * Rhie-Chow transient flux correction (fvc::ddtCorr) omitted; the
//     face-based pressure Laplacian already provides the p-U coupling, which is
//     adequate for this low-Reynolds (Re~10) cavity.

public struct StepReport {
    public let time: Double
    public let courantMax: Double
    public let pInitialResidual: Double
    public let continuityError: Double
    public let uMax: Double
}

public final class IcoFoam {
    public let mesh: StructuredMesh
    public let nu: Double
    public let dt: Double
    public var piso: PisoControl

    public let U: VolVectorField
    public let p: VolScalarField
    public var phi: SurfaceScalarField

    private let fvm: Fvm
    private let fvc: Fvc

    public init(mesh: StructuredMesh, nu: Double, dt: Double,
                U: VolVectorField, p: VolScalarField, piso: PisoControl) {
        self.mesh = mesh
        self.nu = nu
        self.dt = dt
        self.U = U
        self.p = p
        self.piso = piso
        let fvcLocal = Fvc(mesh: mesh)
        self.fvm = Fvm(mesh: mesh, dt: dt)
        self.fvc = fvcLocal
        // createPhi: initial face flux from the initial velocity field.
        self.phi = fvcLocal.flux(U.internalField, boundaryVelocity: U.boundaryValue)
    }

    /// Advance one time step. Returns diagnostics for the UI / tests.
    @discardableResult
    public func step(time: Double) -> StepReport {
        let V = mesh.cellVolume

        // fvVectorMatrix UEqn(fvm::ddt(U) + fvm::div(phi,U) - fvm::laplacian(nu,U));
        let UEqn = fvm.ddt(U) + fvm.div(phi, U) - fvm.laplacian(nu, U)

        // solve(UEqn == -fvc::grad(p));
        if piso.momentumPredictor {
            var mom = UEqn
            let gradP = fvc.grad(p)
            for c in 0..<mesh.nCells { mom.source[c] -= gradP[c] * V }   // == -grad(p)
            LinearSolver.gaussSeidel(mom, x: &U.internalField, nSweeps: 4)
        }

        var pInitRes = 0.0

        // --- PISO loop ---
        for _ in 0..<max(piso.nCorrectors, 1) {
            // rAU = 1/UEqn.A();  HbyA = rAU*UEqn.H();
            let A = UEqn.A()
            let H = UEqn.H(U.internalField)
            var rAU = [Double](repeating: 0, count: mesh.nCells)
            var HbyA = [Vector2](repeating: .zero, count: mesh.nCells)
            for c in 0..<mesh.nCells {
                rAU[c] = 1.0 / A[c]
                HbyA[c] = rAU[c] * H[c]
            }

            // phiHbyA = fvc::flux(HbyA);   (boundary flux = wall velocity flux = 0)
            var phiHbyA = fvc.flux(HbyA, boundaryVelocity: U.boundaryValue)
            let rAUf = fvc.interpolate(rAU)

            // fvScalarMatrix pEqn(fvm::laplacian(rAU,p) == fvc::div(phiHbyA));
            var pEqn = fvm.laplacianSPD(rAUf, p)
            for (f, face) in mesh.internalFaces.enumerated() {
                pEqn.source[face.owner]    -= phiHbyA.internalField[f]
                pEqn.source[face.neighbour] += phiHbyA.internalField[f]
            }
            pEqn.setReference(cell: piso.pRefCell, value: piso.pRefValue)

            let perf = LinearSolver.conjugateGradient(
                pEqn, x: &p.internalField, tolerance: 1e-6, relTol: 0.05)
            pInitRes = perf.initialResidual

            // phi = phiHbyA - pEqn.flux();
            for (f, face) in mesh.internalFaces.enumerated() {
                let w = rAUf[f] * face.magSf / face.delta
                let dp = p.internalField[face.neighbour] - p.internalField[face.owner]
                phiHbyA.internalField[f] -= w * dp
            }
            phi = phiHbyA   // boundary fluxes remain 0

            // U = HbyA - rAU*fvc::grad(p);  U.correctBoundaryConditions();
            let gradP = fvc.grad(p)
            for c in 0..<mesh.nCells {
                U.internalField[c] = HbyA[c] - rAU[c] * gradP[c]
            }
            // boundary values are recomputed on demand via U.boundaryValue(...)
        }

        return StepReport(
            time: time,
            courantMax: courantMax(),
            pInitialResidual: pInitRes,
            continuityError: continuityError(),
            uMax: uMax())
    }

    /// Run from t=0 to `endTime`. Optionally observe each step's report.
    @discardableResult
    public func run(endTime: Double, onStep: ((Int, StepReport) -> Void)? = nil) -> [StepReport] {
        var reports: [StepReport] = []
        let nSteps = max(Int((endTime / dt).rounded()), 1)
        var t = 0.0
        for s in 1...nSteps {
            t += dt
            let r = step(time: t)
            reports.append(r)
            onStep?(s, r)
        }
        return reports
    }

    // MARK: diagnostics

    public func courantMax() -> Double {
        let V = mesh.cellVolume
        var sumPhi = [Double](repeating: 0, count: mesh.nCells)
        for (f, face) in mesh.internalFaces.enumerated() {
            let a = abs(phi.internalField[f])
            sumPhi[face.owner] += a
            sumPhi[face.neighbour] += a
        }
        var co = 0.0
        for c in 0..<mesh.nCells { co = max(co, 0.5 * sumPhi[c] / V * dt) }
        return co
    }

    /// Sum of |div(phi)| over cells — should approach 0 as continuity is enforced.
    public func continuityError() -> Double {
        var div = [Double](repeating: 0, count: mesh.nCells)
        for (f, face) in mesh.internalFaces.enumerated() {
            div[face.owner]    += phi.internalField[f]
            div[face.neighbour] -= phi.internalField[f]
        }
        var s = 0.0
        for v in div { s += abs(v) }
        return s
    }

    public func uMax() -> Double {
        var m = 0.0
        for v in U.internalField { m = max(m, v.magnitude) }
        return m
    }
}
