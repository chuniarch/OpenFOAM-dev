# iPad CFD 教学程序 · 架构设计文档

> 版本：v0.3　|　日期：2026-06-23（v0.2 定于 2026-06-10）
> 修订史：v0.3 — ③架构设计收口：①§0 的 7 条决策 + FR7 后端正规化为 ADR-001～008；②裁定 D1–D5 并落为 ADR-001/009/010/011/012；③补 §1.1 引擎事件接口缺口（ADR-009）；④升级资源层契约（ADR-010）；⑤新增 §6.1 协作视图（SolverEvent 流）；⑥新增 §13 架构评审记录（断言核实 + 8 用例场景走查）。**本版冻结 ③阶段。**
> 评审状态：**§2 类映射与 §4 案例数据结构已对照本仓库逐项核实并冻结**（评审记录见 §2.1、§4.5）；**ADR 全套 12 份见 `adr/`，索引见 §0.1**；**③ 架构评审通过见 §13**。
> 合并记录（2026-08-28）：③ 阶段曾被两个会话各自冻结，产生两份 v0.3。按「保留最新修改」，
> **本文正文 §0–§13 取 2026-06-23 版**（`894b0436`，较 2026-06-13 版 `a627bc71` 晚 10 天）。
> 06-13 版独有的 §14–§17 无对应章节且被 `detailed-design.md` 引用 57 处（§14×4、§15×26、§16×24、§17×3），
> 故整体接续于 §13 之后，章节号不变；其中 §17 已被 §13 取代，见该节注记。
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

> 上表 7 条已正规化为正式 ADR（背景指回 SRS、列落选项与否决理由、写后果与缓解），见 §0.1。

### 0.1 架构决策记录（ADR）索引

全套 ADR 落于 `doc/ipad-cfd-teaching/adr/`。每份四段式：背景（指回需求）→ 选项 → 决策 → 后果（含缓解 + 被否决项及否决理由）。

| ADR | 标题 | 裁定的决策点 | 状态 | 主要追溯 |
|---|---|---|---|---|
| ADR-001 | FR7 AI 后端 + 可替换接口（默认端侧+RAG / 可选 BYO-key / 无后端） | **D5** | 已接受 | FR7, NFR1, NFR5, C3, §10 |
| ADR-002 | 求解引擎语言 = Swift（忠实移植） | — | 已接受 | C1, C2 |
| ADR-003 | 源码展示 = 真实 C++ 内嵌 + GPL 分期 | — | 已接受 | FR4, C3 |
| ADR-004 | 四层分层 + 引擎零 UI 依赖 | — | 已接受 | ASR, §1.1 |
| ADR-005 | 联动层单一事实源 | — | 已接受 | FR4, FR5 |
| ADR-006 | 数据驱动可插拔案例 | — | 已接受 | 演进策略 |
| ADR-007 | 数学渲染 = SwiftMath | — | 已接受 | NFR4, NFR5 |
| ADR-008 | 可视化 = Metal / SwiftUI Canvas | — | 已接受 | NFR4, FR3, NFR6 |
| ADR-009 | 引擎事件接口：算子级 + PISO 子步级广播 | **D2** | 已接受 | FR4, FR5, UC4-6, §1.1 缺口 |
| ADR-010 | 资源层契约升级：mappings + graph + ContextPack/AIProvider | **D4** | 已接受 | §9, FR4, FR7 |
| ADR-011 | UC6 detail 呈现：固定侧栏 split | **D1** | 已接受 | NFR6, UC6 |
| ADR-012 | 编辑后重算：重置重算（MVP） | **D3** | 已接受 | FR2, NFR4, UC2-E3 |

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

### 1.1 评审记录（2026-06-10，对照 M0 代码核实）

- ✅ **零 UI 依赖已验证**：`FoamMiniEngine` 全部源码的 import 仅 `Foundation`（1 处），无 SwiftUI/UIKit/Metal；CLI 与测试仅依赖引擎本身。纪律成立。
- ✅ **M0 目录结构与引擎层模块划分一致**：Core（Mesh/Fields/Vector2/DimensionSet）、Discretisation（Fvm/Fvc）、Matrix（FvMatrix）、Solvers（IcoFoam/LinearSolver/PisoControl）、Case（CavityCase），独立 SwiftPM 包 + 测试。
- ✅ 四层落地进度符合里程碑：引擎层已成形；资源层部分成形（案例数据有，源码片段 + 映射表待 M2）；展示层、联动层未开工（M1/M2）。
- ✅ **设计缺口已由 ADR-009 解决（2026-06-23，v0.3）**：§3 要求「每个算子执行时向联动层广播自己对应真实源码哪一段」，但引擎当前对外只有粗粒度接口——`run(onStep:)` 回调 + `StepReport`（每时间步一次，已对照 `IcoFoam.swift` 核实）。**ADR-009 定下事件流接口形状**：`enum SolverEvent`（时间步边界 / PISO 子步边界 / 算子执行 / 矩阵组装 / 线性求解+残差 / 场更新，各带 `nodeID`）经 `events() -> AsyncStream<SolverEvent>` 广播；保留 `step()`/`run()` 供 headless 与测试。D2 选「时间步 + PISO 子步两档」后，此接口须达子步粒度。它是联动层单一事实源（ADR-005）的数据来源，nodeID 与资源层 graph（ADR-010）共用同一命名空间。属 M1/M2 前置条件，详见 §6.1 协作视图。

