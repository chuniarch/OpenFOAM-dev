// ============================================================
// Diffusion2D.ts  —— 砖块 7：二维稳态扩散 + 高斯-塞德尔
//
// 物理：一片 n × n 个正方形盒子，水静止，墨只靠扩散在盒子之间移动。
//       四周四面边界墙：钉死浓度的墙，或不透水的墙。求稳态。
// 数学：每个盒子一条方程  C_P = 分子 / 分母，四个方向各自判断「是邻居还是墙」
//       内部墙：        分子 += k·C_邻居    分母 += k      k = D·A/Δx（正方形格子，四个方向同一个 k）
//       钉死浓度的墙：  分子 += 2k·C_墙     分母 += 2k     （盒心到墙只有半格）
//       不透水的墙：    什么都不加
//       解法：高斯-塞德尔，一行一行扫，算出新值立刻写回；最大改动 < 容差 就停。
// 下标：c[j][i]，j = 第几行（y，往上数），i = 第几列（x，往右数）。
// 运行：贴进 TypeScript Playground 点 Run；或在电脑上 node Diffusion2D.ts
//       （Node 22.18 或更新的版本能直接跑 .ts 文件）。
// ============================================================

// ===== 1. 墙的描述（和一维一样） =====
type Wall =
  | { kind: "fixed"; value: number } // 钉死浓度的墙，带着墙上的浓度 [kg/m³]
  | { kind: "closed" };              // 不透水的墙

function fixedWall(value: number): Wall {
  return { kind: "fixed", value: value };
}
const closedWall: Wall = { kind: "closed" };

// 四面墙放在一起（不在最外层用 top 这个名字：浏览器里已经有全局变量 top）
type Walls = { left: Wall; right: Wall; bottom: Wall; top: Wall };

// 一面边界墙对分子、分母的贡献：钉死的加 2k，不透水的什么都不加
function addWall(wall: Wall, k: number, acc: { numerator: number; denominator: number }): void {
  switch (wall.kind) {
    case "fixed":
      acc.numerator += 2.0 * k * wall.value;
      acc.denominator += 2.0 * k;
      break;
    case "closed":
      break;
  }
}

// ===== 2. 求解器 =====
// 返回：每个盒子的浓度 c[j][i] [kg/m³]，以及一共扫了几遍。
// 四面墙都不透水时方程没有唯一解，本程序不处理这种设定。
function solveDiffusion2D(
  n: number,             // 每边的盒子个数（一共 n × n 个）
  length: number,        // 边长 L [m]
  diffusivity: number,   // 扩散系数 D [m²/s]
  area: number,          // 一道墙的面积 A [m²]
  walls: Walls,
  initialGuess = 0.0,
  tolerance = 1e-6,
  maxSweeps = 100_000,   // 保险丝
): { c: number[][]; sweeps: number } {

  if (!Number.isInteger(n) || n < 1) {
    throw new Error("每边至少要有一个盒子");
  }

  const dx = length / n;                 // 格宽 Δx = Δy [m]
  const k = diffusivity * area / dx;     // 内部墙权重 [m³/s]

  // 每一行都是新造的数组；不能写 new Array(n).fill(new Array(n).fill(...))，那样所有行是同一个数组
  const c: number[][] = Array.from({ length: n }, () => new Array(n).fill(initialGuess));
  let sweeps = 0;

  while (sweeps < maxSweeps) {
    sweeps += 1;
    let maxChange = 0.0;                 // 每一遍开头清零

    for (let j = 0; j < n; j++) {        // 外层：行，从下往上
      for (let i = 0; i < n; i++) {      // 内层：列，从左往右
        const acc = { numerator: 0.0, denominator: 0.0 };

        // 四个互相独立的判断，不是 if … else if 链（角上的盒子要碰到两面墙）
        // 看左
        if (i > 0) {
          acc.numerator += k * c[j][i - 1];
          acc.denominator += k;
        } else {
          addWall(walls.left, k, acc);
        }
        // 看右
        if (i < n - 1) {
          acc.numerator += k * c[j][i + 1];
          acc.denominator += k;
        } else {
          addWall(walls.right, k, acc);
        }
        // 看下
        if (j > 0) {
          acc.numerator += k * c[j - 1][i];
          acc.denominator += k;
        } else {
          addWall(walls.bottom, k, acc);
        }
        // 看上
        if (j < n - 1) {
          acc.numerator += k * c[j + 1][i];
          acc.denominator += k;
        } else {
          addWall(walls.top, k, acc);
        }

        const newValue = acc.numerator / acc.denominator;
        maxChange = Math.max(maxChange, Math.abs(newValue - c[j][i]));
        c[j][i] = newValue;              // 就地写回
      }
    }

    if (maxChange < tolerance) {
      break;
    }
  }

  return { c: c, sweeps: sweeps };
}

