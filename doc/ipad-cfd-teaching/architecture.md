# iPad CFD 教学程序 · 架构设计文档

> 版本：草案 v0.1　|　日期：2026-06-04
> 定位：**OpenFOAM 的「引桥课」**——在 iPad 上零环境成本走通一次「从输入到流场」的完整闭环，并直接对照真实 OpenFOAM 源码，让初学者带着心智模型去面对真正的工具。

---

## 0. 已定决策汇总（本文档的前提）

| 项 | 决策 | 理由 |
|---|---|---|
| 求解引擎语言 | **Swift** | 好调试、好优化、无桥接复杂度、上架成熟 |
| 源码展示 | **直接展示真实 OpenFOAM C++ 源码**（非手写、非 Swift） | OpenFOAM 本就是 C++，展示真源码即「源码入门」 |
| Swift 与展示的关系 | Swift 引擎是真实 C++ 的**忠实移植**，靠「函数↔源码映射表」对齐 | 不是「骗」，是「对照还原」；语义必须一致 |
| 首个案例 | **icoFoam + cavity（顶盖驱动方腔，2D）** | OpenFOAM 入门第一课，源码仅约 100 行，是完美锚点 |
| 案例组织 | **数据驱动、可插拔**：案例 = 字典数据 + solver 标识 | 加新案例 = 加数据，不动 UI/框架 |
| 数学公式渲染 | **SwiftMath**（原生，离线，数学模式 LaTeX 子集） | PDE 标准记号足够；快、无 WebView |
| 可视化 | **Metal / SwiftUI Canvas** | 矢量场、云图、流线、残差曲线 |

---

## 1. 总体架构（分层）

```
┌──────────────────────────────────────────────────────────────┐
│  展示层  SwiftUI + Metal                                        │
│  ├─ 案例编辑器（表单 ↔ dict 文本 双向同步）                       │
│  ├─ 源码面板（真实 OpenFOAM C++，行高亮）                        │
│  ├─ 数学面板（SwiftMath 渲染 PDE）                               │
│  ├─ 结果可视化（速度矢量 / 压力云图 / 流线 / 残差曲线）            │
│  └─ 数据探针（点 cell 看 U/p 值、离散模板、矩阵系数）             │
├──────────────────────────────────────────────────────────────┤
│  联动层  ViewModel（@Observable）                               │
│  └─ 单一事实源：currentHighlightedNode / iterationState         │
│     驱动「点代码行 → 公式高亮 + 结果闪烁 + 探针更新」             │
├──────────────────────────────────────────────────────────────┤
│  引擎层  Swift FVM Core（纯计算，无 UI 依赖，可单测）             │
│  Case / Time / Mesh / Field<T> / fvm / fvc / linearSolver /    │
│  pisoControl                                                    │
├──────────────────────────────────────────────────────────────┤
│  资源层  Bundle 内嵌                                            │
│  ├─ 案例数据（0/ constant/ system/ 的结构化等价物）              │
│  ├─ 真实 OpenFOAM 源码片段（icoFoam.C 等）+ 行号锚点            │
│  └─ 「函数 ↔ 源码」映射表（JSON）                               │
└──────────────────────────────────────────────────────────────┘
```

**关键纪律：引擎层零 UI 依赖。** 引擎是一个可独立单元测试的 Swift package，UI 只读它的状态、调它的 `step()`。这样「好调试好优化」才真正成立。

---

## 2. Swift 引擎类设计 ↔ 真实 OpenFOAM 类映射

这张表是「源码入门」的骨架：用户在 UI 点到某个 Swift 概念，App 跳转展示右列真实 OpenFOAM 源码。

