// CavityCase — the lid-driven cavity, with the same numbers as the real
// OpenFOAM tutorial:
//   tutorials/legacy/incompressible/icoFoam/cavity/cavity
//
//   constant/physicalProperties : nu  [0 2 -1 0 0 0 0]  0.01
//   system/blockMeshDict        : 1x1 unit block, scale 0.1 -> 0.1 m square,
//                                 (20 20 1) cells
//   system/controlDict          : endTime 0.5, deltaT 0.005
//   system/fvSolution           : PISO { nCorrectors 2; nNonOrthogonalCorrectors 0 }
//   0/U  : movingWall (1 0 0) fixedValue, fixedWalls noSlip, frontAndBack empty
//   0/p  : all walls zeroGradient, frontAndBack empty
//
// This is the M0 "preset"; later cases become data files (see the architecture
// doc, §4 "case data format").
public enum CavityCase {

    public struct Config {
        public var n: Int          // cells per side
        public var length: Double  // domain side (m)
        public var nu: Double      // kinematic viscosity (m^2/s)
        public var lidSpeed: Double
        public var dt: Double
        public var endTime: Double

        public init(n: Int = 20, length: Double = 0.1, nu: Double = 0.01,
                    lidSpeed: Double = 1.0, dt: Double = 0.005, endTime: Double = 0.5) {
            self.n = n; self.length = length; self.nu = nu
            self.lidSpeed = lidSpeed; self.dt = dt; self.endTime = endTime
        }
    }

    public static func make(_ cfg: Config = Config()) -> IcoFoam {
        let mesh = StructuredMesh(nx: cfg.n, ny: cfg.n, length: cfg.length)

        // 0/U  — patch order must match mesh patch ids: [movingWall, fixedWalls]
        let U = VolVectorField(
            name: "U", dimensions: .velocity, mesh: mesh, initial: .zero,
            patchBCs: [.fixedValue(Vector2(cfg.lidSpeed, 0)),  // movingWall
                       .noSlip])                               // fixedWalls

        // 0/p  — zeroGradient on every wall
        let p = VolScalarField(
            name: "p", dimensions: .pressureKinematic, mesh: mesh, initial: 0,
            patchBCs: [.zeroGradient,   // movingWall
                       .zeroGradient])  // fixedWalls

        let piso = PisoControl(nCorrectors: 2, nNonOrthogonalCorrectors: 0,
                               momentumPredictor: true, pRefCell: 0, pRefValue: 0)

        return IcoFoam(mesh: mesh, nu: cfg.nu, dt: cfg.dt,
                       U: U, p: p, piso: piso)
    }

    /// Reynolds number based on lid speed and cavity side.
    public static func reynolds(_ cfg: Config = Config()) -> Double {
        cfg.lidSpeed * cfg.length / cfg.nu
    }
}
