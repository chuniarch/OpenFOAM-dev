# OpenFOAM 源码学习计划 — 针对 iPad CFD 教学项目（icoFoam + cavity）

> **⚠️ 分支已重组（2026-08-28）**：本文提到的所有 `claude/*` 分支均已合并进 **`ipad-cfd-teaching/main`** 并删除。
> 一律使用该分支；新会话请**直接在其上工作并推送**，不要再新建 `claude/*` 分支
> （当初每个会话各建一个自动命名分支，正是产出散落的根源）。会话与产出的完整对照见 `CONTEXT-INDEX.md`。


> **用途**：在**新开的对话**里，专门学习本项目用到的那一小片 OpenFOAM C++ 源码。读懂它，回头看 ③`architecture.md` / ④`detailed-design.md` 就不再吃力。
> **关键便利**：本仓库 `OpenFOAM-dev` **本身就是 OpenFOAM 源码**——下列所有路径都能直接打开读（**已逐条核实存在**，2026-06-14）。
> **另一个大便宜**：本项目的 `ipad-cfd-teaching/FoamMini/`（15 个 Swift 文件）**就是这条线的"简短可读版"**。学习法 = **先读 FoamMini 的 Swift（短、看懂逻辑）→ 再翻真实 OpenFOAM C++（认出同一个东西）**。

---

## 0. 给学习者 + 新对话接手模型的关键指示（务必先读）

1. **学习者身份**：需求方 + 学习者，自述软件工程"几乎全忘"、**不是工程师**、**目前还不懂 OpenFOAM 代码与 C++**。
2. **★教学纪律（与主线 `HANDOFF-stage4.md §0` 一致）★**：**先讲概念（大白话 + 类比）再看代码**；一次只啃一小块；**重要内容全文贴进对话**（别只让他自己去翻文件）；**判据：学习者能用自己的话复述"这块在干嘛"才算讲到位**。C++ 语法/符号不熟，随时停下来解释。
3. **目标不是读懂整个 OpenFOAM**（几十万行）。目标是读懂 **icoFoam 解 cavity** 这一条线穿过的**约 10 个文件**，建立"**从输入数据 → 流场结果**"的完整心智模型。
4. **真 C++ 的读法分两档**：① `icoFoam.C`（顶层求解器，约 100 行，读起来像数学）——**逐行读懂**；② 其余真 C++（算子/矩阵/场的实现，含 C++ 模板与宏）——**只"认结构、对概念"**，不要求看懂每个模板。逻辑理解一律先靠 FoamMini 的 Swift。
5. **每学一块都"三对账"**：真 OpenFOAM C++ ↔ FoamMini Swift ↔ `architecture.md §2` 映射表——三者讲的是同一件事，对上了才算通。

---

## 1. 为什么"看着吓人"其实"只学一小片"

- **大白话**：OpenFOAM 是个通用 CFD 框架，能解几百种问题，所以代码海量。但你只关心**一个**问题（顶盖驱动方腔），用**一个**求解器（icoFoam）。一个求解器只调用框架里很小一撮零件。
- **类比**：宜家仓库有上万种零件，但拼**这一张椅子**的说明书只用到其中 12 个螺丝和 5 块板。我们照着"这张椅子的说明书"（= icoFoam 的调用链）去仓库里**只取这几样**。
- **这条线的"故事"**（top-down，先有个全貌，细节后面填）：

```
   读入算例数据 (0/ constant/ system/)         ← 输入：边界、物性、网格、控制
        │
   建网格 Mesh + 建场 U,p,phi                   ← 数据结构：网格、场
        │
   每个时间步：
     组装动量方程 UEqn = fvm::ddt + fvm::div − fvm::laplacian   ← 算子（隐式→矩阵）
     解动量预测 solve(UEqn == −fvc::grad(p))                    ← 算子（显式→场）+ 解矩阵
     PISO 循环（解压力、修正速度与通量，让 ∇·U=0）             ← PISO 算法 + 矩阵求解器
        │
   写出/可视化流场                              ← 结果
```

---

## 2. 学习地图：本项目穿过的 OpenFOAM 文件（约 10 个）