---

## 2. Swift 引擎类设计 ↔ 真实 OpenFOAM 类映射

这张表是「源码入门」的骨架：用户在 UI 点到某个 Swift 概念，App 跳转展示右列真实 OpenFOAM 源码。

Swift 列已与 M0 实际代码（`ipad-cfd-teaching/FoamMini/`）的类型名对齐；右列路径已逐项核实存在于本仓库。

| Swift 引擎类型（M0 实际名） | 职责 | 对应真实 OpenFOAM | 真实源码位置（本仓库，已核实） |
|---|---|---|---|
| `CavityCase`（M3 演化为数据驱动 `CaseData`） | 持有 0/constant/system 三组数据 + 求解器标识 | 算例目录约定 | `tutorials/legacy/incompressible/icoFoam/cavity/cavity/` |
| —（暂无独立 `Time` 类型，时间推进在 `IcoFoam.run`；M1 时间轴时再立） | 时间推进、写出控制 | `Time` / `runTime` | `src/OpenFOAM/db/Time/` |
| `DimensionSet`（7 维幂） | 量纲 `[0 1 -1 …]` 校验 | `dimensionSet` | `src/OpenFOAM/dimensionSet/` |
| `StructuredMesh`（2D 结构化方腔） | cell/face/patch 拓扑、几何 | `polyMesh` / `fvMesh` | `src/finiteVolume/fvMesh/` |
| `VolScalarField` / `VolVectorField` | 体场（internal + boundary） | `volScalarField` / `volVectorField` | `src/finiteVolume/fields/GeometricFields/volFields/` |
| `SurfaceScalarField` | 面场（如通量 `phi`） | `surfaceScalarField` | `src/finiteVolume/fields/GeometricFields/surfaceFields/` |
| `ScalarBC` / `VectorBC` 枚举（fixedValue / noSlip / zeroGradient / empty） | 边界条件 | `fvPatchField` 派生类 | `src/finiteVolume/fields/fvPatchFields/` |
| `Fvm`：`ddt/div/laplacian` | **隐式**离散 → 组装稀疏矩阵 | `Foam::fvm::` | `src/finiteVolume/finiteVolume/fvm/` |
| `Fvc`：`grad/flux/interpolate`（`div` 待补，见 §2.1） | **显式**计算 → 直接返回场 | `Foam::fvc::` | `src/finiteVolume/finiteVolume/fvc/` |
| `FvScalarMatrix` / `FvVectorMatrix` | 稀疏矩阵方程对象，支持 `==`、`A()`、`H()`、`setReference()` | `fvMatrix`（typedef `fvScalarMatrix`/`fvVectorMatrix`） | `src/finiteVolume/fvMatrices/` |
| `LinearSolver`（CG / Gauss-Seidel） | 解线性系统 | `PCG` / `smoothSolver` / `GAMG` | `src/OpenFOAM/matrices/lduMatrix/solvers/` |
| `PisoControl`（含 `pRefCell`/`pRefValue`） | PISO 循环控制 | `pisoControl` | `src/finiteVolume/cfdTools/general/solutionControl/` |

### 2.1 评审记录（2026-06-10，对照本仓库核实）

- ✅ 右列 12 个源码路径全部核实存在；其中 2 处原稿有误已修正：`volFields`/`surfaceFields` 实际位于 `src/finiteVolume/fields/GeometricFields/` 之下，而非 `src/finiteVolume/fields/` 直下。
- ✅ cavity 教程精确路径锚定为 `tutorials/legacy/incompressible/icoFoam/cavity/cavity/`（仓库另有 `tutorials/fluid/cavity`、`tutorials/incompressibleFluid/cavity`，属新版求解器模块，**非** icoFoam 教学锚点，勿混用）。
- ✅ Swift 列改为 M0 实际类型名。M0 命名比原稿更贴近 OpenFOAM（`VolVectorField` vs 原稿 `Field<Vector>`），予以采纳。
- 📌 设计决策：边界条件用**枚举**（`ScalarBC`/`VectorBC`）而非类继承。MVP 只有 4 种 BC，枚举更简单且 switch 穷举有编译期保障；若后续开放更多 BC 类型再演化为协议 + 派生类型（届时与 `fvPatchField` 继承树的对照教学更直观）。
- 📌 已知缺口（已记录，不阻塞）：① `Fvc.div` 未实现——M0 在 `IcoFoam` 内部直接用通量散度组右端，语义等价但与展示的 `fvc::div(phiHbyA)` 不逐行对应，M0 收尾时补一个 `Fvc.div(SurfaceScalarField)` 包装即可对齐；② 线性求解器无 Jacobi（原稿笔误，实际 CG + Gauss-Seidel，已更正）；③ 真实 cavity 的 U 求解器是 smoothSolver+symGaussSeidel，M0 的 Gauss-Seidel 与之语义对应。

> **教学重点（差异化王牌）：`fvm` 与 `fvc` 的区分。** `fvm::` 返回矩阵（隐式，进左端），`fvc::` 返回场（显式，进右端）。这是 OpenFOAM 最难懂也最核心的抽象，必须在 UI 上可视化（见 §6 面板⑦）。

---

## 3. 引擎核心：让 Swift 顶层「方程即代码」

设计目标——Swift 的求解器顶层必须和真实 `icoFoam.C` 几乎逐行对应。