| Swift 引擎类型 | 职责 | 对应真实 OpenFOAM | 真实源码位置（本仓库） |
|---|---|---|---|
| `Case` | 持有 0/constant/system 三组数据 + 求解器标识 | 算例目录约定 | `tutorials/.../cavity/` |
| `Time` | 时间推进、写出控制 | `Time` / `runTime` | `src/OpenFOAM/db/Time/` |
| `DimensionSet`（7 维幂） | 量纲 `[0 1 -1 …]` 校验 | `dimensionSet` | `src/OpenFOAM/dimensionSet/` |
| `Mesh`（2D 结构化方腔） | cell/face/patch 拓扑、几何 | `polyMesh` / `fvMesh` | `src/finiteVolume/fvMesh/` |
| `Field<Scalar>` / `Field<Vector>` | 体场（internal + boundary） | `volScalarField` / `volVectorField` | `src/finiteVolume/fields/volFields/` |
| `SurfaceField<Scalar>` | 面场（如通量 `phi`） | `surfaceScalarField` | `src/finiteVolume/fields/surfaceFields/` |
| `PatchField`（fixedValue / noSlip / zeroGradient / empty） | 边界条件 | `fvPatchField` 派生类 | `src/finiteVolume/fields/fvPatchFields/` |
| `fvm`（命名空间/枚举）：`ddt/div/laplacian` | **隐式**离散 → 组装稀疏矩阵 `FvMatrix` | `Foam::fvm::` | `src/finiteVolume/finiteVolume/fvm/` |
| `fvc`：`grad/div/flux/interpolate` | **显式**计算 → 直接返回场 | `Foam::fvc::` | `src/finiteVolume/finiteVolume/fvc/` |
| `FvMatrix<T>` | 稀疏矩阵方程对象，支持 `==`、`A()`、`H()` | `fvMatrix` | `src/finiteVolume/fvMatrices/` |
| `LinearSolver`（CG/Jacobi/GaussSeidel） | 解线性系统 | `PCG` / `smoothSolver` / `GAMG` | `src/OpenFOAM/matrices/lduMatrix/solvers/` |
| `pisoControl` | PISO 循环控制 | `pisoControl` | `src/finiteVolume/cfdTools/general/solutionControl/` |

> **教学重点（差异化王牌）：`fvm` 与 `fvc` 的区分。** `fvm::` 返回矩阵（隐式，进左端），`fvc::` 返回场（显式，进右端）。这是 OpenFOAM 最难懂也最核心的抽象，必须在 UI 上可视化（见 §6 面板⑦）。

---

## 3. 引擎核心：让 Swift 顶层「方程即代码」

设计目标——Swift 的求解器顶层必须和真实 `icoFoam.C` 几乎逐行对应。

真实 OpenFOAM（`applications/legacy/incompressible/icoFoam/icoFoam.C`，节选）：

```cpp
fvVectorMatrix UEqn
(
    fvm::ddt(U) + fvm::div(phi, U) - fvm::laplacian(nu, U)
);
if (piso.momentumPredictor()) { solve(UEqn == -fvc::grad(p)); }

while (piso.correct())
{
    volScalarField rAU(1.0/UEqn.A());
    volVectorField HbyA(constrainHbyA(rAU*UEqn.H(), U, p));
    surfaceScalarField phiHbyA("phiHbyA", fvc::flux(HbyA) + ...);
    while (piso.correctNonOrthogonal())
    {
        fvScalarMatrix pEqn(fvm::laplacian(rAU, p) == fvc::div(phiHbyA));
        pEqn.solve();
        if (piso.finalNonOrthogonalIter()) phi = phiHbyA - pEqn.flux();
    }
    U = HbyA - rAU*fvc::grad(p);
    U.correctBoundaryConditions();
}
```

目标 Swift 形态（待实现，示意 API 风格）：

