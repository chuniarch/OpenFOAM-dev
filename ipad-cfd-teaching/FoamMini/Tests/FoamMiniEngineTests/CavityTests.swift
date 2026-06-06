import XCTest
@testable import FoamMiniEngine

// Verification bar for M0: the solver must (a) build the expected mesh, (b) stay
// bounded and conservative, and (c) reproduce the qualitative lid-driven cavity
// flow (a primary recirculation: fluid dragged forward under the lid, returning
// backward lower down). Exact quantitative validation against Ghia et al. is a
// later milestone.
final class CavityTests: XCTestCase {

    func testMeshTopology() {
        let mesh = StructuredMesh(nx: 20, ny: 20, length: 0.1)
        XCTAssertEqual(mesh.nCells, 400)
        // internal faces: (nx-1)*ny + nx*(ny-1)
        XCTAssertEqual(mesh.internalFaces.count, 19 * 20 + 20 * 19)
        // boundary faces: 2*nx + 2*ny
        XCTAssertEqual(mesh.boundaryFaces.count, 2 * 20 + 2 * 20)
    }

    func testDimensionsBracketed() {
        XCTAssertEqual(DimensionSet.velocity.bracketed, "[0 1 -1 0 0 0 0]")
        XCTAssertEqual(DimensionSet.kinematicViscosity.bracketed, "[0 2 -1 0 0 0 0]")
    }

    func testReynolds() {
        XCTAssertEqual(CavityCase.reynolds(), 10.0, accuracy: 1e-9)
    }

    func testCavityIsBoundedAndConservative() {
        let solver = CavityCase.make()
        solver.run(endTime: 0.5)

        // No NaNs / blow-up: max speed must not exceed the lid speed by much.
        let umax = solver.uMax()
        XCTAssertFalse(umax.isNaN)
        XCTAssertLessThan(umax, 1.05, "velocity should be bounded by the lid speed")

        // Continuity should be well enforced after the PISO correctors.
        XCTAssertLessThan(solver.continuityError(), 1e-3)
    }

    func testCavityRecirculation() {
        let solver = CavityCase.make()
        solver.run(endTime: 0.5)

        let mesh = solver.mesh
        let iMid = mesh.nx / 2

        // Near the lid the centreline flow follows the lid (+x).
        let topCell = (mesh.ny - 1) * mesh.nx + iMid
        XCTAssertGreaterThan(solver.U.internalField[topCell].x, 0.0)

        // Lower down on the centreline the return flow is negative (-x) somewhere.
        var sawReturn = false
        for j in 0..<(mesh.ny / 2) {
            if solver.U.internalField[j * mesh.nx + iMid].x < 0 { sawReturn = true; break }
        }
        XCTAssertTrue(sawReturn, "expected a return flow (Ux<0) in the lower half")
    }
}
