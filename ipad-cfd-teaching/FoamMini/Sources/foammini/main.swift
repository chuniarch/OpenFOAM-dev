// foammini — headless CLI that runs the lid-driven cavity and prints a
// convergence trace, mimicking the console output of the real `icoFoam`.
//
// Usage:
//   swift run foammini            # default 20x20, endTime 0.5
//   swift run foammini 40 1.0     # 40x40 grid, endTime 1.0

import Foundation
import FoamMiniEngine

// --- parse args ---
let args = CommandLine.arguments
var cfg = CavityCase.Config()
if args.count > 1, let n = Int(args[1]) { cfg.n = n }
if args.count > 2, let t = Double(args[2]) { cfg.endTime = t }

print("""
/*-------------------------------------------------------------------------*\\
  FoamMini — icoFoam (PISO) on a lid-driven cavity   [teaching engine, M0]
\\*-------------------------------------------------------------------------*/
  mesh        : \(cfg.n) x \(cfg.n)   (domain \(cfg.length) m square)
  nu          : \(cfg.nu) m^2/s
  lid speed   : \(cfg.lidSpeed) m/s
  Reynolds    : \(CavityCase.reynolds(cfg))
  deltaT      : \(cfg.dt)   endTime: \(cfg.endTime)
""")

let solver = CavityCase.make(cfg)

print("\nStarting time loop\n")
let reports = solver.run(endTime: cfg.endTime) { stepIndex, r in
    if stepIndex % 20 == 0 || r.time >= cfg.endTime - 1e-12 {
        let t = String(format: "%.3f", r.time)
        let co = String(format: "%.4f", r.courantMax)
        let res = String(format: "%.2e", r.pInitialResidual)
        let cont = String(format: "%.2e", r.continuityError)
        let um = String(format: "%.4f", r.uMax)
        print("Time = \(t)  Courant max = \(co)  p residual = \(res)  "
              + "continuity = \(cont)  |U|max = \(um)")
    }
}

// --- final summary: horizontal velocity along the vertical centreline ---
let mesh = solver.mesh
let iMid = mesh.nx / 2
print("\nEnd. Final |U|max = \(String(format: "%.4f", solver.uMax()))")
print("Vertical centreline (x≈mid): y/L vs Ux/Ulid")
for j in stride(from: 0, to: mesh.ny, by: max(mesh.ny / 10, 1)) {
    let c = j * mesh.nx + iMid
    let y = mesh.centre(c).y / cfg.length
    let ux = solver.U.internalField[c].x / cfg.lidSpeed
    print(String(format: "  %.3f   % .4f", y, ux))
}

_ = reports
