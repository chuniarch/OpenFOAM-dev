import Foundation

// ============================================================
// Diffusion1D.swift  —— 砖块 6：一维稳态扩散 + 高斯-塞德尔
//
// 物理：一排 N 个盒子，水静止，墨只靠扩散在盒子之间移动。
//       两端各一面边界墙：钉死浓度的墙，或不透水的墙。求稳态。
// 数学：每个盒子一条方程  C_P = 分子 / 分母
//       内部墙：        分子 += k·C_邻居    分母 += k      k = D·A/Δx
//       钉死浓度的墙：  分子 += 2k·C_墙     分母 += 2k     （盒心到墙只有半格）
//       不透水的墙：    什么都不加
//       解法：高斯-塞德尔，算出新值立刻写回；最大改动 < 容差 就停。
// ============================================================

// ===== 1. 墙的描述 =====
enum Wall {
    case fixed(Double)   // 钉死浓度的墙，带着墙上的浓度 [kg/m³]
    case closed          // 不透水的墙
}

// ===== 2. 求解器 =====
// 返回：每个盒子的浓度 [kg/m³]，以及一共扫了几遍。
// 两面墙都不透水时方程没有唯一解，本程序不处理这种设定。
func solveDiffusion1D(
    n: Int,                     // 盒子个数
    length: Double,             // 全长 L [m]
    diffusivity: Double,        // 扩散系数 D [m²/s]
    area: Double,               // 墙的面积 A [m²]
    left: Wall,
    right: Wall,
    initialGuess: Double = 0.0,
    tolerance: Double = 1e-6,
    maxSweeps: Int = 100_000    // 保险丝：写错时不至于永远转下去
) -> (c: [Double], sweeps: Int) {

    precondition(n >= 1, "至少要有一个盒子")

    let dx = length / Double(n)             // 格宽 Δx [m]
    let k = diffusivity * area / dx         // 内部墙权重 [m³/s]

    var c = [Double](repeating: initialGuess, count: n)
    var sweeps = 0

    while sweeps < maxSweeps {
        sweeps += 1
        var maxChange = 0.0                 // 每一遍开头清零

        for i in 0..<n {
            var numerator = 0.0             // 分子
            var denominator = 0.0           // 分母

            // 看左边：是邻居还是边界墙
            if i > 0 {
                numerator += k * c[i - 1]
                denominator += k
            } else {
                switch left {
                case .fixed(let value):
                    numerator += 2.0 * k * value
                    denominator += 2.0 * k
                case .closed:
                    break
                }
            }

            // 看右边：和看左边是两个独立的判断（只有一个盒子时，两边都是墙）
            if i < n - 1 {
                numerator += k * c[i + 1]
                denominator += k
            } else {
                switch right {
                case .fixed(let value):
                    numerator += 2.0 * k * value
                    denominator += 2.0 * k
                case .closed:
                    break
                }
            }

            let newValue = numerator / denominator
            maxChange = max(maxChange, abs(newValue - c[i]))
            c[i] = newValue                 // 就地写回：后面的盒子马上用上新值
        }

        if maxChange < tolerance {
            break
        }
    }

    return (c: c, sweeps: sweeps)
}

// ===== 3. 打印 =====
func report(_ title: String, _ result: (c: [Double], sweeps: Int)) {
    let values = result.c.map { String(format: "%.3f", $0) }.joined(separator: " ")
    print("\(title)：\(values)   （扫了 \(result.sweeps) 遍）")
}

// ===== 4. 第 6 课的六把验收尺子 =====
let L = 0.1        // 全长 [m]
let D = 1e-9       // 墨在水里的扩散系数 [m²/s]
let A = 1e-4       // 墙面积 1 cm² [m²]

report("尺子 1 · 情形甲 N=5 ", solveDiffusion1D(n: 5,  length: L, diffusivity: D,       area: A, left: .fixed(10), right: .fixed(0)))
report("尺子 2 · 情形乙 N=5 ", solveDiffusion1D(n: 5,  length: L, diffusivity: D,       area: A, left: .fixed(10), right: .closed))
report("尺子 3 · 平场   N=5 ", solveDiffusion1D(n: 5,  length: L, diffusivity: D,       area: A, left: .fixed(5),  right: .fixed(5)))
report("尺子 4 · D 放大百倍 ", solveDiffusion1D(n: 5,  length: L, diffusivity: 100 * D, area: A, left: .fixed(10), right: .fixed(0)))
report("尺子 5 · N=1        ", solveDiffusion1D(n: 1,  length: L, diffusivity: D,       area: A, left: .fixed(10), right: .fixed(0)))
report("尺子 6 · N=10       ", solveDiffusion1D(n: 10, length: L, diffusivity: D,       area: A, left: .fixed(10), right: .fixed(0)))

// ===== 5. 给插页 B：盒子数与遍数 =====
print("")
print("情形甲，盒子数与遍数：")
for n in [5, 10, 20, 40] {
    let r = solveDiffusion1D(n: n, length: L, diffusivity: D, area: A, left: .fixed(10), right: .fixed(0))
    print("N = \(n)：\(r.sweeps) 遍")
}