```swift
let UEqn = fvm.ddt(U) + fvm.div(phi, U) - fvm.laplacian(nu, U)
if piso.momentumPredictor { solve(UEqn == -fvc.grad(p)) }

while piso.correct() {
    let rAU  = 1.0 / UEqn.A()
    let HbyA = constrainHbyA(rAU * UEqn.H(), U, p)
    var phiHbyA = fvc.flux(HbyA) + fvc.interpolate(rAU) * fvc.ddtCorr(U, phi)
    while piso.correctNonOrthogonal() {
        let pEqn = fvm.laplacian(rAU, p) == fvc.div(phiHbyA)
        pEqn.solve()
        if piso.finalNonOrthogonalIter { phi = phiHbyA - pEqn.flux() }
    }
    U = HbyA - rAU * fvc.grad(p)
    U.correctBoundaryConditions()
}
```

Swift 实现要点：
- 运算符重载 `+ - * ==` 让方程可读；`FvMatrix` 实现 `==`（移项）、`A()`（对角）、`H()`（off-diagonal 贡献）。
- `fvm.*` 返回 `FvMatrix`，`fvc.*` 返回 `Field`，**类型系统强制区分隐式/显式**（编译期就教对了概念）。
- 每个算子在执行时向**联动层**广播「我正在执行 + 我对应真实源码哪一段」。

---

## 4. 案例数据格式（数据驱动，对照真实 cavity）

案例不写死在代码里，而是结构化数据。下表为首个案例 cavity 的真实取值（取自本仓库），作为数据模型字段定义依据。

### 4.1 `0/` 初始与边界场

`0/U`（`volVectorField`，`dimensions [0 1 -1 0 0 0 0]`，`internalField (0 0 0)`）：

| patch | type | value |
|---|---|---|
| movingWall | fixedValue | (1 0 0) |
| fixedWalls | noSlip | — |
| frontAndBack | empty | — |

`0/p`（`volScalarField`，`dimensions [0 2 -2 0 0 0 0]`，`internalField 0`）：

| patch | type |
|---|---|
| movingWall | zeroGradient |
| fixedWalls | zeroGradient |
| frontAndBack | empty |

### 4.2 `constant/physicalProperties`
```
nu   [0 2 -1 0 0 0 0]   0.01;
```

### 4.3 `system/` 控制字典（真实 cavity 值）

- **controlDict**：`endTime 0.5`、`deltaT 0.005`、`writeInterval 20`、`writeControl timeStep`。
- **fvSchemes**：`ddt: Euler`；`grad: Gauss linear`；`div(phi,U): Gauss linear`；`laplacian: Gauss linear orthogonal`；`interpolation: linear`；`snGrad: orthogonal`。
- **fvSolution**：`p: PCG + DIC, tol 1e-6, relTol 0.05`；`pFinal: relTol 0`；`U: smoothSolver + symGaussSeidel, tol 1e-5`；`PISO: nCorrectors 2, nNonOrthogonalCorrectors 0, pRefCell 0, pRefValue 0`。
- **blockMeshDict**：单 hex 块，`scale 0.1`，`(20 20 1)` 均匀网格，patch：movingWall（顶）、fixedWalls（左右下）、frontAndBack（empty，2D）。

### 4.4 Swift 侧建议的案例数据结构（示意）

```swift
struct CaseData: Codable {
    var solver: String                 // "icoFoam"
    var control: ControlDict           // endTime, deltaT, writeInterval...
    var schemes: FvSchemes
    var solution: FvSolution           // 含 PISO 设置
    var properties: [String: Dimensioned]   // nu = [0 2 -1 ...] 0.01
    var mesh: MeshSpec                  // 方腔：尺寸、网格数、patch 定义
    var fields: [FieldSpec]            // U, p：dimensions/internal/boundary
}
```

> 简化纪律（MVP）：网格只支持 2D 均匀笛卡尔方腔（跳过 `blockMesh` 复杂语法，但保留 patch/边界概念）；`fvSchemes` 选项先固定为 cavity 默认值并以**只读说明**呈现，第二阶段再开放可选。

---

## 5. 「函数 ↔ 真实源码」映射表（机制）

资源层放一份 JSON，把每个引擎调用/UI 元素映射到真实 OpenFOAM 源码段：