真实 OpenFOAM（`applications/legacy/incompressible/icoFoam/icoFoam.C`，节选；行号已核实：UEqn 组装 75–80，动量预测 82–85，PISO 循环 88–127）：

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

> 一致性注记（评审补充）：真实 icoFoam.C 还含三处上面 Swift 示意省略的调用——`adjustPhi(phiHbyA, U, p)`（L99，全封闭域通量全局守恒修正）、`constrainPressure(...)`（L102）、`pEqn.setReference(pRefCell, pRefValue)`（L114，纯 Neumann 压力方程定参考点，**必需**）。M0 已实现 `setReference`；`adjustPhi` 在封闭方腔属必要语义，M0 验证阶段须确认等价处理。源码面板展示真实代码时这三行**不省略**，映射表（§5）须为其建条目。

Swift 实现要点：
- 运算符重载 `+ - * ==` 让方程可读；`FvMatrix` 实现 `==`（移项）、`A()`（对角）、`H()`（off-diagonal 贡献）。
- `fvm.*` 返回 `FvMatrix`，`fvc.*` 返回 `Field`，**类型系统强制区分隐式/显式**（编译期就教对了概念）。
- 每个算子在执行时向**联动层**广播「我正在执行 + 我对应真实源码哪一段」——此广播的接口形状由 **ADR-009**（`SolverEvent` + `AsyncStream`）定下，数据流见 §6.1。

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
- **fvSolution**：`p: PCG + DIC, tol 1e-6, relTol 0.05`；`pFinal: relTol 0`；`U: smoothSolver + symGaussSeidel, tol 1e-5, relTol 0`；`PISO: nCorrectors 2, nNonOrthogonalCorrectors 0, pRefCell 0, pRefValue 0`。
- **blockMeshDict**：单 hex 块，`scale 0.1`，`(20 20 1)` 均匀网格，patch：movingWall（顶，type wall）、fixedWalls（左右下，type wall）、frontAndBack（type empty，2D）。

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

### 4.5 评审记录（2026-06-10，对照本仓库核实）

对照 `tutorials/legacy/incompressible/icoFoam/cavity/cavity/` 实际文件逐项核验：

| 项 | 结果 |
|---|---|
| `0/U`（量纲、internalField、3 个 patch 的 type/value） | ✅ 与 §4.1 完全一致 |
| `0/p`（量纲、internalField、3 个 patch） | ✅ 一致 |
| `constant/physicalProperties`（`nu [0 2 -1 0 0 0 0] 0.01`） | ✅ 一致 |
| `system/controlDict`（endTime/deltaT/writeControl/writeInterval） | ✅ 一致 |
| `system/fvSchemes`（Euler、Gauss linear、orthogonal 等） | ✅ 一致（实际文件另有显式 `grad(p) Gauss linear`，与 default 同值） |
| `system/fvSolution` | ✅ 一致；补记 U 的 `relTol 0`（原稿遗漏） |
| `system/blockMeshDict` | ✅ 一致；补记 patch 的 `type wall`/`type empty` |
| `CaseData` 数据结构 | ✅ 字段覆盖上述全部输入，**冻结**；`pRefCell/pRefValue` 归属 `FvSolution`（与真实字典的 PISO 子字典一致） |

结论：**§4 案例数据格式评审通过并冻结**。M3 字典编辑器与 M0 案例装载均以本节为契约。

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

### 5.1 资源层契约升级（v0.3，ADR-010）

②建模新增了「源码思维导图」需求（requirements §9、analysis-model §2.4/§3）：原映射表只有**节点**，思维导图还要**有类型的边**。故资源层契约由「单一 mappings」升级为 **`{mappings.json, graph.json}`** 两份：

- `mappings.json`：上方 MappingEntry（symbol ↔ 源码段 ↔ 公式 ↔ 解释）。
- `graph.json`：`nodes[{id, kind, title, sourceFile, lineStart, lineEnd, mappingId, x, y}]`（**`x,y` = 手工坐标，D4/ADR-010**）+ `edges[{from, to, type, arrow, label}]`（枚举见 analysis-model §3.2，`contributesLHS/RHS` 直接把 fvm/fvc 之分可视化）。
- **构建期 lint**（analysis-model §3.3）：边端点存在 / 枚举合法 / 非 `concept` 节点源码行对照真仓库存在（验收测试 T7）/ 无孤儿节点。
- **节点 id 与 ADR-009 的 `SolverEvent.nodeID` 共用同一命名空间** → 运行时执行游标（动态）与思维导图（静态）天然对齐。
- **FR7 预留挂点（M5 实现，③ 不堵死）**：`makeContextPack(nodeID, iterationState?) -> ContextPack` 生成上下文包；`protocol AIProvider { func answer(_ pack: ContextPack, prompt: String) -> AsyncStream<String> }` 留默认端侧 + 可选 BYO-key 两档实现位（ADR-001）。

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

> UC6 源码视图布局（ADR-011/D1）：思维导图 = 左画布（overview，graph.json 节点+边）+ 右侧栏（detail，点节点载入其 MappingEntry），`NavigationSplitView` 同屏并列，贴 NFR6 横屏多栏 + 避开经典 CAE 平铺文件树。

### 6.1 协作视图（块间通信：SolverEvent 流）

结构视图（§1 分层）回答"有哪些块"，本节回答"块间怎么通信"。教学 App 的核心通信链是**引擎 → 联动层 → 各面板**的单向数据流，由 ADR-009 的事件流驱动：