> 路径均已核实存在。"FoamMini 镜像"= 先读这个 Swift 文件理解逻辑。

| # | 模块（是什么）| 本项目为啥需要 | FoamMini 镜像（先读这个）| 真实 OpenFOAM 路径（后翻这个）|
|---|---|---|---|---|
| A | **算例输入**（0/U,p；constant/物性；system/控制）| 一切的输入；你要会改它 | `Case/CavityCase.swift` | `tutorials/legacy/incompressible/icoFoam/cavity/cavity/` |
| B | **顶层求解器 icoFoam**（时间循环 + PISO）| 整条线的"主程序"、本项目的锚点 | `Solvers/IcoFoam.swift` | `applications/legacy/incompressible/icoFoam/icoFoam.C`（143 行）|
| C | **场 Field**（体场 U/p、面场 phi、边界条件）| 流场数据怎么存 | `Core/Fields.swift` | `src/finiteVolume/fields/GeometricFields/volFields/`、`.../surfaceFields/`、`.../fvPatchFields/` |
| D | **网格 Mesh**（cell/face、owner-neighbour 寻址）| 几何与拓扑；矩阵寻址靠它 | `Core/Mesh.swift` | `src/finiteVolume/fvMesh/`、`src/OpenFOAM/meshes/polyMesh/` |
| E | **量纲 dimensionSet**（`[0 1 -1 …]`）| 物理量的单位检查 | `Core/DimensionSet.swift` | `src/OpenFOAM/dimensionSet/dimensionSet.H` |
| F | **fvm 隐式算子**（ddt/div/laplacian → **矩阵**）| 把 PDE 离散成方程组（左端）| `Discretisation/Fvm.swift` | `src/finiteVolume/finiteVolume/fvm/`（fvmDdt/Div/Laplacian）|
| G | **fvc 显式算子**（grad/div/flux → **场**）| 用已知场算出量（右端）| `Discretisation/Fvc.swift` | `src/finiteVolume/finiteVolume/fvc/`（fvcGrad/Div/Flux）|
| H | **fvMatrix**（方程对象：`A()`/`H()`/`==`/`solve`）| 离散后的"方程组"本体 | `Matrix/FvMatrix.swift` | `src/finiteVolume/fvMatrices/fvMatrix/` |
| I | **lduMatrix + 线性求解器**（LDU 稀疏存储；PCG）| 真正把方程组解出来 | `Solvers/LinearSolver.swift` | `src/OpenFOAM/matrices/lduMatrix/lduMatrix/`、`.../solvers/PCG`、`.../smoothSolver` |
| J | **pisoControl**（PISO 循环控制）| 压力-速度耦合的调度 | `Solvers/PisoControl.swift` | `src/finiteVolume/cfdTools/general/solutionControl/pisoControl/` |

---

## 3. 分阶段学习路线（P0 → P6，建议顺序）

> 每阶段：**目标 → 读什么 → 看懂的判据（能回答出来才算过）→ 它解开了 ④ 的哪个难点**。
> 节奏：每个 P 大约就是"新对话里的一两轮"，**不赶**。先 Swift 后 C++。

### P·理论 · 物理理论预备（★开始读代码前先走一遍★ · 应需求方要求新增）

> 为什么先讲这个：读代码前，先知道"代码在算的是什么物理"。否则看见 `U/p/nu/phi` 只是符号、没有意义。本段**不碰代码**，只建立物理直觉。

**理论-A · 这是个什么物理问题（cavity）**
- 一个**方盒子**装满流体（想成一小缸油/水）。**顶盖以恒定速度向右滑**，另外三面墙不动。顶盖靠"粘性"把贴着它的流体拖着走，带动整缸转起来，形成一个**主漩涡**。
- 类比：**用勺子贴着咖啡表面匀速划一下**，整杯会转起来、底部回流。cavity 就是把这个装进方盒子、取一个 2D 切片。
- 它是 CFD 的"Hello World"：几何最简、物理却丰富（漩涡、边界层、角涡），有公认参考解。

**理论-B · 控制方程：不可压缩 Navier–Stokes（就两条）**
1. **动量方程**（牛顿第二定律用在流体微团上，"受力 = 质量×加速度"）：
   `∂U/∂t + ∇·(UU) = −∇p + ν∇²U`　——左：速度随时间变 + 对流；右：压力推 + 粘性磨。