```json
[
  {
    "id": "fvm.laplacian",
    "title": "fvm::laplacian — 隐式拉普拉斯离散",
    "swiftSymbol": "Fvm.laplacian(_:_:)",
    "sourceFile": "applications/legacy/incompressible/icoFoam/icoFoam.C",
    "lineStart": 79, "lineEnd": 79,
    "explanationMD": "对扩散项隐式离散，组装进矩阵左端……",
    "latex": "\\nabla\\cdot(\\nu\\nabla U)",
    "relatedImpl": "src/finiteVolume/finiteVolume/fvm/fvmLaplacian.C"
  }
]
```

- `sourceFile/lineStart/lineEnd`：点击时展示真实源码并高亮。**源码片段随 App 内嵌**（含版权头，遵守 GPL）。
- `latex`：交给 SwiftMath 渲染（§7）。
- `explanationMD`：Markdown 解释。
- 维护这张表 = 维护「源码入门」内容，与引擎代码解耦。

> 合规提醒：OpenFOAM 为 GPL v3。内嵌其源码片段须保留许可头、标注来源，并评估本 App 的分发许可（详见 §9 未决项）。

---

## 6. 展示面板与联动数据流

9 个面板（按教学价值排序，前两个为差异化王牌）：

| # | 面板 | 来源 | 联动行为 |
|---|---|---|---|
| ① | **数学↔代码桥** | SwiftMath + 源码 | 点源码行 → 高亮对应 PDE 项 |
| ② | **数据探针** | 引擎 `FvMatrix` | 点 cell → 显示 U/p、离散模板、矩阵系数 |
| ③ | 源码面板 | 真实 OpenFOAM C++ | 当前执行行高亮 |
| ④ | 速度矢量 / 流线 | `Field<Vector>` U | 时间步推进刷新 |
| ⑤ | 压力云图 | `Field<Scalar>` p | 同上 |
| ⑥ | 残差 / Courant 曲线 | `LinearSolver` / `pisoControl` | 每迭代追加点 |
| ⑦ | 字典编辑器 | `CaseData` | 表单 ↔ dict 文本双向 |
| ⑧ | 网格 / patch 视图 | `Mesh` | 高亮 movingWall/noSlip/empty |
| ⑨ | 时间轴控制 | `Time` | 播放/暂停/单步 PISO |

联动核心——**单一事实源**：

```swift
@Observable final class SessionVM {
    var highlightedNodeID: String?     // 当前高亮的「函数↔源码」节点
    var iteration: IterationState      // 时间步、PISO 子步、各场残差
    var probedCell: Int?               // 数据探针选中的 cell
    // 引擎每步回调 → 更新此处 → SwiftUI 各面板自动刷新
}
```

「一处操作、多处响应」是教学 App 的灵魂：点 ③ 源码某行 → ① 公式高亮 + ④ 结果上闪烁受影响区域 + ② 探针显示该项贡献的矩阵系数。

---

## 7. 数学公式：SwiftMath 方案

- 库：**SwiftMath**（iosMath 维护分支），原生渲染数学模式 LaTeX 子集，离线、快、无 WebView。
- 用法：`latex` 字段（见 §5）→ `MTMathView` 渲染。
- 解释文字走 Markdown，公式走 SwiftMath，二者分区排版。
- 升级位：若日后需复杂排版/长推导/文字公式混排，对该局部改用 `WKWebView + KaTeX`，不影响整体。

PDE 锚点（cavity / icoFoam）：

$$\frac{\partial U}{\partial t} + \nabla\cdot(UU) = -\nabla p + \nu\nabla^2 U,\qquad \nabla\cdot U = 0$$

逐项对应：`fvm.ddt` ↔ ∂U/∂t；`fvm.div(phi,U)` ↔ ∇·(UU)；`fvm.laplacian(nu,U)` ↔ ν∇²U；`fvc.grad(p)` ↔ ∇p；压力修正 `fvm.laplacian(rAU,p)==fvc.div(phiHbyA)` ↔ 由 ∇·U=0 导出的泊松方程。