```
引擎层 IcoFoam.step()                   联动层 SessionVM(@Observable)        展示层 SwiftUI 各面板
─────────────────────────              ──────────────────────────         ────────────────────
  每个算子/子步执行处 yield                  消费 AsyncStream<SolverEvent>          自动重渲染（无需手动通知）
    SolverEvent {                  ──▶    ├─ .operator(nodeID) ─────▶ 更新   ──▶ ③ 源码高亮该行
      .timeStepBoundary             stream  │                       highlightedNodeID  ① 公式高亮对应项
      .pisoCorrectorBoundary  (D2)         │                                            ⑥ 思维导图执行游标(UC6-E2)
      .operatorExecuted(nodeID)            ├─ .matrixAssembled ─────▶ 更新   ──▶ ② 探针:该 cell 行 aP/aN
      .matrixAssembled                     │                       iterationState     (UC5)
      .linearSolved(residual)              ├─ .linearSolved ────────▶ 追加   ──▶ ⑥ 残差/Courant 曲线
      .fieldUpdated                        │                                            (FR3)
    }                                      └─ .fieldUpdated ────────▶ 触发   ──▶ ④⑤ 矢量/云图刷新
                                                                  场快照
  保留 step()/run() 供 headless/测试    ◀── 暂停 = 停止消费;单步 = 消费到下一个子步边界即停(UC4/D2)
```

通信纪律：

- **单向**：引擎只 `yield` 纯数据 `SolverEvent`（Foundation-only，不 import UI——守 ADR-004）；联动层是唯一订阅者，把事件折叠进**单一事实源**（ADR-005）；SwiftUI 因 `@Observable` 自动重渲染，**面板之间不直接通信**（杜绝 N×N 耦合）。
- **暂停/单步 = 背压**：UC4 的暂停 = 停止从 AsyncStream 拉取；单步 = 拉取到下一个"子步边界"事件即停（D2 两档）。无需引擎侧加锁。
- **id 对齐**：`SolverEvent.nodeID` 与 `graph.json` 节点 id 同一命名空间（ADR-010），故"运行时高亮哪段源码"与"思维导图哪个节点"是同一把钥匙。
- **编辑回流**：⑦ 字典编辑 → `CaseData` 变更 → 重置重算（ADR-012/D3）→ 引擎重新发流，闭合"改→算→看→懂"回路（requirements §10.2 强反馈通道）。

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
│  ├─ mappings.json            # 函数↔源码映射（MappingEntry）
│  └─ graph.json               # 思维导图节点+边（ADR-010，含手工坐标）
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

1. ~~评审本文档，确认 §2 类映射与 §4 案例数据结构~~ — **已完成并冻结**（2026-06-10，见 §2.1、§4.5）：修正 2 处源码路径、锚定教程精确路径、Swift 列对齐 M0 实际类型名、补记 `Fvc.div` 缺口与 `adjustPhi`/`setReference` 一致性注记（§3）。
2. ~~起 **M0**~~ — **已搭建**：见 `ipad-cfd-teaching/FoamMini/`（SwiftPM 包）。
   - 已含：`StructuredMesh`、`Field`、`Fvm`(ddt/div/laplacian)、`Fvc`(grad/flux/interpolate)、`FvMatrix`(A/H)、CG + Gauss-Seidel、`PisoControl`、`IcoFoam`、`CavityCase` 预设、CLI、验证测试。
   - 顶层 `IcoFoam.step()` 与真实 `icoFoam.C` 逐行对应（见包内 README 的映射表）。
   - ⚠️ **当前开发环境无 Swift 工具链且 swift.org 被网络策略拦截，代码尚未编译/运行验证**；需在 macOS/Linux 上 `swift build && swift test` 首次构建，按报错迭代。
3. 并行整理 §5 映射表首批条目（icoFoam.C 的 PISO 各行）。

> 许可合规（§11）：已决定原型期先内嵌真实源码开发、不阻塞；相关改造（外链 + 自写等价讲解、分发许可确认）列为**上架前**待办，见 §11.4。

---

## 13. ③ 架构评审记录（2026-06-23，v0.3 冻结依据）

③ 的验证 = 架构评审（评审而非跑测试，因架构主靠"可评审"）。分两道：断言核实（verification，对照写下的事实）+ 场景走查（用 ② 用例与质量场景在架构上走一遍）。

### 13.1 断言核实（对照真仓库）

| 断言 | 核实结果 |
|---|---|
| `icoFoam.C` UEqn 组装在 L75 起、PISO 循环含 `adjustPhi`(L99)/`setReference`(L114)/`pEqn.flux()` | ✅ 对照 `applications/legacy/incompressible/icoFoam/icoFoam.C` 一致 |
| cavity 教程路径 `tutorials/legacy/incompressible/icoFoam/cavity/cavity/`（0/constant/system） | ✅ 存在 |
| 引擎当前对外仅 `step(time:)->StepReport` + `run(endTime:onStep:)`（ADR-009 背景所依据的缺口事实） | ✅ 对照 `FoamMini/.../Solvers/IcoFoam.swift` 一致 |
| 引擎零 UI 依赖（ADR-004） | ✅ 延续 §1.1 既有核实（import 仅 Foundation） |
| §2 类映射 12 路径、§4 案例数据 | ✅ 沿用 v0.2 已冻结核实（§2.1、§4.5），本版未改动 |

