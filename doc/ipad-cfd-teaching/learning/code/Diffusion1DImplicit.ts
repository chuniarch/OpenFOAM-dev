// ============================================================
// Diffusion1DImplicit.ts  —— 砖块 9：一维非稳态扩散，隐式时间推进
//
// 物理：一排 N 个盒子，水静止，墨只靠扩散移动；看它一步一步怎么变。
// 数学：V × (C_新 − C_旧) / Δt = Σ w × (C_对面,新 − C_新)      右边全用这一步结束时的值
//       ⇒ C_新 = ( (1/r) × C_旧 + Σ m × C_对面,新 ) / ( 1/r + Σm )
//       r = D × Δt / Δx²；m = w / k：内部墙 1，钉死浓度的墙 2（对面是墙值），不透水的墙 0
// 解法：两层循环。
//       外层 = 时间：一步走 Δt，第 s 步结束时的真实时间是 s × Δt。
//       内层 = 解这一步的方程：高斯-塞德尔，从旧值出发一遍遍扫，扫到最大改动 < 容差。
// Δt 只通过 r 进入更新式，所以程序里算的是 r；真实时间用 Δt = r × Δx² / D 换算出来打印。
// 运行：贴进 TypeScript Playground 点 Run；或 node Diffusion1DImplicit.ts（Node 22.18 起）。
// ============================================================

// ===== 1. 墙的描述（和第 6、8 课一样） =====
type Wall =
  | { kind: "fixed"; value: number } // 钉死浓度的墙 [kg/m³]
  | { kind: "closed" };              // 不透水的墙

function fixedWall(value: number): Wall {
  return { kind: "fixed", value: value };
}
const closedWall: Wall = { kind: "closed" };

// ===== 2. 走一步：解 5 条联立方程（内层高斯-塞德尔） =====
// cOld：这一步开头的值，整个内层都不改。返回这一步结束时的值，以及内层扫了几遍。
function implicitStep(
  cOld: number[],
  r: number,
  left: Wall,
  right: Wall,
  tolerance = 1e-10,      // 内层容差取得比外层严，r 大时总量才不漂
  maxSweeps = 100_000,    // 保险丝
): { c: number[]; sweeps: number } {
  const n = cOld.length;
  const cNew = cOld.slice(); // 猜测：先拿旧值当新值（复制一份，不能和 cOld 是同一个数组）
  const inv = 1 / r;         // 旧值这个「邻居」的权重 1/r

  let sweeps = 0;
  while (sweeps < maxSweeps) {
    sweeps += 1;
    let maxChange = 0;

    for (let i = 0; i < n; i++) {
      let numerator = inv * cOld[i];  // (1/r) × C_旧
      let denominator = inv;          // 1/r

      // 看左：邻居用 cNew 里当前最新的值（还没扫到的，就是猜测）
      if (i > 0) {
        numerator += 1 * cNew[i - 1];
        denominator += 1;
      } else if (left.kind === "fixed") {
        numerator += 2 * left.value;
        denominator += 2;
      }
      // 看右（和看左是两个独立的判断）
      if (i < n - 1) {
        numerator += 1 * cNew[i + 1];
        denominator += 1;
      } else if (right.kind === "fixed") {
        numerator += 2 * right.value;
        denominator += 2;
      }

      const value = numerator / denominator;
      maxChange = Math.max(maxChange, Math.abs(value - cNew[i]));
      cNew[i] = value;                // 内层就地写回：这是在解同一时刻的方程（第 6 课的做法）
    }

    if (maxChange < tolerance) break;
  }
  return { c: cNew, sweeps: sweeps };
}

// ===== 3. 外层：一步步往前走 =====
function sum(c: number[]): number {
  let s = 0;
  for (const v of c) s += v;
  return s;
}

function run(
  title: string,
  initial: number[],
  r: number,
  left: Wall,
  right: Wall,
  secondsPerUnitR: number, // Δx² / D：r = 1 时一步是多少秒
  showSteps: number[],
  maxSteps: number,
  stopTolerance = 1e-6,    // 一步之内最大改动 < 它，就报告停住
): void {
  const dt = r * secondsPerUnitR; // Δt = r × Δx² / D
  console.log(`${title}（r = ${r}，Δt = ${dt.toFixed(0)} 秒 ≈ ${(dt / 86400).toFixed(2)} 天）`);
  console.log(`  第 0 步（t = 0）：${initial.map((v) => v.toFixed(3)).join(" ")}   总和 ${sum(initial).toFixed(3)}`);

  let c = initial.slice();
  for (let s = 1; s <= maxSteps; s++) {
    const result = implicitStep(c, r, left, right);
    let maxChange = 0;
    for (let i = 0; i < c.length; i++) maxChange = Math.max(maxChange, Math.abs(result.c[i] - c[i]));
    c = result.c;

    const days = (s * dt / 86400).toFixed(1); // 时间在外层计数：第 s 步结束时 t = s × Δt
    if (showSteps.includes(s)) {
      console.log(`  第 ${s} 步（t ≈ ${days} 天）：${c.map((v) => v.toFixed(3)).join(" ")}   总和 ${sum(c).toFixed(3)}   内层扫了 ${result.sweeps} 遍`);
    }
    if (maxChange < stopTolerance) {
      console.log(`  第 ${s} 步（t ≈ ${days} 天）最大改动 < ${stopTolerance}，停住：${c.map((v) => v.toFixed(3)).join(" ")}`);
      return;
    }
  }
  console.log(`  走满 ${maxSteps} 步还没停`);
}

// ===== 4. 第 9 课验收表里的三道题 =====
const D = 1e-9;                  // 墨在水里的扩散系数 [m²/s]
const dx = 0.1 / 5;              // 管长 0.1 m，5 个盒子 [m]
const unit = dx * dx / D;        // Δx² / D = 400000 秒
const drop = [0, 0, 10, 0, 0];   // 墨滴在 3 号

run("两面不透水，墨滴在 3 号", drop, 0.25, closedWall, closedWall, unit, [1, 2, 3], 100000);
run("两面不透水，墨滴在 3 号，Δt 加大", drop, 0.6, closedWall, closedWall, unit, [1, 2], 100000);
run("左钉死 10，右钉死 0，初值全 0", [0, 0, 0, 0, 0], 5, fixedWall(10), fixedWall(0), unit, [1], 100000);