---

## 8. MVP 里程碑

| 阶段 | 交付 | 验收 |
|---|---|---|
| **M0 引擎内核** | Swift package：Mesh + Field + fvm/fvc + CG + PISO，跑通 cavity，CLI 输出与真实 icoFoam 趋势一致 | 顶盖驱动涡心位置、残差收敛合理 |
| **M1 可视化** | Metal 画速度矢量 + 压力云图 + 残差曲线；时间轴播放/单步 | 流场动画正确、可暂停单步 |
| **M2 源码入门** | 源码面板 + 函数↔源码映射 + SwiftMath 公式 + 数学↔代码桥 | 点函数能看真实源码+公式+解释 |
| **M3 探针 + 字典** | 数据探针（点 cell 看矩阵系数）+ 字典表单↔文本 | `fvm` 组矩阵可视、可改边界条件重算 |
| **M4 打磨发布** | 引导教程、稳定参数锁定、上架 | 全程零崩溃、必出结果 |

发布策略：**M4 即可发布**（单案例做到极致），之后按「加数据」方式迭代新案例。

---

## 9. 建议目录结构（Xcode 工程）

```
iCavity/                       # 产品工作名
├─ Engine/                     # 纯 Swift 计算，可单测，零 UI 依赖
│  ├─ Core/  (Time, DimensionSet, Mesh, Field, SurfaceField)
│  ├─ Discretisation/  (Fvm, Fvc, FvMatrix)
│  ├─ Solvers/  (LinearSolver, PisoControl, IcoFoamSolver)
│  └─ Boundary/  (PatchField 派生)
├─ App/                        # SwiftUI + Metal
│  ├─ ViewModels/  (SessionVM)
│  ├─ Panels/  (Source, Math, Vis, Probe, Dict, Mesh, Timeline)
│  └─ Render/   (Metal shaders, Canvas)
├─ Resources/
│  ├─ Cases/cavity/            # 结构化案例数据
│  ├─ Sources/                 # 内嵌真实 OpenFOAM 源码片段（含许可头）
│  └─ mapping.json             # 函数↔源码映射
└─ Tests/  (EngineTests：与参考解对拍)
```

---

## 10. 风险与未决项

| 项 | 说明 | 处置 |
|---|---|---|
| **GPL 合规** | 内嵌 OpenFOAM 源码片段 + 移植其架构，涉及 GPL v3 | 详见 §11。**原型期不阻塞**（先内嵌开发），改造列为上架前待办（§11.4）。 |
| 数值稳定性 | 新手乱改参数易发散 | 锁定 cavity 稳定参数，限制 Courant 数，预置安全范围 |
| 展示≠运行的一致性 | Swift 行为须与所展示 C++ 语义一致 | 映射表评审；引擎与真实 icoFoam 对拍 |
| 范围蔓延 | 想加 3D/湍流/复杂网格 | 严守 cavity+icoFoam 的 MVP，迭代再扩 |
| Swift 运算符重载性能 | 大量临时 Field 分配 | 教学网格小（20×20）可接受；必要时引入 expression-template 式惰性求值 |
| 触屏编辑 dict 体验 | 手敲字典差 | 表单↔文本双向同步（既解决体验又是教学法） |

---

## 11. 许可合规分析（GPL v3）

> ⚠️ 本节为工程师视角的常识梳理，非法律意见；**正式上架前须经懂开源许可的专业人士确认**。

### 11.1 背景：OpenFOAM 是 GPL v3

本仓库 `COPYING` 与 `README.org` 明确：OpenFOAM 采用 **GNU General Public License v3**。GPL 属于**传染型（copyleft）**许可——

> 任何**复制、修改、分发**了 GPL 代码而形成的新软件，整体也必须以 GPL 开源，并向用户提供完整源码。

