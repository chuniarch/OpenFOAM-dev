// LinearSolver — iterative solvers for the LDU systems.
//
//   conjugateGradient : SPD systems (the pressure equation) — like PCG/DIC.
//   gaussSeidel       : general systems (the momentum equation) — like
//                       smoothSolver/symGaussSeidel.
//
// For M0 the preconditioner is a simple Jacobi (diagonal) scaling rather than
// OpenFOAM's DIC; this keeps the code short and is a clean later upgrade.
//
// Real source for reference (this repo):
//   src/OpenFOAM/matrices/lduMatrix/solvers/   (PCG, smoothSolver, ...)

public struct SolverPerformance {
    public let initialResidual: Double
    public let finalResidual: Double
    public let iterations: Int
}

public enum LinearSolver {

    // MARK: scalar matrix-vector product, y = M x
    static func matVec(_ m: FvScalarMatrix, _ x: [Double]) -> [Double] {
        var y = [Double](repeating: 0, count: x.count)
        for i in x.indices { y[i] = m.coeffs.diag[i] * x[i] }
        for (f, face) in m.mesh.internalFaces.enumerated() {
            y[face.owner]    += m.coeffs.upper[f] * x[face.neighbour]
            y[face.neighbour] += m.coeffs.lower[f] * x[face.owner]
        }
        return y
    }

    static func dot(_ a: [Double], _ b: [Double]) -> Double {
        var s = 0.0
        for i in a.indices { s += a[i] * b[i] }
        return s
    }

    /// L1-normalised residual, comparable to OpenFOAM's reported residual.
    static func residualNorm(_ r: [Double]) -> Double {
        var s = 0.0
        for v in r { s += abs(v) }
        return s / Double(max(r.count, 1))
    }

    // MARK: Conjugate Gradient (SPD), Jacobi-preconditioned
    public static func conjugateGradient(_ m: FvScalarMatrix, x: inout [Double],
                                         tolerance: Double, relTol: Double,
                                         maxIter: Int = 1000) -> SolverPerformance {
        let n = x.count
        var r = LinearSolver.matVec(m, x)
        for i in 0..<n { r[i] = m.source[i] - r[i] }

        let normFactor = max(LinearSolver.residualNorm(m.source), 1e-30)
        let initRes = LinearSolver.residualNorm(r) / normFactor
        if initRes < tolerance {
            return SolverPerformance(initialResidual: initRes, finalResidual: initRes, iterations: 0)
        }

        let invDiag = m.coeffs.diag.map { 1.0 / $0 }
        var z = [Double](repeating: 0, count: n)
        for i in 0..<n { z[i] = invDiag[i] * r[i] }   // Jacobi precondition
        var p = z
        var rzOld = LinearSolver.dot(r, z)

        var res = initRes
        var iter = 0
        while iter < maxIter {
            let Ap = LinearSolver.matVec(m, p)
            let alpha = rzOld / max(LinearSolver.dot(p, Ap), 1e-30)
            for i in 0..<n { x[i] += alpha * p[i]; r[i] -= alpha * Ap[i] }

            res = LinearSolver.residualNorm(r) / normFactor
            iter += 1
            if res < tolerance || res < relTol * initRes { break }

            for i in 0..<n { z[i] = invDiag[i] * r[i] }
            let rzNew = LinearSolver.dot(r, z)
            let beta = rzNew / max(rzOld, 1e-30)
            for i in 0..<n { p[i] = z[i] + beta * p[i] }
            rzOld = rzNew
        }
        return SolverPerformance(initialResidual: initRes, finalResidual: res, iterations: iter)
    }

    // MARK: symmetric Gauss-Seidel for the vector momentum system
    //
    // Same scalar coefficients act on each velocity component. Sweeps forward
    // then backward (symmetric). `nSweeps` plays the role of solver iterations.
    @discardableResult
    public static func gaussSeidel(_ m: FvVectorMatrix, x: inout [Vector2],
                                   nSweeps: Int = 4) -> SolverPerformance {
        let mesh = m.mesh
        // initial residual (for reporting)
        let initRes = vectorResidual(m, x)

        func sweep(_ order: StrideThrough<Int>) {
            for c in order {
                var sum = m.source[c]
                for ref in mesh.cellFaceRefs[c] {
                    let coeff = ref.isOwner ? m.coeffs.upper[ref.face] : m.coeffs.lower[ref.face]
                    sum -= coeff * x[ref.other]
                }
                x[c] = sum / m.coeffs.diag[c]
            }
        }
        for _ in 0..<nSweeps {
            sweep(stride(from: 0, through: mesh.nCells - 1, by: 1))
            sweep(stride(from: mesh.nCells - 1, through: 0, by: -1))
        }
        let finalRes = vectorResidual(m, x)
        return SolverPerformance(initialResidual: initRes, finalResidual: finalRes, iterations: nSweeps)
    }

    static func vectorResidual(_ m: FvVectorMatrix, _ x: [Vector2]) -> Double {
        let mesh = m.mesh
        var s = 0.0
        var norm = 0.0
        for c in 0..<mesh.nCells {
            var Ax = m.coeffs.diag[c] * x[c]
            for ref in mesh.cellFaceRefs[c] {
                let coeff = ref.isOwner ? m.coeffs.upper[ref.face] : m.coeffs.lower[ref.face]
                Ax += coeff * x[ref.other]
            }
            let r = m.source[c] - Ax
            s += r.magnitude
            norm += m.source[c].magnitude
        }
        return s / max(norm, 1e-30)
    }
}
