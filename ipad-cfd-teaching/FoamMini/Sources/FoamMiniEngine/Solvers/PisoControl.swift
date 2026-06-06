// PisoControl — settings for the PISO pressure-velocity coupling loop, mirroring
// OpenFOAM's `pisoControl` and the `PISO { ... }` sub-dictionary of fvSolution.
//
// Real source for reference (this repo):
//   src/finiteVolume/cfdTools/general/solutionControl/

public struct PisoControl {
    public var nCorrectors: Int
    public var nNonOrthogonalCorrectors: Int
    public var momentumPredictor: Bool
    public var pRefCell: Int
    public var pRefValue: Double

    public init(nCorrectors: Int = 2,
                nNonOrthogonalCorrectors: Int = 0,
                momentumPredictor: Bool = true,
                pRefCell: Int = 0,
                pRefValue: Double = 0) {
        self.nCorrectors = nCorrectors
        self.nNonOrthogonalCorrectors = nNonOrthogonalCorrectors
        self.momentumPredictor = momentumPredictor
        self.pRefCell = pRefCell
        self.pRefValue = pRefValue
    }
}