「思想/概念」不受版权保护，「源码文本」受保护。即：**学其架构思想 → 一般安全；复制其源码文本 → 触发传染。**

### 11.2 本 App 会撞上的三类问题

| # | 场景 | 问题 | 严重度 |
|---|---|---|---|
| A | **内嵌真实 OpenFOAM 源码片段**（源码面板展示 `icoFoam.C` 等） | 复制并分发 GPL 文本 → App 整体可能被要求按 GPL 开源 | 🔴 高 |
| B | **将 OpenFOAM 架构移植为 Swift** | 灰色地带：逐字照抄 → 算衍生作品；仅借鉴概念（fvm 隐式 / fvc 显式等）并独立实现 → 通常不算 | 🟡 中 |
| C | **上架 App Store** | **GPL 与 App Store 条款直接冲突** | 🔴 高 |

**关于 C（最出名的坑）**：GPL 要求「用户可自由复制、修改、再分发」；App Store 施加 DRM 且限制再分发。二者互斥 → 含 GPL 代码的 App 上架本身即违反 GPL（历史先例：VLC 曾因此被下架）。

### 11.3 出路对比

| 方案 | 做法 | 代价 |
|---|---|---|
| ① 外链真实源码 | App 不内嵌，跳转 openfoam.org 在线源码 | 教学连贯性略降，合规最干净 |
| ② 自写等价讲解 | 源码面板展示自写的、概念等价但非逐字复制的示意代码 + 解释 | 失去「展示真源码」的权威感 |
| ③ App 整体 GPL + 不上架 App Store | 走自签名 / TestFlight / 学校自装等渠道 | 放弃 App Store，商业化受限 |
| ④ 联系 OpenFOAM 基金会获取授权 | 询问教学内嵌的特别许可 | 能否谈成不确定，但最稳妥 |
| ⑤ 仅展示概念图 + 公式 + 极简伪代码 | 完全规避复制 | 教学深度打折 |

**建议长期形态**：①（外链真源码）+ ②（自写等价讲解）组合——不复制 GPL 文本、仍可对照真实 OpenFOAM、且可上架。

### 11.4 当前阶段决策（已拍板）

> **现阶段（开发/原型期）：先直接对照、内嵌真实 OpenFOAM 源码进行开发，不为合规分心。** 待项目成熟、真正面临上架时，再按 §11.3 的方案（优先 ①+②）改造源码展示方式。

理由：原型期重点是验证教学效果与引擎正确性；合规改造主要影响「源码如何呈现」这一层，与引擎、可视化解耦，**后期替换成本可控**，不阻塞当前开发。

> 待办（移至上架前处理）：源码面板的呈现方式由「内嵌」切换为「外链 + 自写等价讲解」；确认整个 App 的分发许可策略。

## 12. 下一步

1. 评审本文档，确认 §2 类映射与 §4 案例数据结构。
2. ~~起 **M0**~~ — **已搭建**：见 `ipad-cfd-teaching/FoamMini/`（SwiftPM 包）。
   - 已含：`StructuredMesh`、`Field`、`Fvm`(ddt/div/laplacian)、`Fvc`(grad/flux/interpolate)、`FvMatrix`(A/H)、CG + Gauss-Seidel、`PisoControl`、`IcoFoam`、`CavityCase` 预设、CLI、验证测试。
   - 顶层 `IcoFoam.step()` 与真实 `icoFoam.C` 逐行对应（见包内 README 的映射表）。
   - ⚠️ **当前开发环境无 Swift 工具链且 swift.org 被网络策略拦截，代码尚未编译/运行验证**；需在 macOS/Linux 上 `swift build && swift test` 首次构建，按报错迭代。
3. 并行整理 §5 映射表首批条目（icoFoam.C 的 PISO 各行）。

> 许可合规（§11）：已决定原型期先内嵌真实源码开发、不阻塞；相关改造（外链 + 自写等价讲解、分发许可确认）列为**上架前**待办，见 §11.4。