// ===== 3. 打印：从最上面一行往下打，屏幕上的「上」就是物理上的「上」 =====
function report(title: string, result: { c: number[][]; sweeps: number }): void {
  console.log(`${title}（扫了 ${result.sweeps} 遍）`);
  const n = result.c.length;
  for (let j = n - 1; j >= 0; j--) {
    const row = result.c[j].map((v) => v.toFixed(3).padStart(7)).join(" ");
    console.log(`  j=${j}  ${row}`);
  }
}

// 尺子五：所有值都要落在最低和最高的钉死墙值之间
function checkBounds(result: { c: number[][] }, walls: Walls): string {
  const wallValues: number[] = [];
  for (const w of [walls.left, walls.right, walls.bottom, walls.top]) {
    if (w.kind === "fixed") wallValues.push(w.value);
  }
  const lo = Math.min(...wallValues);
  const hi = Math.max(...wallValues);
  const all = result.c.flat();
  const cMin = Math.min(...all);
  const cMax = Math.max(...all);
  // 迭代只收敛到 1e-6 左右（平场会算出 4.9999997 这样的数），所以留 1e-4 的余量
  const ok = cMin >= lo - 1e-4 && cMax <= hi + 1e-4;
  return `盒子里最小 ${cMin.toFixed(3)}、最大 ${cMax.toFixed(3)}，墙值在 ${lo} 到 ${hi} 之间 → ${ok ? "有界 ✓" : "越界 ✗"}`;
}

// ===== 4. 第 7 课的五把验收尺子（都是 5 × 5） =====
const L = 0.1;     // 边长 [m]
const D = 1e-9;    // 墨在水里的扩散系数 [m²/s]
const A = 1e-4;    // 一道墙的面积 [m²]
const N = 5;

const ruler1: Walls = { left: fixedWall(10), right: fixedWall(0), bottom: closedWall,   top: closedWall };
const ruler2: Walls = { left: fixedWall(5),  right: fixedWall(5), bottom: fixedWall(5), top: fixedWall(5) };
const ruler3: Walls = { left: fixedWall(10), right: fixedWall(0), bottom: fixedWall(0), top: fixedWall(0) };
const ruler4: Walls = { left: fixedWall(0),  right: fixedWall(0), bottom: fixedWall(0), top: fixedWall(10) };

const r1 = solveDiffusion2D(N, L, D, A, ruler1);
const r2 = solveDiffusion2D(N, L, D, A, ruler2);
const r3 = solveDiffusion2D(N, L, D, A, ruler3);
const r4 = solveDiffusion2D(N, L, D, A, ruler4);

report("尺子一 · 左钉死 10，右钉死 0，上下不透水（每一行都该是 9 7 5 3 1）", r1);
report("尺子二 · 四面都钉死 5（全该是 5）", r2);
report("尺子三 · 左钉死 10，另三面钉死 0（第 0 行 = 第 4 行，第 1 行 = 第 3 行）", r3);
console.log(`  中心 c[2][2] = ${r3.c[2][2].toFixed(3)}（该是 2.500）`);
report("尺子四 · 上钉死 10，另三面钉死 0（中心该是 2.500，每行左右对称）", r4);
console.log(`  中心 c[2][2] = ${r4.c[2][2].toFixed(3)}`);

console.log("尺子五 · 有界");
console.log("  尺子一：" + checkBounds(r1, ruler1));
console.log("  尺子二：" + checkBounds(r2, ruler2));
console.log("  尺子三：" + checkBounds(r3, ruler3));
console.log("  尺子四：" + checkBounds(r4, ruler4));