2. **连续性方程**（质量守恒；不可压 = 体积守恒）：`∇·U = 0`　——流进多少就得流出多少，不凭空多/少。

逐项对应（也是 P1/P3 要看的代码）：

| 数学项 | 物理含义（大白话）| 代码 |
|---|---|---|
| `∂U/∂t` | 某点速度**随时间怎么变**（不稳态）| `fvm::ddt(U)` |
| `∇·(UU)` | **对流**：流体把自己的动量"随流带走" | `fvm::div(phi,U)` |
| `ν∇²U` | **粘性扩散**：内摩擦把速度差抹平 | `fvm::laplacian(nu,U)` |
| `−∇p` | **压力梯度**：流体被从高压推向低压 | `fvc::grad(p)` |
| `∇·U=0` | **连续性**：不可压 → 导出"压力方程" | PISO 的 pEqn |

**理论-C · 四个变量是什么、怎么从现实理解（★最想问的★）**

| 变量 | 是什么 | 现实直觉 | 单位/量纲 |
|---|---|---|---|
| **U 速度场**（矢量）| 盒里每点流体"朝哪、多快"——每点一个箭头 | 天气图上的风向箭头，但画的是缸里流体 | m/s，`[0 1 -1 …]`；2D 有 Ux,Uy |
| **p 压力场**（标量）| 每点流体被"挤/推"的程度，驱动流动 | 水管里的压力：水从被挤处流向松弛处 | **运动学压力=真压力/密度**，单位 m²/s²、`[0 2 -2 …]`（**不是 Pa**！）|
| **ν 运动粘度**（常数）| 流体的"粘稠/拖拽"程度（÷密度）| 蜂蜜 vs 水：蜂蜜 ν 大、难搅、漩涡温吞；水 ν 小、易转 | m²/s，`[0 2 -1 …]`；cavity 取 0.01 |
| **φ(phi) 面通量**（面上标量）| 每条"小窗口"每秒**穿过多少体积流量**（=U 在面上投影 U·Sf）| 量"相邻两房间的窗口每秒过多少升水" | 由 U 算出、活在**面**上（不在 cell 中心）|

两个常见困惑澄清：
- **p 是"运动学压力" p/ρ**——所以量纲是 m²/s² 而非帕斯卡。不可压里只有压力的**差/梯度**有意义、绝对值无所谓，故需 `setReference` 把某 cell 压力"钉"个基准（否则方程不唯一）。
- **为啥单独有 φ**：有限体积法天然按"穿过面的流量"记账（对流、连续性都是面上的事）。φ 就是这本"窗口流量账"，由 U 推出。

**理论-D · 一个数概括全局：雷诺数 Re**
- `Re = U·L/ν = 惯性/粘性`。cavity：盖速 1、盒边 0.1、ν=0.01 → **Re=10**，很低。
- 低 Re = **粘性主导、流动温吞有序（层流）**，像搅冷蜂蜜；高 Re = 惯性主导、紊乱（湍流），像激流。
- 因为 Re=10 是层流，icoFoam（**层流、无湍流模型**）才够用，且数值稳定、好教学。

**看懂判据**：能用自己的话讲——这是个什么物理场景；动量方程每项在说什么；U/p/ν/φ 各是什么、各举一个现实例子；为什么 Re 低就是层流。

### P0 · 先看"输入长什么样"（不是代码，是数据 —— 最易上手）
- **读什么**：cavity 算例三件套 `tutorials/legacy/incompressible/icoFoam/cavity/cavity/` 的 `0/U`、`0/p`、`constant/physicalProperties`、`system/{controlDict,fvSchemes,fvSolution,blockMeshDict}`；对照 `FoamMini/.../CavityCase.swift`。
- **判据**：能说清——这个案例是个**方盒子、顶盖向右滑**；`movingWall` 速度 (1,0,0)、其余墙 noSlip；`nu=0.01`；时间步 `deltaT=0.005` 跑到 `0.5`；PISO 修正 2 次。
- **解开 ④ 的**：④-5 编辑闭环、`CaseData` 都是在编辑这堆输入。

