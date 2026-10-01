// ============================================================
// Diffusion1DTransient.ts  —— 砖块 8：一维非稳态扩散，显式时间推进
//
// 物理：一排 N 个盒子，水静止，墨只靠扩散移动；看它一步一步怎么变。
// 数学：V × (C_新 − C_旧) / Δt = Σ w × (C_对面,旧 − C_旧)      右边全用这一步开头的值
//       ⇒ C_新 = C_旧 + r × Σ m × (C_对面,旧 − C_旧)，   r = D × Δt / Δx²
//       m：内部墙 1，钉死浓度的墙 2（对面是墙值），不透水的墙 0（不写）
// 读写分开：右边只读 c，只写 cNew；一步算完再 c = cNew。
// 运行：贴进 TypeScript Playground 点 Run；或 node Diffusion1DTransient.ts（Node 22.18 起）。
// ============================================================

// ===== 1. 墙的描述（和第 6 课一样） =====
type Wall =
  | { kind: "fixed"; value: number } // 钉死浓度的墙 [kg/m³]
  | { kind: "closed" };              // 不透水的墙

function fixedWall(value: number): Wall {
  return { kind: "fixed", value: value };
}
const closedWall: Wall = { kind: "closed" };

// 一面边界墙的贡献：m × (墙值 − 自己)，钉死的 m = 2，不透水的不写
function wallTerm(wall: Wall, self: number): number {
  switch (wall.kind) {
    case "fixed":
      return 2 * (wall.value - self);
    case "closed":
      return 0;
  }
}

// ===== 2. Δt 的上限：每个盒子自己留下的系数 1 − r × Σm 不能小于 0 =====
function maxR(n: number, left: Wall, right: Wall): number {
  let worst = 0; // 所有盒子里最大的 Σm
  for (let i = 0; i < n; i++) {
    let m = 0;
    m += i > 0 ? 1 : left.kind === "fixed" ? 2 : 0;
    m += i < n - 1 ? 1 : right.kind === "fixed" ? 2 : 0;
    worst = Math.max(worst, m);
  }
  return worst > 0 ? 1 / worst : Infinity;
}

// ===== 3. 走一步：只读 c，只写 cNew =====
function step(c: number[], r: number, left: Wall, right: Wall): number[] {
  const n = c.length;
  const cNew: number[] = new Array(n).fill(0); // 新数组；不能写 const cNew = c（那是同一个数组）
  for (let i = 0; i < n; i++) {
    let net = 0;
    // 看左
    if (i > 0) {
      net += c[i - 1] - c[i];
    } else {
      net += wallTerm(left, c[i]);
    }
    // 看右（和看左是两个独立的判断）
    if (i < n - 1) {
      net += c[i + 1] - c[i];
    } else {
      net += wallTerm(right, c[i]);
    }
    cNew[i] = c[i] + r * net;
  }
  return cNew;
}

// ===== 4. 走很多步，打印指定的几步 =====
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
  showSteps: number[],   // 要打印的步数
  maxSteps: number,      // 最多走几步
  tolerance = 1e-6,      // 最大改动小于它就报告「停住了」并结束
): void {
  const limit = maxR(initial.length, left, right);
  console.log(`${title}（r = ${r}，自留系数不为负的上限 r ≤ ${limit.toFixed(4)}${r > limit ? "，超了！" : ""}）`);
  console.log(`  第 0 步：${initial.map((v) => v.toFixed(3)).join(" ")}   总和 ${sum(initial).toFixed(3)}`);

  let c = initial.slice(); // 复制一份，不改调用者的数组
  for (let s = 1; s <= maxSteps; s++) {
    const cNew = step(c, r, left, right);
    let maxChange = 0;
    for (let i = 0; i < c.length; i++) maxChange = Math.max(maxChange, Math.abs(cNew[i] - c[i]));
    c = cNew;

    if (showSteps.includes(s)) {
      console.log(`  第 ${s} 步：${c.map((v) => v.toFixed(3)).join(" ")}   总和 ${sum(c).toFixed(3)}`);
    }
    if (maxChange < tolerance) {
      console.log(`  第 ${s} 步最大改动 < ${tolerance}，停住：${c.map((v) => v.toFixed(3)).join(" ")}   总和 ${sum(c).toFixed(3)}`);
      return;
    }
  }
  console.log(`  走满 ${maxSteps} 步还没停`);
}

// ===== 5. 第 8 课的三把尺子 =====
const drop = [0, 0, 10, 0, 0]; // 墨滴在 3 号

run("尺子 1 · 两面不透水，墨滴在中间", drop, 0.25, closedWall, closedWall, [1, 2, 3], 100000);
run("尺子 2 · 同上，Δt 太大", drop, 0.6, closedWall, closedWall, [1, 2, 3, 20], 20);
run("尺子 3 · 左钉死 10，右钉死 0，初值全 0", [0, 0, 0, 0, 0], 0.25, fixedWall(10), fixedWall(0), [1, 2], 100000);

// 换成真实单位：r = D × Δt / Δx²
const D = 1e-9;          // 墨在水里的扩散系数 [m²/s]
const dx = 0.1 / 5;      // 管长 0.1 m，5 个盒子 [m]
const dt = 0.25 * dx * dx / D;
console.log(`r = 0.25 时一步 Δt = ${dt.toFixed(0)} 秒，约 ${(dt / 3600).toFixed(1)} 小时`);
