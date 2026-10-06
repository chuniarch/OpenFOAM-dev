// ============================================================
// ConvectionDiffusion1D.ts  —— 砖块 10B：一维对流 + 扩散，显式；量出数值扩散
//
// 物理：一根管等分成 N 个盒子，水从左往右流（速度 u），墨既被水带走，也在扩散。
//       左端是进水口（流进来的水浓度 C_进），右端是出水口。
// 数学：C_新 = C_旧 + CFL × (C_左 − C_旧) + r × [ (C_左 − C_旧) + (C_右 − C_旧) ]
//            = (1 − CFL − 2r) × C_旧 + (CFL + r) × C_左 + r × C_右
//       CFL = u × Δt / Δx（对流，迎风取上游）；r = D × Δt / Δx²（扩散）
//       自己那份 1 − CFL − 2r 不能是负的：CFL + 2r ≤ 1
// 两头：对流照第 10 课（1 号的上游是进水口，出水口不用给）；
//       扩散项在两头先不写——这一课的墨离两头很远，碰不到。
// 每一步量两个数：
//       重心 = Σ(盒号 × 浓度) / Σ浓度            公式：每步右移 CFL 格
//       方差 = Σ[浓度 × (盒号 − 重心)²] / Σ浓度   公式：每步增加 CFL × (1 − CFL) + 2r 格²
// 运行：贴进 TypeScript Playground 点 Run；或 node ConvectionDiffusion1D.ts（Node 22.18 起）。
// ============================================================

// ===== 1. 走一步：只读 c，只写 cNew =====
function step(c: number[], cfl: number, r: number, cIn: number): number[] {
  const n = c.length;
  const cNew: number[] = new Array(n).fill(0);
  for (let i = 0; i < n; i++) {
    // 对流：上游是左邻；1 号的上游是进水口
    const upstream = i > 0 ? c[i - 1] : cIn;
    const convection = cfl * (upstream - c[i]);

    // 扩散：看左、看右两个独立判断；两头先不写
    let diffusion = 0;
    if (i > 0) diffusion += c[i - 1] - c[i];
    if (i < n - 1) diffusion += c[i + 1] - c[i];

    cNew[i] = c[i] + convection + r * diffusion;
  }
  return cNew;
}

// ===== 2. 量：总和、重心、方差（盒号从 1 数） =====
function measure(c: number[]): { total: number; mean: number; variance: number } {
  let total = 0;
  let weighted = 0;
  for (let i = 0; i < c.length; i++) {
    total += c[i];
    weighted += (i + 1) * c[i];
  }
  const mean = weighted / total;
  let spread = 0;
  for (let i = 0; i < c.length; i++) {
    spread += c[i] * (i + 1 - mean) ** 2; // 一定要先减重心
  }
  return { total: total, mean: mean, variance: spread / total };
}

// ===== 3. 跑一种设定，每一步和公式对照 =====
function run(cfl: number, r: number, steps: number): void {
  const n = 40;
  const start = 10;                      // 墨全在 10 号
  const self = 1 - cfl - 2 * r;          // 自己留下的系数
  console.log(`CFL = ${cfl}，r = ${r}（自己留下 1 − CFL − 2r = ${self.toFixed(2)}${self < 0 ? "，是负的！" : ""}）`);

  let c: number[] = new Array(n).fill(0);
  c[start - 1] = 10;

  const perStep = cfl * (1 - cfl) + 2 * r; // 公式：每步新增方差
  for (let s = 1; s <= steps; s++) {
    c = step(c, cfl, r, 0);
    const m = measure(c);
    const meanFormula = start + s * cfl;
    const varFormula = s * perStep;
    console.log(
      `  第 ${String(s).padStart(2)} 步：总和 ${m.total.toFixed(3)}` +
      `  重心 ${m.mean.toFixed(3)}（公式 ${meanFormula.toFixed(3)}）` +
      `  方差 ${m.variance.toFixed(3)}（公式 ${varFormula.toFixed(3)}）`,
    );
  }
}

// ===== 4. 第 10B 课的三种设定 =====
run(0.5, 0, 10);   // 只有对流：方差每步 + 0.25，全是数值扩散
run(1, 0, 10);     // 只有对流、CFL = 1：原样平移，方差一直是 0
run(0.5, 0.1, 10); // 对流 + 扩散：方差每步 + 0.25（数值）+ 0.2（真实）= 0.45

// 换成真实单位：D_num = (u × Δx / 2) × (1 − CFL)
const u = 0.001;   // 水速 [m/s]
const dx = 0.02;   // 格宽 [m]
const D = 1e-9;    // 墨在水里真实的扩散系数 [m²/s]
const dNum = (u * dx / 2) * (1 - 0.5);
console.log(`CFL = 0.5 时 D_num = ${dNum.toExponential(1)} m²/s，是真实 D 的 ${(dNum / D).toFixed(0)} 倍`);