### P1 · 读顶层求解器 icoFoam.C（把算子当黑盒，先抓"故事"）
- **读什么**：先读 `FoamMini/.../IcoFoam.swift` 的 `step()`（约 60 行，带注释）；再逐行读真 `icoFoam.C`（L67–130 是正文）。**把 `fvm::*`/`fvc::*` 当黑盒**，只看整体流程：组装 UEqn → 动量预测 → PISO{解压力 → 修正通量 → 修正速度}。
- **判据**：能在 `icoFoam.C` 上**用手指出**：哪几行组装动量方程、哪行解动量、PISO 循环从哪到哪、哪行解压力、哪行修正速度。能讲"它为什么要循环修正 2 次"。
- **解开 ④ 的**：④-1 整块（求解游标）就是把这段 `step()` 切成相位——读懂这段，④-1 的"15 个相位"立刻就懂了。

### P2 · 三块地基数据结构：场 / 网格 / 量纲
- **读什么**：`Fields.swift`（体场 = 内部值 + 每个 patch 一个边界条件；面场 = 每条面一个值）→ 真 `volFields.H`/`surfaceFields.H` 认名字；`Mesh.swift`（**owner-neighbour 寻址**：每条内部面记住它隔开的两个 cell）→ 真 `polyMesh.H` 认概念；`DimensionSet.swift` → `dimensionSet.H`。
- **判据**：能解释"**一条内部面有 owner 和 neighbour 两个 cell**"、"场分**内部场 + 边界场**"；能说出 U 和 p 的量纲为啥不同。
- **解开 ④ 的**：④-1 里"U/p 是引用、phi 是值"、④-2 里"沿面捡系数"全建立在这。

### P3 · 核心抽象：fvm（隐式→矩阵）vs fvc（显式→场）★最重要★
- **读什么**：`Fvm.swift`（`ddt/div/laplacian` 每个都**往矩阵里填系数**）vs `Fvc.swift`（`grad/flux` **直接算出一个场**）；再翻真 `fvmLaplacian.C` / `fvcGrad.C` 认结构。
- **判据**：能用一句话讲清 **`fvm::` 返回矩阵（隐式、进方程左端）、`fvc::` 返回场（显式、进右端）**，并说出为什么 `fvm::laplacian(nu,U)` 是隐式而 `fvc::grad(p)` 是显式。（这是 OpenFOAM 最核心、也最难的一招。）
- **解开 ④ 的**：贯穿全 ④；④-2 的 aP/aN 就是 `fvm::` 填进矩阵的那些系数。

### P4 · 矩阵与求解器：fvMatrix（A/H/==/solve）+ lduMatrix（LDU）+ PCG
- **读什么**：`FvMatrix.swift`（**LDU 存法**：`diag` + 每条面的 `upper/lower`；`A()` 取对角、`H()` 取邻居贡献）→ 真 `fvMatrix.H`、`lduMatrix.H` 认结构；`LinearSolver.swift` 的 `conjugateGradient`（共轭梯度）→ 真 `PCG`。
- **判据**：能解释"矩阵为啥不按表格存、按 LDU 存"（绝大多数是 0）；能说出"取第 c 行得**沿 c 的每条面捡系数**"。
- **解开 ④ 的**：④-2 整块（探针 `row(cell)`）就在这；④-1 里 `UEqn.A()`/`UEqn.H()` 也在这。

### P5 · PISO 拼装：把 P1–P4 串回 icoFoam.C
- **读什么**：`PisoControl.swift` → 真 `pisoControl.H`；重读 `IcoFoam.swift` 的 PISO 段，这次**不当黑盒**，把每行的 `fvm/fvc/A/H/solve` 都对上 P3/P4 学的东西。理解"为什么要解一个**压力方程** `fvm::laplacian(rAU,p) == fvc::div(phiHbyA)`"——它是从"质量守恒 ∇·U=0"推出来的。
- **判据**：能讲完整一遍"一个时间步里 PISO 在干嘛"：先猜一个速度（动量预测）→ 这个速度不满足质量守恒 → 解压力方程修正它 → 用修正后的压力更新速度和通量 → 重复 2 次。
- **解开 ④ 的**：④-1 的相位序、④-3 的"两档单步"（时间步 vs PISO 子步）全靠这层理解。