### 13.2 场景走查（② 的 8 用例 + 质量场景）

逐条确认"每步有模块接得住 + 相关 NFR 不被违反"：

| 用例 | 走查路径（架构上） | 接得住？ |
|---|---|---|
| UC0 引导 | 展示层 onboarding 浮层叠在各面板上，复用 UC1/UC6 路径 | ✅ |
| UC1 运行 | ⑨→引擎 `run()`→`SolverEvent` 流（§6.1）→联动层→④⑤⑥ 刷新 | ✅ |
| UC2 编辑 | ⑦`CaseData`改→重置重算（ADR-012）→引擎重发流；越界钳制在编辑器层（NFR2/C4 不被违反） | ✅ |
| UC3 看结果 | ④⑤⑥ 读联动层场快照/残差序列；⑨ 时间轴回放 | ✅ |
| UC4 控制 | 暂停=停止消费 AsyncStream，单步=消费到子步边界即停（ADR-009/D2） | ✅ |
| UC5 探针 | 点 cell→联动层 `probedCell`→② 读引擎 `FvMatrix` 该行 aP/aN（依赖 `.matrixAssembled` 事件） | ✅ |
| UC6 源码对照 | ③ graph.json 节点图（ADR-010）+ 侧栏 detail（ADR-011/D1）；运行时执行游标 = `.operatorExecuted(nodeID)`，nodeID 同一命名空间 | ✅ |
| UC7 问 AI（M5） | 选中节点→`makeContextPack`→`AIProvider`（ADR-001/010 预留挂点）；断网降级在展示层（NFR5） | ✅ 挂点已留，不堵死 |

**质量场景**：

- **离线（NFR5）**：UC1–UC6 全链路无网络依赖（引擎/资源/渲染均本地）；仅 UC7 在线，默认端侧实现（ADR-001）可使其离线可用，断网降级路径在展示层。✅
- **性能（NFR4）**：20×20 网格；Metal 渲染（ADR-008）+ AsyncStream 背压使单步无可感卡顿；运算符重载临时分配在小网格可接受（§10 风险表已记缓解位）。✅
- **演进（加案例不改框架）**：新案例 = 加 CaseData（ADR-006）+ 加 graph/mappings 数据（ADR-010），框架不动。✅

### 13.3 结论

断言核实全过、8 用例 + 3 质量场景走查全部"有模块接得住、相关 NFR 不被违反"，无新增缺口。**architecture.md v0.3 冻结，③架构设计阶段收口。** D1–D5 全部裁定并落 ADR；§1.1 缺口由 ADR-009 解决。

下一阶段 ④详设 的种子：ADR-009 `SolverEvent` 枚举的完整成员与 payload 类型；ADR-010 两份 JSON 的完整 schema 与 lint 工具；组合/引用（analysis-model §2.3）→ Swift 值/引用语义选型；Keychain 存取 BYO-key 的具体实现（ADR-001）。

---

# 附：§14–§17（承 2026-06-13 版）

> 以下四节来自 ③ 的另一条会话线（2026-06-13，`claude/festive-mccarthy-44aptr` → `claude/blissful-noether-gdnfwa`），
> 2026-06-23 版无对应章节。`detailed-design.md` 与 `HANDOFF-stage4/5.md` 直接引用其章节号，故原样接续、编号不变。

## 14. D1–D4 裁决（②→③ 开放决策收口）

`analysis-model.md §6` 留给 ③ 的 4 个开放决策，2026-06-13 由需求方拍板：

| # | 决策点 | 裁决 | 理由 / 后果 | 影响下游 |
|---|---|---|---|---|
| **D1** | UC6 detail 呈现 | **固定侧栏**（地图常驻 + 源码并排）；**暂定，待 UI 评审验证，效果不佳可回退浮层** | overview+detail 同屏是思维导图教法核心；契合 NFR6 iPad 横屏多栏。代价：源码栏宽度受限 | UX 架构（§6 面板③）；**可回退，不进不可变 ADR** |
| **D2** | 单步粒度 | **时间步 + PISO 子步两档** | PISO 内部（动量预测→压力修正→通量校正）是 FR4/FR5 教学王牌，须可见可单步 | **直接决定 §15 引擎事件接口粒度**（下沉到算子/子步级）|
| **D3** | 编辑后重算 | **重置重算（MVP）** | 语义干净、与 UC2-E3 既定 MVP 策略一致、实现简单；「从当前时刻续算」属进阶项延后 | 联动层重算流；§15 游标 `reset()` |
| **D4** | 图布局算法 | **手工定坐标（MVP）** | icoFoam 节点仅约十几个，手工排版可按教学顺序摆位、最可控、零额外依赖 | 资源层 graph：node 带可选 `x/y`（item 4 契约）|

> D1 注记：需求方明确「先看效果、不理想再改」——故 D1 登记为**可回退的暂定项**，不进「不可变 ADR」，留待 ④ 设计稿 / NFR6 评审复核。D2/D3/D4 为稳定裁决。

---

## 15. 引擎↔联动层 事件接口（补 §1.1 缺口）[ADR-011]

§1.1 记录的设计缺口：引擎对外仅 `step()→StepReport` / `run(onStep:)`（**每时间步一次，粗粒度**），但「点算子→高亮真实源码行」（FR4）、「执行游标脉冲」（UC6-E2）、「子步单步」（D2/UC4）都要求**算子/子步级**广播。本节把该接口的形状定下来。

