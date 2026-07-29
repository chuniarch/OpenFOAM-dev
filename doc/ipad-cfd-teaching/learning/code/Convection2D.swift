import Foundation

// ============================================================
// Convection2D.swift  —— 砖块 10
// 二维「对流 + 扩散」输运：墨水被匀速水流推着走，同时向外扩散
// 显式时间推进 + 迎风格式(upwind)
// ============================================================

// ===== 1. 网格与几何 =====
let n = 21
let dx = 0.05
let dy = 0.05
let depth = 1.0                 // 2D，深度取 1

let volume = dx * dy * depth    // 盒子体积 V
let axFace = dy * depth         // x 法向面(左右墙)的面积
let ayFace = dx * depth         // y 法向面(上下墙)的面积

// ===== 2. 速度场（手工给定，且满足不可压 ∇·U = 0）=====
let u = 1.0                     // x 方向速度 m/s
let v = 0.0                     // y 方向速度

// 体积流量 F = U · A_face  —— 这就是 OpenFOAM 里的 surfaceScalarField phi
let fx = u * axFace             // 穿过左右墙 = 0.05 m³/s
let fy = v * ayFace             // 穿过上下墙 = 0

// ===== 3. 扩散 =====
let dCoeff = 0.01               // 扩散系数 D（取小 → 对流主导，现象明显）
let kx = dCoeff * axFace / dx   // 左右墙扩散权重
let ky = dCoeff * ayFace / dy   // 上下墙扩散权重

// ===== 4. 时间步：显式的「统一稳定条件」=====
// 显式更新展开后，C_P_old 的自留系数是
//     1 − (Δt/V)·( Σ扩散权重 + Σ流出的对流通量 )
// 要求它 ≥ 0（否则自己对未来产生负贡献 → 震荡发散）：
let dtLimit = volume / (2 * kx + 2 * ky + abs(fx) + abs(fy))
let dt = 0.5 * dtLimit          // 留 50% 余量
let endTime = 1.0
let numSteps = Int(endTime / dt)

// ===== 5. 场与初始条件 =====
let cInlet = 100.0                                  // 入口固定浓度
var c = [[Double]](repeating: [Double](repeating: 0.0, count: n), count: n)
let frontIndex = n / 3                              // 左侧 1/3 是浓墨
for j in 0..<n {
    for i in 0..<frontIndex { c[j][i] = 100.0 }
}

let mid = n / 2

func printCentreRow(_ label: String) {
    var line = ""
    for i in 0..<n { line += String(format: "%6.1f", c[mid][i]) }
    print("\(label) \(line)")
}

print(String(format: "Δt上限 = %.5f, 取 Δt = %.5f, 共 %d 步", dtLimit, dt, numSteps))
printCentreRow("t=0.000 ")

// ===== 6. 时间推进（显式）=====
for step in 0..<numSteps {
    var cNew = c                                     // 双缓冲：新场独立存

    for j in 0..<n {
        for i in 0..<n {
            let cP = c[j][i]
            var netInflow = 0.0                      // 四个面的「扩散 + 对流」总和

            // ---------- 西面（左）：+x 方向的通量流【进】P ----------
            if i > 0 {
                let cW = c[j][i - 1]
                netInflow += kx * (cW - cP)                          // 扩散
                netInflow += max(fx, 0) * cW - max(-fx, 0) * cP      // 对流(迎风)
            } else {
                // 入口 fixedValue：扩散用半距离 2k，对流上游是边界本身
                netInflow += 2 * kx * (cInlet - cP)
                netInflow += max(fx, 0) * cInlet - max(-fx, 0) * cP
            }

            // ---------- 东面（右）：+x 方向的通量流【出】P ----------
            if i < n - 1 {
                let cE = c[j][i + 1]
                netInflow += kx * (cE - cP)
                netInflow += max(-fx, 0) * cE - max(fx, 0) * cP
            } else {
                // 出口：扩散 zeroGradient → 0；对流迎风的上游就是自己
                netInflow += -fx * cP
            }

            // ---------- 南面（下） ----------
            if j > 0 {
                let cS = c[j - 1][i]
                netInflow += ky * (cS - cP)
                netInflow += max(fy, 0) * cS - max(-fy, 0) * cP
            }   // 否则是壁面：zeroGradient 扩散跳过，且 fy=0 无对流

            // ---------- 北面（上） ----------
            if j < n - 1 {
                let cN = c[j + 1][i]
                netInflow += ky * (cN - cP)
                netInflow += max(-fy, 0) * cN - max(fy, 0) * cP
            }

            cNew[j][i] = cP + (dt / volume) * netInflow
        }
    }

    c = cNew                                         // 整张换新场

    if (step + 1) % 12 == 0 {
        printCentreRow(String(format: "t=%.3f ", Double(step + 1) * dt))
    }
}

print("结束于 \(numSteps) 步")