### P6 ·（可选）边界条件家族 fvPatchField
- **读什么**：`Fields.swift` 里的 `VectorBC`/`ScalarBC` 枚举（fixedValue/noSlip/zeroGradient/empty）→ 真 `src/finiteVolume/fields/fvPatchFields/basic/`（fixedValue/fixedGradient…的继承树）。
- **判据**：能说出 cavity 用的 4 种边界各是什么意思；理解"真 OpenFOAM 用**类继承**、本项目 MVP 用**枚举**"（architecture §2.1 已解释为何这样简化）。
- **解开 ④ 的**：④-5 编辑闭环里改边界条件。

---

## 4. 总验收：能回答这 8 问（代码线），就"毕业"了

> **物理理论预备**的"看懂判据"见 §3 的 **P·理论** 段（能讲清动量方程各项 + U/p/ν/φ + 雷诺数）。下面 8 问针对代码理解。

1. cavity 这个案例物理上在算什么？输入有哪几类？
2. 在 `icoFoam.C` 上指出：UEqn 组装、动量预测、PISO 循环、压力求解、速度修正各在哪。
3. `fvm::` 和 `fvc::` 的根本区别是什么？各举一个例子。
4. 一条内部面的 owner/neighbour 是什么？场为什么分内部场和边界场？
5. 矩阵为什么用 LDU 稀疏存储？怎么取出某个 cell 的那一行？
6. `fvMatrix` 的 `A()` 和 `H()` 分别给出什么？PISO 为什么要用它们？
7. 完整讲一遍：一个时间步里 PISO 循环在做什么、为什么要解压力方程？
8. 用 FoamMini 的某个 Swift 文件，对上它在真实 OpenFOAM 里的"老家"。

> 答得出 1–7、做得到 8，你再回来看 ④`detailed-design.md`，会发现**全是熟面孔**。

---

## 5. 每学一块的"三对账"模板（贴给新对话用）

```
我在学 OpenFOAM 的 ___（模块名）。请按本项目纪律：
1) 先用大白话+类比讲清"它在干嘛、为什么需要它"；
2) 带我读 FoamMini 的对应 Swift 文件（短、可读），逐段讲；
3) 再翻真实 OpenFOAM C++，只"认结构、对概念"，指出同一个东西；
4) 对照 architecture.md §2 映射表确认三者一致；
5) 最后让我用自己的话复述，复述不出就换个比方再讲。
```

---

## 6. 新对话开场白（复制整段即可启动）

```
读取分支 ipad-cfd-teaching/main 上的文件
doc/ipad-cfd-teaching/openfoam-reading-plan.md
（新会话默认在 master 看不到它，请先
 git fetch origin && git checkout -B ipad-cfd-teaching/main origin/ipad-cfd-teaching/main。

我是需求方 + 学习者，软件工程几乎全忘、不是工程师、目前还不懂 OpenFOAM 代码和 C++。
我要学懂本项目（iPad CFD 教学 App，icoFoam 解 cavity）用到的那一小片 OpenFOAM 源码，
好让我回头能看懂 ③架构 / ④详细设计。

请务必先读该文件 §0 的教学纪律（大白话+类比、先概念后代码、全文贴进对话、
我能复述才算讲到位）。我对物理理论也不熟，所以请先带我走 §3 的【P·理论 物理理论预备】
建立物理直觉（NS 方程、U/p/ν/φ 各是什么、雷诺数），再从 P0 开始按 P0→P6 一阶阶学：
每块"先 FoamMini 的 Swift、后真实 OpenFOAM C++"，并按 §5 的"三对账"来。
本仓库自身就是 OpenFOAM 源码，所有路径可直接打开。一次只啃一小块，别赶。
```

---

> 本计划与主线的关系：这是为缓解"看 ④ 详细设计吃力"而开的**支线**（先补 OpenFOAM 背景）。学完回到主线 ④ 时，按需求方新要求，每块详设会**把对应的 ③ 架构原文 + ④ 详设原文 + 二者对应关系，全部贴进对话**（见主线约定）。