### 15.1 ADR-011 · 事件接口 = 同步可恢复「求解游标」+ 事件枚举（AsyncStream 作播放适配）
- **背景**：上述缺口；**D2 裁决（时间步+PISO 子步两档）**要求引擎能在子步边界**暂停/恢复**；NFR4（流畅、可连续播放）；ADR-001（引擎零 UI 依赖、可单测）；验收 T5（单步一致性：暂停-单步 n 次的场 = 连续跑 n 步**逐位一致**）。
- **决策**：引入**同步、确定性、可恢复**的「求解游标」`SolveCursor` 作为新原语——`advance() -> SolveEvent` 执行下一相位、就地更新场、返回事件。事件类型 `SolveEvent`（**纯 Swift 值类型，零 UI import**）携带 `phase + nodeID + 迭代坐标(step/corrector) + 载荷(residual/contErr/report)`。**联动层**在游标之上提供 `AsyncStream<SolveEvent>`（播放模式驱动 UI 刷新）与 `step()/stepSubPhase()`（两档单步）。现有 `step(time:)`/`run(endTime:onStep:)` 降为游标之上的便利包装（**M0 测试不破**）。
- **落选选项（及否决它的需求）**：
  - **纯同步回调** `step(emit:(SolveEvent)->Void)` —— 能广播但无法在子步边界暂停/恢复（直线循环跑完才返回），被 **D2 子步单步 + UC4** 否决。
  - **纯 AsyncStream（引擎内开 Task 异步求解）** —— 适合播放，但把并发塞进引擎，损 **ADR-001 可单测** 与 **T5 逐位一致**（异步调度引入非确定性）；故 AsyncStream 只在联动层用，不下沉进引擎。
  - **维持现状（仅 StepReport / 时间步粒度）** —— 被 **FR4 / FR5 / UC6-E2** 否决（无算子级游标则无源码联动、无执行脉冲）。
- **后果与缓解**：正面 = 算子级联动落地、单步确定可复现（T5/T6 可验收）、引擎仍同步零 UI（ADR-001 不破）、向后兼容 M0。负面 = 须把直线 `step()` 重构为相位游标，承担**「重构须行为保持」**义务（游标的数值运算序列须与原 `step()` 逐位一致）；M0 现有数值简化（省 `adjustPhi`/`constrainPressure`/`fvc::ddtCorr`）使真实 icoFoam.C 的 L96/L99/L102 暂无对应相位——这些行**照常显示**（ADR-002/§3）、标「展示未执行」状态，待 M0 补齐再接相位。缓解 = 游标重构守「相位切分、算术不动」纪律 + 黄金对拍测试（连续跑 vs 单步逐位比对，即 T5）。
- **追溯**：FR4 / FR5 / NFR4 / D2 / UC6-E2 / T5；补 §1.1 缺口；关联 ADR-001、ADR-003。

### 15.2 SolveEvent 相位序（对照真实 icoFoam.C，行号已核实）

每个相位携带一个 `nodeID`（= `analysis-model §3` 思维导图节点 id），联动层据此同时点亮：思维导图节点（脉冲）+ 源码行（§5 映射表）+ 公式（§7）+ 结果面板（④⑤⑥）。这张表就是「**协作视图**」的算子级落地：

| 序 | SolvePhase | icoFoam.C 行 | nodeID | 联动效果（一处执行 → 多处响应）|
|---|---|---|---|---|
| 0 | `timeStepBegin(step,time)` | 67–69 | `icoFoam` | ⑨ 时间轴前进；游标入 solver 根节点 |
| 1 | `op(.ddt,.lhs)` | 77 | `fvm.ddt` | ① 高亮 ∂U/∂t + ③ L77 + 图 UEqn 入边 |
| 2 | `op(.div,.lhs)` | 78 | `fvm.div` | ① ∇·(UU)（用 phi）+ ③ L78 |
| 3 | `op(.laplacian,.lhs)` | 79 | `fvm.laplacian` | ① ν∇²U + ③ L79 |
| 4 | `assembleMomentum` | 75–80 | `icoFoam.UEqn` | 图 UEqn 节点脉冲；② 探针看该矩阵 A/H |
| 5 | `op(.grad,.rhs)` | 84 | `fvc.grad(p)` | ① −∇p 进右端 + ③ L84（**fvc 显式** vs fvm 隐式同屏对比）|
| 6 | `solveMomentum(residual)` | 82–85 | `icoFoam.UEqn` | 动量预测解；④ U 矢量刷新 |
| 7 | `pisoCorrectorBegin(c)` | 88–91 | `icoFoam.piso` | ⑨ 子步指示灯亮第 c 档（D2 两档下钻）|
| 8 | `op(.flux,.rhs)` | 92–97 | `fvc.flux` | 面通量 phiHbyA + ③ L95 |
| 9 | `assemblePressure(c)` | 109–112 | `icoFoam.pEqn` | pEqn = `fvm.laplacian`(隐式左端) `==` `fvc.div`(显式右端)，**王牌对比**|
| 10 | `solvePressure(c,residual)` | 114–116 | `icoFoam.pEqn` | 压力 PCG 解；⑥ 残差追加点；⑤ p 云图刷新 |
| 11 | `correctFlux(c)` | 118–121 | `field.phi` | phi = phiHbyA − pEqn.flux()；连续性误差↓ |
| 12 | `correctVelocity(c)` | 126–127 | `fvc.grad(p)` | U = HbyA − rAU·∇p；④ U 矢量刷新 |
| 13 | `pisoCorrectorEnd(c,contErr)` | 124 | `icoFoam.piso` | 子步收尾（continuityErrs）|
| 14 | `timeStepEnd(report)` | 130 | `icoFoam` | StepReport；⑨ 时间轴落点 |

