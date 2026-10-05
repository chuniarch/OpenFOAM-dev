// ============================================================
// Convection1D.ts  —— 砖块 10：一维纯对流，显式迎风
//
// 物理：一根管等分成 N 个盒子，水从左往右以速度 u 流动，把墨一起带走；这一课没有扩散。
//       左端是进水口，流进来的水浓度 C_进 是题目给的；右端是出水口。
// 数学：V × (C_新 − C_旧) / Δt = F × C_上游,旧 − F × C_旧        F = u × A（每秒穿过一道墙的水的体积）
//       ⇒ C_新 = (1 − CFL) × C_旧 + CFL × C_上游,旧               CFL = u × Δt / Δx
//       迎风：穿过墙的水来自上游那个盒子，所以墙上的浓度取上游的值。
//       1 号的上游是进水口（C_进）；出水口流出的就是最后一个盒子自己的水，什么都不用给。
// 读写分开：右边只读 c，只写 cNew；一步算完再 c = cNew（第 8 课的两个数组）。
// 运行：贴进 TypeScript Playground 点 Run；或 node Convection1D.ts（Node 22.18 起）。
// ============================================================

// ===== 1. 走一步 =====
function step(c: number[], cfl: number, cIn: number): number[] {
  const n = c.length;
  const cNew: number[] = new Array(n).fill(0); // 新数组，不能写 const cNew = c
  for (let i = 0; i < n; i++) {
    const upstream = i > 0 ? c[i - 1] : cIn;    // 上游：左邻；1 号的上游是进水口
    cNew[i] = (1 - cfl) * c[i] + cfl * upstream; // 自己剩 1 − CFL，上游来 CFL
  }
  return cNew;
}

// ===== 2. 打印用的小工具 =====
function sum(c: number[]): number {
  let s = 0;
  for (const v of c) s += v;
  return s;
}
function show(c: number[]): string {
  return c.map((v) => v.toFixed(3).padStart(7)).join(" ");
}

// ===== 3. 一步步往前走 =====
function run(
  title: string,
  initial: number[],
  cfl: number,
  cIn: number,
  showSteps: number[],  // 要打印的步数
  maxSteps: number,     // 最多走几步
  tolerance = 1e-6,     // 一步里最大改动小于它，就报告停住
): void {
  console.log(`${title}（C_进 = ${cIn}，CFL = ${cfl}${cfl > 1 ? "，超过 1 了！" : ""}）`);
  console.log(`  第 0 步：${show(initial)}   总和 ${sum(initial).toFixed(3)}`);

  let c = initial.slice();
  for (let s = 1; s <= maxSteps; s++) {
    // 总量记账：内部墙一进一出抵消，只剩进水口带进、出水口带走
    const expected = cfl * (cIn - c[c.length - 1]);
    const cNew = step(c, cfl, cIn);

    let maxChange = 0;
    for (let i = 0; i < c.length; i++) maxChange = Math.max(maxChange, Math.abs(cNew[i] - c[i]));
    const actual = sum(cNew) - sum(c);
    c = cNew;

    if (showSteps.includes(s)) {
      console.log(`  第 ${s} 步：${show(c)}   总和 ${sum(c).toFixed(3)}   总和变化 ${actual.toFixed(3)}（记账算出 ${expected.toFixed(3)}）`);
    }
    if (maxChange < tolerance) {
      console.log(`  第 ${s} 步最大改动 < ${tolerance}，停住：${show(c)}`);
      return;
    }
  }
}

// ===== 4. 第 10 课验收表里的四道题 =====
const drop = [0, 0, 10, 0, 0]; // 墨在 3 号
const clean = [0, 0, 0, 0, 0]; // 清水管

run("墨在 3 号，水走一格一步", drop, 1, 0, [1, 2, 3], 3);
run("墨在 3 号，水走半格一步", drop, 0.5, 0, [1, 2, 3], 3);
run("清水管，进水口浓度 10", clean, 0.5, 10, [1, 2, 3, 4], 1000);
run("墨在 3 号，CFL 太大", drop, 1.5, 0, [1, 2, 3], 3);

// 换成真实单位：CFL = u × Δt / Δx
const u = 0.001;      // 水速 1 mm/s [m/s]
const dx = 0.1 / 5;   // 管长 0.1 m，5 个盒子 [m]
console.log(`CFL = 0.5 时一步 Δt = ${(0.5 * dx / u).toFixed(1)} 秒；CFL ≤ 1 要求 Δt ≤ ${(dx / u).toFixed(1)} 秒`);
