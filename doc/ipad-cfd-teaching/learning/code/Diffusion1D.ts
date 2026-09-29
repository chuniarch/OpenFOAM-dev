// ============================================================
// Diffusion1D.ts  —— 砖块 6：一维稳态扩散 + 高斯-塞德尔
//
// 物理：一排 N 个盒子，水静止，墨只靠扩散在盒子之间移动。
//       两端各一面边界墙：钉死浓度的墙，或不透水的墙。求稳态。
// 数学：每个盒子一条方程  C_P = 分子 / 分母
//       内部墙：        分子 += k·C_邻居    分母 += k      k = D·A/Δx
//       钉死浓度的墙：  分子 += 2k·C_墙     分母 += 2k     （盒心到墙只有半格）
//       不透水的墙：    什么都不加
//       解法：高斯-塞德尔，算出新值立刻写回；最大改动 < 容差 就停。
// 运行：贴进 TypeScript Playground 点 Run；或在电脑上 node Diffusion1D.ts
//       （Node 22.18 或更新的版本能直接跑 .ts 文件）。
// ============================================================

// ===== 1. 墙的描述 =====
// 联合类型：一面墙要么是「钉死的，带一个值」，要么是「不透水的，什么都不带」。
type Wall =
  | { kind: "fixed"; value: number } // 钉死浓度的墙，带着墙上的浓度 [kg/m³]
  | { kind: "closed" };              // 不透水的墙

function fixedWall(value: number): Wall {
  return { kind: "fixed", value: value };
}
const closedWall: Wall = { kind: "closed" };

// ===== 2. 求解器 =====
// 返回：每个盒子的浓度 [kg/m³]，以及一共扫了几遍。
// 两面墙都不透水时方程没有唯一解，本程序不处理这种设定。
function solveDiffusion1D(
  n: number,             // 盒子个数
  length: number,        // 全长 L [m]
  diffusivity: number,   // 扩散系数 D [m²/s]
  area: number,          // 墙的面积 A [m²]
  left: Wall,
  right: Wall,
  initialGuess = 0.0,
  tolerance = 1e-6,
  maxSweeps = 100_000,   // 保险丝：写错时不至于永远转下去
): { c: number[]; sweeps: number } {

  if (!Number.isInteger(n) || n < 1) {
    throw new Error("至少要有一个盒子");
  }

  const dx = length / n;                 // 格宽 Δx [m]
  const k = diffusivity * area / dx;     // 内部墙权重 [m³/s]

  const c: number[] = new Array(n).fill(initialGuess);
  let sweeps = 0;

  while (sweeps < maxSweeps) {
    sweeps += 1;
    let maxChange = 0.0;                 // 每一遍开头清零

    for (let i = 0; i < n; i++) {
      let numerator = 0.0;               // 分子
      let denominator = 0.0;             // 分母

      // 看左边：是邻居还是边界墙
      if (i > 0) {
        numerator += k * c[i - 1];
        denominator += k;
      } else {
        switch (left.kind) {
          case "fixed":
            numerator += 2.0 * k * left.value;
            denominator += 2.0 * k;
            break;
          case "closed":
            break;
        }
      }

      // 看右边：和看左边是两个独立的判断（只有一个盒子时，两边都是墙）
      if (i < n - 1) {
        numerator += k * c[i + 1];
        denominator += k;
      } else {
        switch (right.kind) {
          case "fixed":
            numerator += 2.0 * k * right.value;
            denominator += 2.0 * k;
            break;
          case "closed":
            break;
        }
      }

      const newValue = numerator / denominator;
      maxChange = Math.max(maxChange, Math.abs(newValue - c[i]));
      c[i] = newValue;                   // 就地写回：后面的盒子马上用上新值
    }

    if (maxChange < tolerance) {
      break;
    }
  }

  return { c: c, sweeps: sweeps };
}

// ===== 3. 打印 =====
function report(title: string, result: { c: number[]; sweeps: number }): void {
  const values = result.c.map((v) => v.toFixed(3)).join(" ");
  console.log(`${title}：${values}   （扫了 ${result.sweeps} 遍）`);
}

// ===== 4. 第 6 课的六把验收尺子 =====
const L = 0.1;     // 全长 [m]
const D = 1e-9;    // 墨在水里的扩散系数 [m²/s]
const A = 1e-4;    // 墙面积 1 cm² [m²]

// 参数顺序：盒子数, 全长, 扩散系数, 墙面积, 左墙, 右墙
report("尺子 1 · N=5  左钉死 10 右钉死 0", solveDiffusion1D(5,  L, D,       A, fixedWall(10), fixedWall(0)));
report("尺子 2 · N=5  左钉死 10 右不透水", solveDiffusion1D(5,  L, D,       A, fixedWall(10), closedWall));
report("尺子 3 · N=5  两面都钉死 5     ", solveDiffusion1D(5,  L, D,       A, fixedWall(5),  fixedWall(5)));
report("尺子 4 · 同尺子 1，D 放大百倍  ", solveDiffusion1D(5,  L, 100 * D, A, fixedWall(10), fixedWall(0)));
report("尺子 5 · N=1  左钉死 10 右钉死 0", solveDiffusion1D(1,  L, D,       A, fixedWall(10), fixedWall(0)));
report("尺子 6 · N=10 左钉死 10 右钉死 0", solveDiffusion1D(10, L, D,       A, fixedWall(10), fixedWall(0)));

// ===== 5. 给插页 B：盒子数与遍数 =====
console.log("");
console.log("左钉死 10、右钉死 0，盒子数与遍数：");
for (const n of [5, 10, 20, 40]) {
  const r = solveDiffusion1D(n, L, D, A, fixedWall(10), fixedWall(0));
  console.log(`N = ${n}：${r.sweeps} 遍`);
}