> 单步两档（D2）的语义：**时间步单步** = 驱动游标 advance 至下一个 `timeStepEnd`；**PISO 子步单步** = advance 一个相位即停。**T5 不变量**：游标按相位推进 n 步得到的场，必须与连续 `run` 跑 n 步逐位一致——因为游标只是把同一套 `step()` 算术**重新切相位、不改运算与顺序**。

### 15.3 类型草案（示意，④ 详设细化；纯 Swift、零 UI）

```swift
public enum OperatorKind { case ddt, div, laplacian, grad, flux, interpolate }
public enum PhaseRole   { case lhs, rhs }          // fvm 进左端 / fvc 进右端

public enum SolveEvent {                            // 纯值类型，可单测、可序列化回放
    case timeStepBegin(step: Int, time: Double)
    case op(OperatorKind, role: PhaseRole, nodeID: String)
    case assembleMomentum(nodeID: String)               // "icoFoam.UEqn"
    case solveMomentum(residual: Double, nodeID: String)
    case pisoCorrectorBegin(index: Int, nodeID: String)
    case assemblePressure(index: Int, nodeID: String)   // "icoFoam.pEqn"
    case solvePressure(index: Int, residual: Double, nodeID: String)
    case correctFlux(index: Int, nodeID: String)        // "field.phi"
    case correctVelocity(index: Int, nodeID: String)
    case pisoCorrectorEnd(index: Int, continuityError: Double, nodeID: String)
    case timeStepEnd(report: StepReport)
}

public final class SolveCursor {                    // 同步、确定性、可恢复
    public func advance() -> SolveEvent              // 执行下一相位，就地更新场
    public var atTimeStepBoundary: Bool { get }
    public func reset()                              // D3：编辑后重置重算
}
```

> 联动层（②已锚定的「单一事实源」`SessionVM`，§6）消费事件：`highlightedNodeID ← event.nodeID`（执行游标脉冲）、`iteration ← (step,corrector,residual)`；播放模式用 `AsyncStream<SolveEvent>` 拉取、单步模式直呼 `advance()`。**引擎仍零 UI 依赖**：它只产出 `SolveEvent` 值，谁消费、怎么渲染概不与闻。

---

## 16. 资源层契约升级（并入思维导图 graph + 预留 FR7 ContextPack 挂点）

§5 原定资源层只放一张 `mappings`（符号 → 源码行 + 公式 + 解释）——一堆「卡片」。②（`analysis-model §2.4 / §3`）给领域模型新增了 `Relationship`（思维导图的「边」）：卡片之间需要「连线」。故资源层契约由 `mappings` 升为 `mappings + graph{nodes, edges}`，并为 FR7（M5）预留 ContextPack 生成挂点。

### 16.1 升级后的资源层契约（顶层形状）

```jsonc
{
  "version": 1,                       // 资源格式版本：新增字段只升版本、不破旧数据
  "mappings": [ /* §5 既有：symbol → 源码行/公式/解释，冻结不动 */ ],
  "graph": {                          // 并入②思维导图（analysis-model §3）
    "nodes": [
      { "id": "fvm.laplacian", "kind": "operator",
        "title": "fvm::laplacian — 隐式扩散",
        "sourceFile": "applications/legacy/incompressible/icoFoam/icoFoam.C",
        "lineStart": 79, "lineEnd": 79,
        "mappingId": "fvm.laplacian",     // 指回 mappings 的卡片（节点≠重复存源码）
        "x": 320, "y": 140 }              // D4：手工坐标（可选；缺省留给将来自动布局）
    ],
    "edges": [
      { "from": "icoFoam.UEqn", "to": "fvm.laplacian",
        "type": "contributesLHS", "arrow": "single", "label": "ν∇²U" }
    ]
  },
  "contextPackHook": null             // FR7/M5 预留：M5 在此插 ContextPack 生成规则；现为 null，不堵死
}
```

字段枚举（`node.kind` / `edge.type` / `edge.arrow`）沿用 `analysis-model §3.2`，不在此重复。

### 16.2 三条设计纪律（为什么这么切）

1. **节点不重复存源码，只用 `mappingId` 指回卡片**：源码/公式/解释的唯一事实源仍是 `mappings`（§5）；graph 只加「结构与连线」。避免同一段源码两处维护、两处漂移。
2. **坐标可选（D4）**：`x/y` 是手工布局（MVP）；字段可缺省，将来切自动布局时旧数据不失效——**开放扩展、不破旧（开放-封闭原则）**。
3. **ContextPack 只留挂点、不现在实现（FR7/M5）**：`ContextPack`（喂 AI 的资料包）= 某 `mappingId` 的卡片内容 +（可选）当前 `SolveEvent`/求解状态（§15）。M5 才生成；③ 只保证它**可由现有结构装配而成**（卡片已在 mappings、状态已在事件流），并留 `contextPackHook`，使 M5 是「加规则」而非「改格式」。

### 16.3 构建期校验（资源层的「每阶段末验证」）

沿用 `analysis-model §3.3` 的 lint，在资源打包时跑（红绿灯式可验收）：① `edge.from/to` 必须存在于 `nodes`；② `type/arrow` 在枚举内；③ 非 `concept` 节点的 `sourceFile:行区间`对照真仓库真实存在（= 验收 T7 映射真实性）；④ 无孤儿节点。

> 追溯链（一条干净的可追溯实例）：需求 §9（思维导图候选概念）→ ② 领域模型新增 `Relationship`（analysis-model §2.4）→ ③ 资源层 `graph.edges`（本节）→ ⑥ 验收 T7。需求一路落到数据格式，链不断。

---

## 17. ③ 阶段末评审与冻结（v0.3）

> **本节已被 §13 取代（2026-08-28 合并时标注）**：§13「③ 架构评审记录」是同一次 ③ 评审的更新版本
> （2026-06-23，走查 8 个用例 + 3 个质量场景；本节为 2026-06-13 版，走查 5 个场景）。按「保留最新修改」，
> **以 §13 为准**。本节保留，仅因 `detailed-design.md` 的 ④-2（UC5 矩阵行只读访问器）立项依据出自
> §17.1 的走查发现——该缺口在 §13 线中由 ADR-009 的 `.matrixAssembled` 事件另行解决（§13.2 UC5 行）。

③ 无法「跑测试」，故按第一课「每阶段末验证」纪律，用两种**评审**手法给架构做体检：**场景走查**（拿②用例 + 质量场景在架构上走一遍）+ **断言核实**（事实断言对真仓库查证）。通过后冻结。

### 17.1 场景走查（②用例 + 质量场景 → 架构是否接得住）

| 场景（源） | 在架构上的走法 | 结论 |
|---|---|---|
| **UC6 读源码 + UC4 单步**（FR4/FR5）| 单步 → 引擎 `SolveCursor.advance()` 出 `SolveEvent(nodeID)`（§15）→ 联动层置 `highlightedNodeID`（§6 单一事实源）→ 思维导图节点脉冲(§16) + 源码行(§5) + 公式(§7) + 结果(④⑤) 同时点亮 | ✅ 全链路有模块接住；§15 缺口已补 |
| **UC2 编辑 + 越界钳制**（FR2/NFR2/C4）| 表单改盖速 → form↔dict 双向同步(ADR-010) → 作用于 `CaseData`(ADR-005) → 确认 → 重置重算(D3) → 新流场；deltaT 越界 → 钳制 + 解释(UC2-E1) | ✅ 接住；NFR2/C4 落在编辑层钳制 |
| **UC5 探查单元**（FR5）| 点 cell → 探针(§6②)需引擎按 cell 取该行矩阵系数(aP/各 aN) | ⚠️ **走查发现小缺口**：`FvMatrix` 现有 `A()/H()`，但无「按 cell 取该行系数」只读访问器 → 记为 ④ 待办（与 §15「引擎向 UI 暴露只读数据」同源），**不阻塞③冻结** |
| **NFR5 离线降级**（质量场景）| 飞行模式 → 静态层（Swift 引擎 + 资源层内嵌源码/公式/数据 + 可视化）全在端上可用；AI 入口(FR7) 置灰提示(UC7-E1) | ✅ 分层(ADR-008) 使静态层不依赖网络；AI 层独立可降级 |
| **NFR4 性能**（质量场景）| 20×20 教学网格；Metal 渲染场/云图、Canvas 画曲线(ADR-007)；单步走游标一相位 | ✅ 网格小 + GPU 渲染；单步响应取决于一相位计算量，可接受 |

> 走查产出 **1 个 ④ 待办**（UC5 矩阵行只读访问器），**0 个 ③ 阻塞项**。架构其余部分在②全部 MVP 用例 + 关键质量场景下成立。

### 17.2 断言核实（事实断言 → 真仓库）

- ✅ 本会话复核 `icoFoam.C` 关键行号：UEqn 75–80、动量预测 82–85、PISO 88–127；`fvm.ddt/div/laplacian` 77/78/79、`fvc::grad(p)` 84、`adjustPhi` 99、`constrainPressure` 102、`pEqn` 109–112、`setReference` 114、通量/速度修正 120/126——§15 相位序据此锚定，全部命中。
- ✅ cavity 锚点 `tutorials/legacy/incompressible/icoFoam/cavity/cavity/`、§2 类映射 12 条源码路径、§4 案例取值——延续 §2.1/§4.5 既有核实，未变。
- 📌 **诚实边界**：§15 的 `SolveCursor`/`SolveEvent`、§16 的 graph/contextPackHook 是**设计契约，尚无对应 Swift 代码**（M0 引擎当前仅 `step()/run()`）。落地 = ④详设 + ⑤实现的活，且背 ADR-011「重构须逐位一致」债（验收 T5 把关）。**架构层断言（路径/行号/取值）为真；实现层断言留给下游验收。**

### 17.3 冻结声明

§13 ADR 台账（ADR-001..011）+ §14 D1–D4 裁决 + §15 事件接口 + §16 资源契约，经上述场景走查与断言核实，**③架构设计冻结为 v0.3**。遗留：1 个 ④ 待办（UC5 矩阵行访问器）、D1 暂定项（待 ④ UI 评审复核）、§15/§16 实现债（④⑤ 落地）——均已登记，不阻塞冻结。**下一阶段：④ 详细设计。**
