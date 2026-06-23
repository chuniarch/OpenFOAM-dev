# iPad CFD 教学程序 · ④ 详细设计文档（detailed-design.md）

> 版本：**v1.0（已冻结 · ④详细设计）**　|　日期：2026-06-14（v0.1 开工 2026-06-13）
> 评审状态：**④详细设计 v1.0 已冻结**（评审记录见 §④-7：场景走查 6 用例 + 断言核实全真）。遗留：④遗留-1（UC3 时间轴回放，⑤/M1）、D1 侧栏暂定（M2 复核）。下一阶段：⑤ 实现。
> 上游（全部在本线分支）：①`requirements.md` v1.3、②`analysis-model.md` v0.2、③`architecture.md` **v0.3 已冻结**。
> 定位：③ 说清了「由哪些大块组成、怎么连、为什么」；**④ 钻进每个大块，把它的内部设计到「照着就能写代码」的程度**——具体类型、函数签名、算法、数据结构、代码级接口契约、关键时序。
> 本阶段验证（重要前提）：**本环境无 Swift 工具链，代码不真编译**。故 ④ 产出 =「设计 + 测试判据」；评审用**断言核实**（对真源码/行号查证）+ **场景走查**（②用例在详设上走通）。真编译/真跑留 ⑤。

---

## §0 接上下文：这条线走到哪、④ 是什么

> 编号约定见 §1.1。本节用大白话把 ①②③ 已走的路和 ④ 的定位接上，供新会话快速进入状态。

### §0.1 六个大阶段地图（用「盖房子」打比方）

| 大阶段 | 软件工程在干嘛 | 盖房子类比 | 产物 | 状态 |
|---|---|---|---|---|
| ① 需求工程 | 反复聊清「到底要什么」 | 和业主谈清要一座什么房 | requirements.md v1.3 | ✅ |
| ② 需求分析/建模 | 把话整理成「有哪些功能、谁连谁」 | 排出有哪些房间、彼此怎么连 | analysis-model.md v0.2 | ✅ |
| ③ 架构设计 | 定整栋的骨架总图 + 为什么 | 定分几层、承重墙、水电主管走向 | architecture.md v0.3（冻结）| ✅ |
| **④ 详细设计（本阶段）** | 把关键大块画到「照着能施工」 | 每个房间/每根管的施工详图 | **detailed-design.md（本文件）** | ▶ 进行中 |
| ⑤ 实现 | 写代码 | 照图施工 | （Swift 代码）| 待 |
| ⑥ 验证 | 测试验收 | 验房 | （测试）| 待 |

### §0.2 ①②③ 已教的概念（④ 直接援引，不重讲）

| 概念 | 一句话大白话 | 哪儿用过 |
|---|---|---|
| 可追溯 | 每条需求都能往前找到「验收怎么验」、每段代码都能往后找到「为哪条需求写」 | 全程：FR/NFR/C → ADR → T 测试 |
| 可验收 vs 可评审 | 能跑测试判真假 = 可验收；不能跑、只能拿人脑走查 = 可评审 | ③④ 没法编译，靠评审 |
| 需求→架构 ASR 筛法 | 真正左右结构的，多是"非功能需求/约束"（性能、离线、合规…），不是功能本身 | ③ ADR 落选项几乎全被 NFR/C 否决 |
| 用例=动词投影 / 领域=名词投影 | 把需求里的「动作」抽出来 = 用例；把「名词概念」抽出来 = 领域模型 | ② UC1–7 / 领域名词表 |
| ADR | 一条「为什么这么决定」的不可变档案：背景→选项→决策→后果 | ③ ADR-001..011 |
| 分层架构 | 楼分层：依赖只能往下、下层不知道上层存在、状态只存一份（单一事实源）| ③ 四层：展示/联动/引擎/资源 |
| 关注点分离 | 各司其职：引擎只「算 + 报幕」、UI 只「听 + 画」 | ③ 引擎零 UI 依赖 |
| 为变化而设计 | 留好「以后能加、但不破坏老的」的口子（开放-封闭、给数据格式编版本号）| ③ 资源 `version`、坐标可选 |

### §0.3 ④「详细设计」是什么（一句话 + 类比）

- 一句话：③ 给的是「整栋楼分四层、各层放什么、层间怎么对接」的**总图（粗）**；④ 是钻进其中关键的几个大块，把「这个开关接哪根线、这根管多粗、拧几圈」画到**工人照着就能装（细）**。
- 对软件而言，「施工详图」= 具体**类型** + **函数签名**（叫什么、吃什么参数、吐什么结果）+ **算法步骤** + **数据怎么存** + 模块间**精确的接口约定** + **关键时序**。

### §0.4 ④ 会新教的概念（用到时再展开）

| 新概念 | 大白话 + 类比 |
|---|---|
| 接口契约精化 | 把③的「示意 API 草图」磨成「能编译的精确签名」。像把"这里留个插座"细化成"装一个国标五孔插座、离地 30cm"。|
| **行为保持的重构（refactoring）** | 在**不改变结果**的前提下重排代码结构。像把一篇文章重新分段加小标题，**一个字不改**。④-1 的核心，须满足 T5「切完逐位一致」。|
| 契约式设计（前置/后置条件）| 每个函数讲明「你先保证什么（前置），我才保证给你什么（后置）」。像快递柜：先有取件码，才弹格子。|
| 可测试性设计 | 设计时就想好「这东西怎么写测试验证它对」。|

---

## §1 ④ 的内部施工清单与编号约定

### §1.1 编号约定（★三套编号不撞号★）

- `①–⑥`：软件工程**大阶段**（现在在 ④）。
- `M0–M5`：产品**交付里程碑**（architecture.md §8；现仅 M0 有代码）。
- `④-1 … ④-7`：**本文档的内部施工块**，**仅属 ④**（不与大阶段/里程碑混用）。
- `§N`：**本文档的章节号**（只在本文档内有效，与别的文档各论各的）。

### §1.2 施工清单（接 ③ 留给 ④ 的债，建议顺序）

| 块 | 在干嘛（一句话）| 接住的需求/用例/测试 | 来源（③ 留的债）|
|---|---|---|---|
| **④-1** | 把 §15 求解游标 `SolveCursor`/`SolveEvent` 从草图落成可编译级设计 + 行为保持重构（把直线 `step()` 切成相位游标，论证逐位一致）| FR4/FR5、UC4/UC6、**T5** | architecture.md §15 / ADR-011 |
| ④-2 | 给 `FvMatrix` 加「按 cell 取该行系数(aP/各 aN)」只读访问器 | UC5 探针、**T6** | §17.1 走查待办 |
| ④-3 | 联动层 `SessionVM` 详设：单一事实源字段、消费事件流、两档单步/播放/暂停/重置 状态机 | UC4、FR5、D2/D3 | §6 / §15.3 |
| ④-4 | 资源层 §16 契约落成具体 `Codable` 类型 + 构建期 lint 工具 | UC6、**T7** | §16 |
| ④-5 | 编辑闭环：`CaseData` ↔ 表单 ↔ dict 文本 三方同步、校验、安全钳制 | UC2、FR2、NFR2/C4 | ADR-010 |
| ④-6（可选）| D1 侧栏 UX 原型/评审（暂定项，效果不佳回退浮层）| UC6、NFR6 | §14 D1 |
| ④-7 | 评审 + 冻结 ④ 产物（用例走查 + 断言核实）| 全部 | §17 纪律延续 |

### §1.3 每块怎么推进（工作流）

先讲「在干嘛 / 为什么」（对话里、大白话、配类比）→ **关键选型用 `AskUserQuestion` 交需求方拍板** → 把图纸（类型/签名/算法/表格）落进本文档 → 块末小结 → ④-7 整体评审、冻结。

---

## ④-1　求解游标 `SolveCursor` / `SolveEvent` 详细设计

### ④-1.1 在干嘛 / 为什么（一句话回顾）

现状：`IcoFoam.step()` 是**一条直线**，一口气把一个时间步算完、给一张 `StepReport`，中途看不到、停不下。
教学 App 要"点一处、多处亮"，需要引擎**算一小步就停下来报幕**（像逐帧暂停的视频）。
④-1 = 把 ③ §15 的"求解游标"草图落成**可编译级设计**，并把直线 `step()` 做**行为保持的重构**切成相位游标，论证 **T5 逐位一致**。

### ④-1.2 援引 ③ 已冻结契约（§15，原文，本节据此精化）

> **§15.1 ADR-011 决策（节录）**：引入**同步、确定性、可恢复**的「求解游标」`SolveCursor`——`advance() -> SolveEvent` 执行下一相位、就地更新场、返回事件。事件 `SolveEvent`（**纯 Swift 值类型，零 UI import**）携带 `phase + nodeID + 迭代坐标(step/corrector) + 载荷(residual/contErr/report)`。联动层在游标之上提供 `AsyncStream<SolveEvent>`（播放）与 `step()/stepSubPhase()`（两档单步）。现有 `step(time:)`/`run(endTime:onStep:)` 降为游标之上的便利包装（**M0 测试不破**）。

> **§15.2 相位序（15 相，行号已核实）**：0 `timeStepBegin`(L67-69,`icoFoam`)｜1 `op(.ddt,.lhs)`(L77,`fvm.ddt`)｜2 `op(.div,.lhs)`(L78,`fvm.div`)｜3 `op(.laplacian,.lhs)`(L79,`fvm.laplacian`)｜4 `assembleMomentum`(L75-80,`icoFoam.UEqn`)｜5 `op(.grad,.rhs)`(L84,`fvc.grad(p)`)｜6 `solveMomentum`(L82-85,`icoFoam.UEqn`)｜7 `pisoCorrectorBegin(c)`(L88-91,`icoFoam.piso`)｜8 `op(.flux,.rhs)`(L92-97,`fvc.flux`)｜9 `assemblePressure(c)`(L109-112,`icoFoam.pEqn`)｜10 `solvePressure(c)`(L114-116,`icoFoam.pEqn`)｜11 `correctFlux(c)`(L118-121,`field.phi`)｜12 `correctVelocity(c)`(L126-127,`fvc.grad(p)`)｜13 `pisoCorrectorEnd(c)`(L124,`icoFoam.piso`)｜14 `timeStepEnd`(L130,`icoFoam`)。
> **T5 不变量（§15.2 原文）**：游标按相位推进 n 步得到的场，必须与连续 `run` 跑 n 步**逐位一致**——因为游标只是把同一套 `step()` 算术**重新切相位、不改运算与顺序**。

§15.3 给的是类型**草案**；下面 ④ 把它精化到"照着能写"。

### ④-1.3 设计决策（A + 三条派生子决策）

**主选型（需求方已拍板）**：**A 手写相位状态机**——游标存一个"走到第几相位"的标记 + 把算到一半的中间量存在游标字段上；`advance()` 用一个 `switch` 执行当前相位、更新状态、返回事件。（落选 B async/await 协程、C 线程+信号量：均把并发/不确定性塞进引擎，违反 ADR-001 同步可单测、威胁 T5 逐位一致——见 §15.1 落选项。）

由 A 直接派生、④ 详设要钉死的三条：

- **④-1-子决策①　游标归属与场共享**：`IcoFoam` 仍**拥有** `U/p/phi`，并持有**一个长生命周期**的 `cursor`。`SolveCursor` 持 `unowned let solver: IcoFoam` 回引用：
  - `U`、`p` 是 **class（引用类型）** → 游标经 `solver.U.internalField[...] = …` **就地改**，天然与 solver 共享同一份（单一事实源，ADR-008）。
  - `phi` 是 **struct（值类型）** → 游标改完经 `solver.phi = …` **属性写回** solver（值类型不会自动共享，必须显式回写——这正是 ②§2.3 预告的"值/引用语义"落点）。
  - 算到一半的中间量（`UEqn`/`rAU`/`HbyA`/`phiHbyA`/`pEqn`…）是**一个时间步内的临时品** → 存为**游标自己的字段**（"把原本藏在函数里的局部变量挪到对象上"）。
- **④-1-子决策②　`step()`/`run()` 降为薄包装**：全引擎**只保留一套算术**（在游标的各相位里）。`step()` = 驱动游标到下一个 `timeStepEnd`；`run()` = 循环调用 `step()`。→ 单步与连跑走**同一份代码**，T5 自然成立（详见 §④-1.8）。
- **④-1-子决策③　`time` 归属**：游标权威，`time = Double(step)·dt`。这与旧 `run()` 里 `t += dt`（第 s 步 = s·dt）**等值**，故 `run()` 报告逐位不变。`step(time:)` 的入参保留作**源码兼容**，实际以游标为准（无调用方传非 s·dt，安全）。

### ④-1.4 `SolveEvent`（精化自 §15.3 草案，纯值类型 / 零 UI / 可序列化回放）

```swift
public enum OperatorKind { case ddt, div, laplacian, grad, flux, interpolate }
public enum PhaseRole    { case lhs, rhs }     // fvm 进左端(隐式) / fvc 进右端(显式)

public enum SolveEvent: Equatable {            // Equatable 支持事件流单测/回放对拍
    case timeStepBegin(step: Int, time: Double)
    case op(OperatorKind, role: PhaseRole, nodeID: String)
    case assembleMomentum(nodeID: String)                       // "icoFoam.UEqn"
    case solveMomentum(residual: Double, nodeID: String)        // 旧 step() 丢弃的残差，这里捡回
    case pisoCorrectorBegin(index: Int, nodeID: String)         // "icoFoam.piso"
    case assemblePressure(index: Int, nodeID: String)           // "icoFoam.pEqn"
    case solvePressure(index: Int, residual: Double, nodeID: String)
    case correctFlux(index: Int, nodeID: String)                // "field.phi"
    case correctVelocity(index: Int, nodeID: String)
    case pisoCorrectorEnd(index: Int, continuityError: Double, nodeID: String)
    case timeStepEnd(report: StepReport)                        // 复用现有 StepReport
}
```

> 注：`StepReport` 须加 `: Equatable`（其成员全是 `Double`，零成本）以让 `SolveEvent: Equatable` 成立——供 §④-1.9 的事件流对拍。

### ④-1.5 `SolveCursor`：相位枚举（程序计数器）+ 字段 + 签名

```swift
public final class SolveCursor {                 // 同步、确定性、可恢复
    // —— 程序计数器：15 相的纯标签（不带 c，c 单独存）——
    private enum Phase {
        case timeStepBegin
        case opDdt, opDiv, opLaplacian, assembleMomentum
        case opGradP, solveMomentum
        case pisoBegin, opFlux, assemblePressure, solvePressure, correctFlux, correctVelocity, pisoEnd
        case timeStepEnd
    }
    private var phase: Phase = .timeStepBegin      // 下一次 advance() 要执行的相位
    private var step = 0                           // 已完成/进行中的时间步序号
    private var corrector = 0                      // 当前 PISO 子步 index (0..<nCorr)

    // —— 上下文（只读，回引用 solver）——
    private unowned let solver: IcoFoam
    private var dt: Double { solver.dt }
    private var nCorr: Int { max(solver.piso.nCorrectors, 1) }

    // —— 跨相位"溢出"的中间量（原 step() 的局部变量挪到这里）——
    private var ddtM, divM, lapM: FvVectorMatrix?  // 相1,2,3 → 相4
    private var UEqn: FvVectorMatrix?              // 相4 → 相7(每个 corrector 复用)
    private var mom: FvVectorMatrix?               // 相5 → 相6
    private var rAU: [Double]?                     // 相7 → 相12
    private var HbyA: [Vector2]?                   // 相7 → 相12
    private var rAUf: [Double]?                    // 相8 → 相9,11
    private var phiHbyA: SurfaceScalarField?       // 相8 → 相9,11
    private var pEqn: FvScalarMatrix?              // 相9 → 相10
    private var pInitRes = 0.0                     // 相10 → 相14(取末次 corrector)

    // —— D3 reset 用的初始快照（构造时拷贝一份）——
    private let U0: [Vector2]
    private let p0: [Double]

    public init(solver: IcoFoam) {
        self.solver = solver
        self.U0 = solver.U.internalField           // 值语义数组：拷贝
        self.p0 = solver.p.internalField
    }

    // —— 三个公开原语（§15.1 契约）——
    @discardableResult public func advance() -> SolveEvent   // 执行下一相位、就地更新场、返回事件
    public var atTimeStepBoundary: Bool {                    // 处于时间步边界（可干净停车 / 计步）
        if case .timeStepBegin = phase { return true } else { return false }
    }
    public func reset() {                                    // D3：编辑后重置重算
        solver.U.internalField = U0
        solver.p.internalField = p0
        solver.phi = solver.recreatePhi()                    // = fvc.flux(U0) ，与 init 一致
        phase = .timeStepBegin; step = 0; corrector = 0; pInitRes = 0
        ddtM = nil; divM = nil; lapM = nil; UEqn = nil; mom = nil
        rAU = nil; HbyA = nil; rAUf = nil; phiHbyA = nil; pEqn = nil
    }
}
```

### ④-1.6 `advance()` 的 `switch` 结构 —— 相位 ↔ 算术 ↔ 事件 对照表（核心图纸）

每一格的"算术"**逐字取自现 `IcoFoam.step()`**（只换了取场的写法 `solver.U` 等）；这就是 T5 的根据——同样的运算、同样的顺序、同样的操作数，只换了"在哪儿暂停"。

| 相位 | 算术（逐字取自现 `step()`）| 写入溢出字段 | 下一相位 | 返回 `SolveEvent` |
|---|---|---|---|---|
| `timeStepBegin` | `step += 1; corrector = 0`（`time = step·dt`）| — | `opDdt` | `.timeStepBegin(step, step·dt)` |
| `opDdt` | `ddtM = fvm.ddt(U)` | `ddtM` | `opDiv` | `.op(.ddt,.lhs,"fvm.ddt")` |
| `opDiv` | `divM = fvm.div(phi, U)` | `divM` | `opLaplacian` | `.op(.div,.lhs,"fvm.div")` |
| `opLaplacian` | `lapM = fvm.laplacian(nu, U)` | `lapM` | `assembleMomentum` | `.op(.laplacian,.lhs,"fvm.laplacian")` |
| `assembleMomentum` | `UEqn = (ddtM + divM) - lapM` | `UEqn` | `momPred ? opGradP : pisoBegin` | `.assembleMomentum("icoFoam.UEqn")` |
| `opGradP` | `var m = UEqn; gP = fvc.grad(p); for c { m.source[c] -= gP[c]*V }; mom = m` | `mom` | `solveMomentum` | `.op(.grad,.rhs,"fvc.grad(p)")` |
| `solveMomentum` | `let perf = gaussSeidel(mom, &U.internalField, 4)` | （`U` 改）| `pisoBegin` | `.solveMomentum(perf.initialResidual,"icoFoam.UEqn")` |
| `pisoBegin` | `A = UEqn.A(); H = UEqn.H(U); for c { rAU[c]=1/A[c]; HbyA[c]=rAU[c]*H[c] }` | `rAU,HbyA` | `opFlux` | `.pisoCorrectorBegin(corrector,"icoFoam.piso")` |
| `opFlux` | `phiHbyA = fvc.flux(HbyA, bc); rAUf = fvc.interpolate(rAU)` | `phiHbyA,rAUf` | `assemblePressure` | `.op(.flux,.rhs,"fvc.flux")` |
| `assemblePressure` | `pEqn = fvm.laplacianSPD(rAUf,p); 各内面 pEqn.source ∓= phiHbyA; pEqn.setReference(pRefCell,pRefValue)` | `pEqn` | `solvePressure` | `.assemblePressure(corrector,"icoFoam.pEqn")` |
| `solvePressure` | `let perf = conjugateGradient(pEqn, &p.internalField, 1e-6, 0.05); pInitRes = perf.initialResidual` | （`p` 改）`pInitRes` | `correctFlux` | `.solvePressure(corrector, perf.initialResidual,"icoFoam.pEqn")` |
| `correctFlux` | `各内面 phiHbyA -= w·dp; solver.phi = phiHbyA`（**值类型显式写回**）| （`solver.phi` 改）| `correctVelocity` | `.correctFlux(corrector,"field.phi")` |
| `correctVelocity` | `gP = fvc.grad(p); for c { U.internalField[c] = HbyA[c] - rAU[c]*gP[c] }` | （`U` 改）| `pisoEnd` | `.correctVelocity(corrector,"fvc.grad(p)")` |
| `pisoEnd` | （读 `solver.continuityError()` 仅供事件展示，**只读不改场**）| — | `corrector += 1; corrector < nCorr ? pisoBegin : timeStepEnd` | `.pisoCorrectorEnd(corrector, contErr,"icoFoam.piso")` |
| `timeStepEnd` | `report = StepReport(step·dt, courantMax(), pInitRes, continuityError(), uMax())` | — | `timeStepBegin`（下一步）| `.timeStepEnd(report)` |

**两处"多给数据、不改算术"**（事件流比旧 `StepReport` 更细，但不动数值）：
- `solveMomentum` 把 `gaussSeidel` 的返回（旧 `step()` 用 `@discardableResult` **丢弃**）捡回当残差载荷——读返回值不改求解过程。
- `pisoEnd` 为事件**额外**算一次 `continuityError()`（只读求和），让用户看到连续性误差逐子步下降；旧 `step()` 只在末尾算一次。**只读、不写场 → 不影响 T5。**

### ④-1.7 `step()` / `run()` 重构为游标包装（M0 测试不破）

```swift
extension IcoFoam {
    public private(set) lazy var cursor = SolveCursor(solver: self)   // 一个长生命周期游标

    @discardableResult
    public func step(time: Double = 0) -> StepReport {                // 驱动游标走完一个时间步
        while true {
            if case .timeStepEnd(let r) = cursor.advance() { return r }
        }
    }
    @discardableResult
    public func run(endTime: Double, onStep: ((Int, StepReport) -> Void)? = nil) -> [StepReport] {
        var reports: [StepReport] = []
        let nSteps = max(Int((endTime / dt).rounded()), 1)
        for s in 1...nSteps { let r = step(); reports.append(r); onStep?(s, r) }
        return reports
    }
}
```

> 联动层（④-3 详设）在 `advance()` 之上做**两档单步**：**相位级单步** = 调 1 次 `advance()`；**时间步级单步** = 循环 `advance()` 直到事件为 `.timeStepEnd`。播放 = 在后台把 `advance()` 包成 `AsyncStream<SolveEvent>`（并发只在联动层，引擎仍同步）。

### ④-1.8 T5 逐位一致论证（"切蛋糕不改配方"）

**命题**：对任意 n，"`reset()` 后纯靠 `advance()` 把游标推过 n 个 `timeStepEnd`"得到的 `U/p/phi`，与"`reset()` 后 `run(n·dt)`"得到的 `U/p/phi`，**逐位（bitwise）相同**。

**论证**（三段）：
1. **唯一算术源**：重构后 `step()`/`run()` 都只是循环调用 `cursor.advance()`（§④-1.7），**不含任何自己的数值运算**。故"连跑"和"单步"执行的是**同一个 `advance()` 函数体**，只是调用节奏不同。
2. **相位切分是行为保持的**：§④-1.6 每相位的算术**逐字搬自原 `step()`**，**运算、顺序、操作数全未变**；跨相位的局部量改存游标字段，是**存储位置**变化而非**数值**变化。唯一非"逐字照搬"的是把一行 `UEqn = ddt + div - laplacian` 拆成 4 相——单独证它逐位一致：
   - 三个算子函数 `fvm.ddt/div/laplacian` 是**纯函数**（只读 `U/phi/nu/mesh/dt`、不改场），相 1–3 之间 `U/phi` 未被任何相位写过（`U` 最早在相 6 才写）→ 三相读到的操作数与原一行**完全相同**；
   - 原式 `a + b - c` 在 Swift 里左结合 = `(a + b) - c`；相 4 用 `(ddtM + divM) - lapM`——**同样的 `+` 再 `-`、同样次序** → 系数逐位相同。
3. **暂停是状态的恒等变换**：游标**同步、无并发、不读时钟/随机数**；两次 `advance()` 之间不论停多久，游标状态原样不动。故"单步时的暂停"对最终场是 no-op。
   
   1 + 2 + 3 ⟹ 单步序列与连跑序列是**同一串浮点运算**，结果逐位一致。∎

### ④-1.9 可测试性设计：T5 / 回归 判据（无工具链，给"能写出的单测"）

| 判据 | 设计（⑤ 落成 XCTest）|
|---|---|
| **G1 黄金对拍（T5 主判据）** | 造两个同 `CaseData` 的 solver `A`、`B`；`A.run(0.5)`；`B` 仅靠 `B.cursor.advance()` 推进，直到累计 **N=100** 个 `.timeStepEnd`。断言 `A.U.internalField == B.U.internalField`（逐元素 `==`，**非** `accuracy`）、`p` 同、`phi.internalField` 同。|
| **G2 暂停不变性** | 同一 solver，"每相位 `advance()` 后插入无操作"对比"连续 `advance()`"——末场逐位相同（暂停 = 恒等）。|
| **G3 两档等价** | "相位级单步 14×k 次" == "时间步级单步 k 次" == `run(k·dt)`，三者逐位相同。|
| **G4 旧测试回归** | 现有 `CavityTests`（`run(0.5)` 后 `uMax<1.05`、`continuityError<1e-3`、回流为负）**原样通过**——因 `run()` 输出逐位不变。|
| **G5 事件序正确** | 一个时间步的事件序列 == §15.2 的 15 相（PISO 段重复 `nCorrectors` 次）；每个 `nodeID` 命中 §16 graph 的节点（接 ④-4）。|

### ④-1.10 诚实边界 / 已知缺口（登记，不阻塞 ④-1）

- **"展示未执行"行**：真实 icoFoam.C 的 `constrainHbyA`(L96)、`adjustPhi`(L99)、`constrainPressure`(L102) M0 未实现，**无对应相位**。源码面板照常显示这些行（ADR-002/§3），由联动层标"展示未执行"。非 T5 问题（这些行不在 Swift 算术里）。补齐留 M0 收尾/⑤。
- **`recreatePhi()`**：`reset()` 依赖一个"由初始 `U` 重算 `phi`"的工厂方法（= `init` 里 `fvc.flux(U0…)` 的同一段）；现 `IcoFoam.init` 内联了这段，⑤ 实现时抽成 `recreatePhi()` 供 `init` 与 `reset()` 共用（消除重复、保证一致）。
- **`lazy var cursor` 与值类型**：`phi` 经 `solver.phi = …` 回写依赖 `solver` 是 class（是）。若未来把 `IcoFoam` 改 struct，此设计需复审（目前 `IcoFoam` 为 `final class`，成立）。

### ④-1 小结

把 §15 草图精化为：1 个 `SolveEvent` 值枚举 + 1 个 `SolveCursor`（15 相位状态机 + 溢出字段 + `advance/atTimeStepBoundary/reset`）+ `step()/run()` 薄包装；给出**相位↔算术↔事件**逐格对照（算术逐字搬自现 `step()`）与 **T5 三段论证** + **5 条测试判据**。**引擎仍同步零 UI**（只产 `SolveEvent` 值）。遗留 3 条缺口已登记、不阻塞。

---

## ④-2　`FvMatrix` 探针只读访问器（按 cell 取该行 aP/aN）

### ④-2.1 在干嘛 / 为什么（一句话）

给 UC5 探针开一扇**只读窗口**：点一个 cell → 看它在矩阵里那一行（`aP·自己 + Σ aN·各邻居 = b`）。验收 **T6**：探针读到的 aP/aN 须与引擎矩阵该行**完全一致**。③§17.1 走查留的待办。

### ④-2.2 难点：矩阵按 LDU 稀疏存，"取一行"要沿面捡

引擎矩阵不按"网格表格"存，而是 OpenFOAM 的 **LDU**：只存`diag`（每 cell 一个 aP）+ 每条**内部面**的 `upper`/`lower`（见 `FvMatrix.swift` L16-38）。因为 CFD 矩阵绝大多数元素是 0（一 cell 只耦合紧邻几个）。代价：取第 c 行得**沿 c 的每条面把系数捡出来**——而这正是求解器 `gaussSeidel`/`H()` 已在做的事（`ref.isOwner ? upper[ref.face] : lower[ref.face]`，`LinearSolver.swift` L99-101）。探针**复用同一套寻址 `mesh.cellFaceRefs[c]`** → 与求解器读同一份系数 → **T6 由构造保证**。

### ④-2.3 设计决策

- **主选型（需求方已拍板）**：**A 交『矩阵行』结构**——引擎返回自描述的 `MatrixRow{cell, aP, neighbours:[(cell,aN)], b}`，正好是探针要显示的形状。引擎嚼细、UI 保持笨（关注点分离，ADR-008）；这个结构本身就是 T6 要核对的对象。（落选 B 原始散件 / C 暴露 LDU 数组：把"矩阵怎么存"的耦合漏给 UI。）
- **派生①　一个泛型 `MatrixRow<Source>`**：标量(p)/矢量(U) 两个矩阵的**系数 aP/aN 都是 `Double`**（几何/通量系数对每个速度分量相同，见 `LinearSolver` 注释 L86-87），**只有右端 b 类型不同**（`Double` vs `Vector2`）。故行骨架共用、用泛型参数化 `b` 的类型，避免重复寻址逻辑。
- **派生②　只读、不依赖场**：`row()` 只读矩阵自身（系数 + 右端），**不碰流场**。UC5 要的"**邻居贡献**" `aN·x_N` 由联动层把 `aN` 配上它手里的当前场值 `x_N` 算出——引擎给系数、UI 配场值，各管一段。

### ④-2.4 图纸：类型 + 访问器（可编译级；纯值类型、Equatable 供 T6 对拍）

```swift
public struct NeighbourCoeff: Equatable {
    public let cell: Int        // 邻居 cell id（点亮"离散模板"高亮用）
    public let aN: Double       // 该邻居的耦合系数（off-diagonal）
}

public struct MatrixRow<Source: Equatable>: Equatable {
    public let cell: Int                     // 被探的 cell
    public let aP: Double                    // 对角（自重）系数
    public let neighbours: [NeighbourCoeff]  // 各内部面邻居 + 其 aN
    public let b: Source                     // 右端项（p: Double / U: Vector2）
}

// 寻址复用：与 gaussSeidel/H() 同一套 cellFaceRefs → 读同一份系数（T6 根因）
extension LduCoeffs {
    func neighbourCoeffs(of cell: Int, mesh: StructuredMesh) -> [NeighbourCoeff] {
        mesh.cellFaceRefs[cell].map { ref in
            NeighbourCoeff(cell: ref.other,
                           aN: ref.isOwner ? upper[ref.face] : lower[ref.face])
        }
    }
}

extension FvScalarMatrix {                   // 压力 pEqn
    public func row(_ cell: Int) -> MatrixRow<Double> {
        MatrixRow(cell: cell, aP: coeffs.diag[cell],
                  neighbours: coeffs.neighbourCoeffs(of: cell, mesh: mesh),
                  b: source[cell])
    }
}
extension FvVectorMatrix {                    // 动量 UEqn
    public func row(_ cell: Int) -> MatrixRow<Vector2> {
        MatrixRow(cell: cell, aP: coeffs.diag[cell],
                  neighbours: coeffs.neighbourCoeffs(of: cell, mesh: mesh),
                  b: source[cell])
    }
}
```

### ④-2.5 供给侧：探针从哪拿到"当前矩阵"（连 ④-1 游标）

探针要读的是**当前那一步**的 `UEqn`/`pEqn`，它们是 ④-1 游标的溢出字段（`private`）。游标开两个**只读**口（§15"引擎向 UI 暴露只读数据"同源）：

```swift
extension SolveCursor {
    public var momentumMatrix: FvVectorMatrix? { UEqn }   // assemble 后有值，否则 nil
    public var pressureMatrix: FvScalarMatrix? { pEqn }
}
```

联动层（④-3）据探中 cell 取行：`cursor.pressureMatrix?.row(probedCell)` → `MatrixRow` → 画卡 + 高亮 `neighbours[].cell`。

### ④-2.6 边界的处理（设计须讲清，否则探针会"少一块"）

`cellFaceRefs[c]` **只含内部面**；**边界效应**（如 movingWall 的 Dirichlet）在装配时已并入 `diag[c]` 与 `source[c]`（`Fvm.laplacian` L74-80：`diag[bf.cell] -= w; source[bf.cell] -= w·Ub`）。故 `MatrixRow`：
- 不为边界面列"邻居"（边界没有"对侧 cell"）；
- 边界的影响**体现在 `aP` 偏大、`b` 含 `w·Ub`** 上。
→ 这忠实反映了**被求解的系统**（求解器看到的就是这个行），T6 成立。**UC5-E1（点到 patch 边界面）** 显示该 patch 的 BC（type/value）而非内部系数，由 UI 分流（④-3/④-5）；④-2 只覆盖"点到 cell"。

### ④-2.7 可测试性：T6 判据（无工具链，给"能写出的单测"）

| 判据 | 设计 |
|---|---|
| **T6-主（行=矩阵该行）** | 取随机解向量 `x` 与代表性 cell `c`，断言 `row(c).aP·x[c] + Σ_n aN_n·x[n] == LinearSolver.matVec(M,x)[c]`（**逐位**）。两边都用同一 `diag/upper/lower` → 必相等；这证明 `row(c)` 忠实等于 M 的第 c 行。矢量版同理（`Vector2` 运算）。|
| **T6-aP** | `row(c).aP == M.coeffs.diag[c]`。|
| **T6-模板** | `Set(row(c).neighbours.map{$0.cell})` == `c` 的内部面邻居集合（独立由 `cellFaceRefs` 列举）。|
| **T6-对称（pEqn 专属，加分）** | `pEqn` 对称（`laplacianSPD` 令 `upper==lower`）→ `row(c)` 到 n 的 `aN` == `row(n)` 到 c 的 `aN`。（动量 `div` 非对称，不适用——正好教"对流让矩阵不对称"。）|

### ④-2 小结

加 2 个值类型（`NeighbourCoeff` / 泛型 `MatrixRow<Source>`）+ 2 个 `row(_:)` 访问器（复用 `cellFaceRefs` 寻址）+ 游标 2 个只读矩阵口；T6 由"探针与求解器读同一份系数"**从构造上**保证。边界效应并入 aP/b 已讲清。引擎仍零 UI、只读不改场。

---

## ④-3　联动层 `SessionVM` 详细设计（单一事实源 + 状态机）

### ④-3.1 在干嘛 / 为什么（一句话）

`SessionVM` = 引擎游标（④-1）和 UI 之间的**调度台 + 一块"当前帧信息板"**。信息板 = **单一事实源**（所有面板只读它 → 永远一致）；调度台 = **状态机**（播放/暂停/两档单步/重置）。接住 UC4、FR5、D2、D3。

### ④-3.2 援引 ③ 契约（原文见对话；要点）

- `§1`/`§6`：联动层 `@Observable`，单一事实源 = `highlightedNodeID + iterationState + probedCell`；"一处操作、多处响应"。
- `§15.1` ADR-011：联动层在游标上提供 **`AsyncStream<SolveEvent>`（播放）** 与 **`step()/stepSubPhase()`（两档单步）**。
- `§15.3`：消费事件 `highlightedNodeID ← event.nodeID`、`iteration ← (step,corrector,residual)`；**播放用流拉取、单步直呼 `advance()`**；引擎仍零 UI。
- `§15.2`：时间步单步 = advance 至 `timeStepEnd`；PISO 子步单步 = advance 一相位即停。
- `§14` D2 两档单步 / D3 重置重算（`cursor.reset()`）。
- `UC4` 后置：迭代状态为单一事实源，所有面板一致；重置二次确认（E1）。

### ④-3.3 设计决策（A + 派生）

- **主选型（需求方拍板）**：**A 主线程计时器/异步循环**驱动播放——主线程开一个**可取消的异步循环**把同步 `advance()` 包成节奏可控的事件流；暂停=取消循环。**不引入后台线程**，引擎保持同步确定（T5/ADR-001 不破）。（落选 B 后台线程：并发入侵、与 T5 精神相悖；C 绑帧率：变速/单步难做。）
- **派生①**：`SessionVM` 标 `@MainActor @Observable`；播放 `Task` 跑在主 actor，与 `advance()` 串行 → 无数据竞争。
- **派生②**：用显式 `enum PlaybackState` 当状态机（呼应 ④-1 状态机教法）。
- **派生③**：可视化场（④⑤）用**快照发布**——VM 在时间步末把 `U/p` 拷进 `@Observable` 数组（20×20=400 cell，拷贝极廉），触发 SwiftUI 刷新；避免"改引擎内部数组不触发观察"的坑。

### ④-3.4 图纸：单一事实源字段（精化 §6 草图）

```swift
struct IterationState: Equatable {
    var step = 0;  var time = 0.0          // 时间步 / 物理时刻
    var corrector = 0                       // 当前 PISO 子步 (0..<nCorr)
    var phaseLabel = ""                     // 当前相位人话名（"组装动量"/"解压力"…）→ ⑨
    var uResidual = 0.0, pResidual = 0.0    // 最近动量/压力残差
    var continuityError = 0.0
}
enum PlaybackState: Equatable { case idle, playing, paused, finished }
struct ResidualPoint: Equatable { let step: Int; let corrector: Int; let residual: Double }

@MainActor @Observable
final class SessionVM {
    // —— 单一事实源（所有面板只读这里）——
    var highlightedNodeID: String?          // 执行游标脉冲：点亮源码行/公式/思维导图节点
    var iteration = IterationState()        // 迭代坐标
    var probedCell: Int?                     // 探针选中的 cell（UC5/④-2）
    var playback: PlaybackState = .idle      // 播放器状态机
    var residualHistory: [ResidualPoint] = [] // ⑥ 残差曲线累积
    var velocity: [Vector2] = []            // ④ 矢量图快照（时间步末刷新）
    var pressure:  [Double]  = []           // ⑤ 压力云图快照
    var lastReport: StepReport?             // 状态栏/⑨

    private let solver: IcoFoam
    private var cursor: SolveCursor { solver.cursor }
    private let endTime: Double             // 来自 controlDict
    private var playTask: Task<Void, Never>?
    var playbackPacing: Duration = .milliseconds(40)  // 播放节奏（变速）

    init(solver: IcoFoam, endTime: Double) { self.solver = solver; self.endTime = endTime }
}
```

### ④-3.5 图纸：消费事件流（apply）+ 播放适配（AsyncStream）+ 播放/暂停

```swift
extension SessionVM {
    // —— 把一张事件卡"写进信息板"（§15.3：nodeID/step/corrector/residual ← event）——
    private func apply(_ e: SolveEvent) {
        switch e {
        case .timeStepBegin(let s, let t):       iteration.step = s; iteration.time = t; iteration.corrector = 0
        case .op(_, _, let id):                  highlightedNodeID = id; iteration.phaseLabel = label(e)
        case .assembleMomentum(let id):          highlightedNodeID = id
        case .solveMomentum(let r, let id):      highlightedNodeID = id; iteration.uResidual = r
        case .pisoCorrectorBegin(let i, let id): iteration.corrector = i; highlightedNodeID = id
        case .assemblePressure(let i, let id):   iteration.corrector = i; highlightedNodeID = id
        case .solvePressure(let i, let r, let id):
            iteration.corrector = i; iteration.pResidual = r; highlightedNodeID = id
            residualHistory.append(ResidualPoint(step: iteration.step, corrector: i, residual: r))
        case .correctFlux(let i, let id), .correctVelocity(let i, let id):
            iteration.corrector = i; highlightedNodeID = id
        case .pisoCorrectorEnd(let i, let ce, _): iteration.corrector = i; iteration.continuityError = ce
        case .timeStepEnd(let report):
            lastReport = report
            velocity = solver.U.internalField    // 快照 → 触发 ④⑤ 刷新（派生③）
            pressure = solver.p.internalField
        }
    }

    // —— 播放适配（§15.1 "AsyncStream 作播放适配"）：同步 advance() 包成事件流，主 actor，无后台线程 ——
    private func makeEventStream() -> AsyncStream<SolveEvent> {
        AsyncStream { continuation in
            let task = Task { @MainActor in
                while cursor.time < endTime {
                    continuation.yield(cursor.advance())
                    try? await Task.sleep(for: playbackPacing)   // 节奏 + 让位 SwiftUI 重绘
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    func play() {
        guard playback != .playing, cursor.time < endTime else { return }
        playback = .playing
        playTask = Task { @MainActor in
            for await e in makeEventStream() {
                guard playback == .playing else { break }
                apply(e)
            }
            if cursor.time >= endTime { playback = .finished }
        }
    }
    func pause() { guard playback == .playing else { return }; playback = .paused; playTask?.cancel(); playTask = nil }
}
```

### ④-3.6 图纸：两档单步（D2）+ 重置（D3）+ 探针接线（④-2）

```swift
extension SessionVM {
    // D2-档1：PISO 子步级（advance 一相位即停，§15.2）
    func stepPhase() {
        guard playback != .playing else { return }
        apply(cursor.advance()); playback = .paused
    }
    // D2-档2：时间步级（advance 到 timeStepEnd，§15.2）
    func stepTimeStep() {
        guard playback != .playing else { return }
        while true { let e = cursor.advance(); apply(e); if case .timeStepEnd = e { break } }
        playback = .paused
    }
    // D3：重置重算（编辑后）。UI 侧先二次确认（UC4-E1）再调本方法
    func reset() {
        pause(); cursor.reset()
        iteration = IterationState(); highlightedNodeID = nil; lastReport = nil
        residualHistory.removeAll(); velocity = []; pressure = []; playback = .idle
    }
    // 探针（UC5 / ④-2）：读当前压力矩阵该行
    func probe(cell: Int?) { probedCell = cell }
    var probedRow: MatrixRow<Double>? { probedCell.flatMap { cursor.pressureMatrix?.row($0) } }
}
```

### ④-3.7 单一事实源 → 各面板 映射（"一处操作、多处响应"落地）

| 信息板字段 | 驱动哪些面板（§6 编号）|
|---|---|
| `highlightedNodeID` | ③源码行高亮 + ①公式高亮 + 思维导图节点脉冲（§16）|
| `iteration`（step/corrector/phaseLabel/残差）| ⑨时间轴/子步指示灯 + 状态栏 |
| `residualHistory` | ⑥残差/收敛曲线 |
| `velocity` / `pressure` | ④速度矢量·流线 / ⑤压力云图 |
| `probedCell` / `probedRow` | ②数据探针（aP/各 aN + 高亮邻居 cell）|

> 机制：以上全是 `@Observable` 属性；`apply()` 一改，SwiftUI 各面板**自动**重算。引擎只产 `SolveEvent` 值，不知道有谁在看（ADR-001/ADR-008）。

### ④-3.8 ③ ↔ ④ 对应表

| ③ 架构原文（出处）| ④-3 把它落成 |
|---|---|
| §1/§6 单一事实源 `highlightedNodeID/iterationState/probedCell` | `SessionVM` 的 `@Observable` 字段（+ 播放态/残差史/场快照）|
| §6 "一处操作、多处响应" | `apply(event)` 写板 → `@Observable` 触发各面板刷新（§④-3.7 映射）|
| §15.1 "AsyncStream（播放）+ step()/stepSubPhase()（两档单步）" | `makeEventStream()→AsyncStream` 供 `play()` 消费；`stepTimeStep()/stepPhase()` 两档 |
| §15.3 "nodeID/step/corrector/residual ← event；播放走流、单步直呼 advance" | `apply()` 的 switch 写板；`play()` 走流、`stepX()` 直呼 `cursor.advance()` |
| §15.2 两档单步语义 | `stepTimeStep()` 循环到 `.timeStepEnd`；`stepPhase()` advance 一次 |
| §14 D2 / D3 | `PlaybackState` + 两单步命令 / `reset()=cursor.reset()+清板` |
| UC4 后置"所有面板一致" | 面板只读 `SessionVM`；播放与单步共用 `advance()` ⇒ 终态一致（继承 T5）|

### ④-3.9 可测试性判据（无 UI 也能测）

| 判据 | 设计 |
|---|---|
| **S1 播放=单步（终态一致）** | 同 case 两个 VM：A `play()` 跑到 `finished`；B 反复 `stepPhase()` 到末。断言 `A.velocity == B.velocity`、`pressure` 同（继承 ④-1 T5）。|
| **S2 状态机合法** | 枚举 play→pause→stepPhase→play→reset 序列，断言 `PlaybackState` 转移合法、`reset()` 后 `iteration==IterationState()`、`residualHistory` 空。|
| **S3 板=事件** | 喂一串已知 `SolveEvent`，断言 `apply` 后 `iteration/highlightedNodeID/residualHistory` 与事件载荷逐一对应。|
| **S4 探针接线** | `probe(cell:c)` 后 `probedRow == cursor.pressureMatrix?.row(c)`（接 ④-2 T6）。|

### ④-3.10 诚实边界 / 连带增补

- **连带给 ④-1 游标加 2 个只读口**（小增补，登记）：`var time: Double { Double(step)*dt }`（播放循环判终点用）；`pressureMatrix/momentumMatrix`（④-2 已加）。
- **播放节奏 vs 逐相位脉冲**：`playbackPacing` 大 → 能看清源码高亮逐相位移动；≈0 → 视觉上每时间步刷新一次。两者底层都是同一串 `advance()`，不影响数值。
- **`label(_:)`**（相位→人话名）是纯展示映射表，⑤实现时补；不影响逻辑。

### ④-3 小结

`SessionVM` = `@MainActor @Observable` 单一事实源（节点高亮/迭代/探针/播放态/残差史/场快照）+ 状态机（`play` 走主 actor `AsyncStream`、`stepPhase`/`stepTimeStep` 两档直呼 `advance`、`reset` 重置）。**播放与单步共用同一套 `advance()`** ⇒ 终态一致（继承 T5）、引擎仍零 UI。给出 §④-3.7 面板映射 + ③↔④ 对应表 + 4 条测试判据。

---

## ④-4　资源层契约 `Codable` 类型 + 构建期 lint 插件

### ④-4.1 在干嘛 / 为什么（一句话）

资源层 = 一批"教学内容数据"（卡片：源码/公式/解释；思维导图：节点+边）。④-4 把 ③ §16 的 **JSON 契约**落成具体 **Swift `Codable` 类型**（对象↔JSON 自动互转），再设计一个**构建期 lint 插件**当"出版前校对员"，自动体检数据（接验收 **T7 映射真实性**）。

### ④-4.2 援引 ③ 契约（原文见对话；要点）

- `§16.1` 顶层：`{version, mappings, graph{nodes,edges}, contextPackHook}`；node 带 `mappingId` 指回卡片、`x/y` 可选(D4)。
- `§16.2` 纪律：①节点不重复存源码、`mappingId` 指回；②坐标可选；③`contextPackHook` 留挂点不实现。
- `§16.3` lint：①`edge.from/to`∈nodes；②`type/arrow`在枚举内；③非`concept`节点`sourceFile:行区间`真实存在(=T7)；④无孤儿。
- `§3.2` 枚举：`node.kind` / `edge.type` / `edge.arrow`（取值见下）。
- `§5` 卡片字段：id/title/swiftSymbol/sourceFile/lineStart/lineEnd/explanationMD/latex/relatedImpl。
- `§5(②)` **T7**：每个非 concept 节点的源码行区间在真仓库**存在且内容一致**。

### ④-4.3 设计决策

- **主选型（需求方拍板）**：**A 构建期插件**——做成 SwiftPM `BuildToolPlugin`，编译 App 时自动跑 lint；数据违规→**编译失败**（红灯、最早拦截，贴合 §16.3「打包时跑」）。
- **派生①　枚举把非法值挡在门外**：`kind/type/arrow` 用 Swift 枚举 → JSON 写了非法值，**`Codable` 解码阶段就抛错**，根本生不成 `ResourceBundle`。故 §16.3 规则②**由解码守门、无需额外运行时检查**（与 ④-2「T6 由构造保证」同一精神）。
- **派生②　唯一事实源**：源码/公式/解释只存在 `mappings` 卡片里；`graph` 节点只用 `mappingId` 指回（§16.2 纪律①），lint 额外检查"`mappingId` 指向的卡片存在"。

### ④-4.4 图纸：`Codable` 类型（JSON 契约 → 可编译类型）

```swift
public struct ResourceBundle: Codable, Equatable {
    public var version: Int                       // 格式版本（加字段只升版本、不破旧数据）
    public var mappings: [MappingEntry]           // §5 卡片
    public var graph: Graph                        // §16 思维导图
    public var contextPackHook: ContextPackHook?   // FR7/M5 预留，现为 nil
}

public struct MappingEntry: Codable, Equatable {  // §5 卡片：symbol → 源码/公式/解释
    public var id: String                          // "fvm.laplacian"
    public var title: String
    public var swiftSymbol: String?                // "Fvm.laplacian(_:_:)"
    public var sourceFile: String
    public var lineStart: Int
    public var lineEnd: Int
    public var explanationMD: String               // Markdown 解释
    public var latex: String?                      // 交 SwiftMath 渲染
    public var relatedImpl: String?
}

public struct Graph: Codable, Equatable {
    public var nodes: [GraphNode]
    public var edges: [GraphEdge]
}

public struct GraphNode: Codable, Equatable {
    public var id: String
    public var kind: NodeKind
    public var title: String
    public var sourceFile: String?                 // concept 节点可无源码
    public var lineStart: Int?
    public var lineEnd: Int?
    public var mappingId: String?                  // 指回 mappings 卡片（不重复存源码）
    public var x: Double?                          // D4 手工坐标，可选（缺省不失效）
    public var y: Double?
}

public struct GraphEdge: Codable, Equatable {
    public var from: String                        // node id
    public var to: String                          // node id
    public var type: EdgeType
    public var arrow: EdgeArrow
    public var label: String?
}

// 三个枚举 = §3.2；非法值在 Codable 解码阶段即被拒（“把非法值挡在门外”）
public enum NodeKind: String, Codable, CaseIterable {
    case solver, equationAssembly, op = "operator", field, control, concept   // op 因 operator 是关键字
}
public enum EdgeType: String, Codable, CaseIterable {
    case assembles, calls, dataFlow, contributesLHS, contributesRHS, derivedFrom, mathEquiv, inherits
}
public enum EdgeArrow: String, Codable, CaseIterable { case single, double, none }

public struct ContextPackHook: Codable, Equatable { /* M5 预留，现空壳 */ }
```

### ④-4.5 图纸：lint 校验逻辑（§16.3 四规则 + T7）

```swift
public struct LintError: Equatable { public let location: String; public let message: String }

public enum ResourceLinter {
    /// sourceRoot = 真仓库根，用于 T7 行区间核验。返回空数组 = 体检通过（绿灯）。
    public static func lint(_ b: ResourceBundle, sourceRoot: URL) -> [LintError] {
        var errs: [LintError] = []
        let nodeIDs = Set(b.graph.nodes.map(\.id))
        let mapIDs  = Set(b.mappings.map(\.id))

        // 规则①：edge.from/to 必须存在于 nodes
        for e in b.graph.edges {
            if !nodeIDs.contains(e.from) { errs.append(.init(location: "edge \(e.from)→\(e.to)", message: "from 节点不存在")) }
            if !nodeIDs.contains(e.to)   { errs.append(.init(location: "edge \(e.from)→\(e.to)", message: "to 节点不存在")) }
        }
        // 规则②：type/arrow 在枚举内 —— 已由 Codable 解码守门（非法值解码即失败），此处无需再查。

        // 规则③ = T7：非 concept 节点的 sourceFile:行区间在真仓库真实存在
        for n in b.graph.nodes where n.kind != .concept {
            guard let f = n.sourceFile, let s = n.lineStart, let e = n.lineEnd else {
                errs.append(.init(location: "node \(n.id)", message: "非 concept 节点缺 sourceFile/行号")); continue
            }
            let url = sourceRoot.appendingPathComponent(f)
            guard let total = try? String(contentsOf: url).split(separator: "\n", omittingEmptySubsequences: false).count else {
                errs.append(.init(location: "node \(n.id)", message: "源码文件不存在: \(f)")); continue
            }
            if s < 1 || e < s || e > total {
                errs.append(.init(location: "node \(n.id)", message: "行区间 \(s)-\(e) 超出 1-\(total)"))
            }
        }
        // 规则④：无孤儿节点（每个节点至少被一条边触及）
        let touched = Set(b.graph.edges.flatMap { [$0.from, $0.to] })
        for n in b.graph.nodes where !touched.contains(n.id) {
            errs.append(.init(location: "node \(n.id)", message: "孤儿节点：无任何边相连"))
        }
        // 附加（§16.2 纪律①）：mappingId 必须指向存在的卡片
        for n in b.graph.nodes {
            if let m = n.mappingId, !mapIDs.contains(m) {
                errs.append(.init(location: "node \(n.id)", message: "mappingId 指向不存在的卡片: \(m)"))
            }
        }
        return errs
    }
}
```

### ④-4.6 图纸：SwiftPM 构建插件（你选的 A —— 编译时跑、违规即失败）

```swift
// 注册为 BuildToolPlugin；构建 App 时自动执行。
@main struct ResourceLintPlugin: BuildToolPlugin {
    func createBuildCommands(...) async throws -> [Command] {
        // 1) 定位资源 JSON（Resources/mapping.json）+ 仓库源码根（用于 T7）
        // 2) 解码 ResourceBundle —— 解码失败(非法枚举/结构) 即构建失败（规则②守门）
        // 3) ResourceLinter.lint(bundle, sourceRoot:) → 每条 LintError 作为 build 诊断 error 发出
        //    有 error → 红灯：构建失败，开发当场看到坏映射
    }
}
```

> 诚实边界：① T7 的"**内容一致**"本设计核到"路径+行区间存在"；逐字内容核对可加一条"快照测试"（把行区间文本存基线、变更即提示），属增强项。② 插件构建期需读真仓库源码做 T7；上架包内嵌的是冻结的源码片段（§5），开发期 `sourceRoot`=仓库根。

### ④-4.7 ③ ↔ ④ 对应表

| ③ 架构原文（出处）| ④-4 落成 |
|---|---|
| §16.1 顶层 `{version,mappings,graph,contextPackHook}` | `ResourceBundle: Codable`（4 字段一一对应）|
| §16.1 node 字段(含 mappingId / x,y) | `GraphNode: Codable`（sourceFile/x/y 为可选）|
| §16.1 edge 字段(from/to/type/arrow/label) | `GraphEdge: Codable` |
| §5 卡片字段 | `MappingEntry: Codable` |
| §3.2 三枚举(kind/type/arrow) | `NodeKind`/`EdgeType`/`EdgeArrow`（非法值解码即拒）|
| §16.2 纪律①(mappingId 指回) | `GraphNode.mappingId` + lint 查它指向存在卡片 |
| §16.2 纪律②(坐标可选) | `x/y: Double?` |
| §16.2 纪律③(ContextPack 挂点) | `contextPackHook: ContextPackHook?` = nil |
| §16.3 lint 规则①②③④ + T7 | `ResourceLinter.lint()` 四查 + 解码守门 + 行区间核验 |
| §16.3「打包时跑」| SwiftPM `BuildToolPlugin`（选型 A）|

### ④-4.8 可测试性：T7 / lint 判据

| 判据 | 设计 |
|---|---|
| **T7 主判据** | 用**真实** icoFoam 映射包跑 `lint(bundle, sourceRoot: 仓库根)` → 返回**空数组**（每个节点行区间在真仓库都存在）。|
| L1 断边 | 边指向不存在节点 → 报"from/to 节点不存在"。|
| L2 越界行号 | 节点行区间超文件长度 → 报"行区间超出"。|
| L3 孤儿 | 无边相连的节点 → 报"孤儿节点"。|
| L4 非法枚举 | JSON 写 `"type":"bogus"` → **解码即抛错**（生不成 bundle），构建失败。|
| L5 悬空 mappingId | `mappingId` 指向不存在卡片 → 报。|

### ④-4 小结

把 §16 JSON 契约落成 6 个 `Codable` 类型 + 3 个枚举（非法值解码即拒）；lint 实现 §16.3 四规则 + T7 行区间核验 + mappingId 完整性；封装为 SwiftPM 构建插件（违规→编译失败）。给出 ③↔④ 对应表 + T7 主判据（真包跑 lint 返回空）。

---

## ④-5　编辑闭环（ADR-010）：CaseData ↔ 表单 ↔ dict 文本

### ④-5.1 在干嘛 / 为什么（一句话）

同一份算例参数有三个样子要时刻一致：`CaseData`(结构化真数据) / 表单(滑杆等控件，NFR3) / dict 文本(真字典文字，教学法)。④-5 设计这套**三方同步** + **越界钳制**(UC2-E1/NFR2/C4) + **文本非法行级报错**(UC2-E2)。

### ④-5.2 援引 ③ 契约（原文见对话；要点）

- `ADR-010`：图形控件 + 等价 dict 文本**双向同步**，编辑作用于结构化 `CaseData`；负面债 = 双向同步 + 文本侧校验(UC2-E2)。
- `§4.4` `CaseData`（已冻结）：control/schemes/solution/properties/mesh/fields + solver。
- `UC2`：主流程④双向同步、⑤确认→重置重算(D3)；E1 越界钳制+解释；E2 文本非法行级标错不重算；E3 运行中编辑自动暂停。
- `T2`改参重算 / `T3`越界钳制 / `T4`非法字典行级报错。

### ④-5.3 设计决策（A + 派生）

- **主选型（需求方拍板）**：**A `CaseData` 当唯一事实源（中枢）**。表单、文本都是它的**投影**：改哪个都先回流进 `CaseData`，再由它刷新另一个；文本非法只在文本侧标红、**不污染** `CaseData`（UC2-E2）。（落选 B 三方对等绑定：非法状态会传染、易死循环；C 文本只读：违反 FR2/ADR-010。）
- **派生①　编辑来源守卫，防回流死循环**：一个 `active: {none,form,text}` 标记。表单改 → 写 `CaseData` → **程序性**重渲染文本（不触发解析）；文本改 → 解析 → 写 `CaseData`（表单经 `@Observable` 自动刷），**不**回渲文本（免冲掉光标）。
- **派生②　钳制是写入 `CaseData` 的必经闸门**：表单值、解析出的文本值，**都过一遍 `SafetyRules`**，越界即拉回 + 给解释 → `CaseData` 永远合法（NFR2/C4）。

### ④-5.4 图纸：校验/钳制 + 文本投影/解析

```swift
public struct ClampResult<T> { public let value: T; public let message: String? }  // message≠nil=被钳制

public enum SafetyRules {                          // NFR2 / C4 防呆
    /// deltaT 受 Courant 约束 Co = lidSpeed·deltaT/dx ≤ coMax
    public static func clampDeltaT(_ dt: Double, lidSpeed: Double, dx: Double, coMax: Double = 1.0) -> ClampResult<Double> {
        let safeMax = coMax * dx / max(lidSpeed, 1e-9)
        return dt > safeMax
            ? .init(value: safeMax, message: "deltaT=\(dt) 时 Courant>\(coMax)，会发散；已限制为 \(safeMax)")
            : .init(value: dt, message: nil)
    }
    // clampNu(>0) / clampNCells(≥1) / clampEndTime(>0) … 各字段同构
}

public struct LineError: Equatable { public let line: Int; public let message: String }
public enum ParseResult { case ok(CaseData); case errors([LineError]) }
public enum DictText {
    public static func render(_ c: CaseData) -> String { /* CaseData → 规范 dict 文本 */ }
    public static func parse(_ text: String) -> ParseResult { /* MVP：只解析 cavity 子集；非法 token → [LineError] */ }
}
```

### ④-5.5 图纸：`EditorVM`（唯一事实源 + 三方同步 + 提交）

```swift
@MainActor @Observable
public final class EditorVM {
    public private(set) var caseData: CaseData        // 唯一事实源(A)，永远合法
    public private(set) var dictText: String          // 文本投影
    public private(set) var lineErrors: [LineError] = []   // 文本侧行级报错（UC2-E2）
    public private(set) var clampNotice: String?      // 越界钳制解释（UC2-E1）
    public private(set) var isDirty = false

    private enum Surface { case none, form, text }
    private var active: Surface = .none               // 防回流循环的"编辑来源"守卫
    private unowned let session: SessionVM            // 接 ④-3：提交后 reset+重算
    private var dx: Double { caseData.mesh.length / Double(caseData.mesh.nx) }
    private var lidSpeed: Double { caseData.movingWallSpeed }

    public init(caseData: CaseData, session: SessionVM) {
        self.caseData = caseData; self.session = session
        self.dictText = DictText.render(caseData)
    }

    // 表单路径：校验钳制 → 写 CaseData → 程序性刷新文本
    public func setDeltaT(_ dt: Double) {
        active = .form
        let r = SafetyRules.clampDeltaT(dt, lidSpeed: lidSpeed, dx: dx)
        caseData.control.deltaT = r.value
        clampNotice = r.message
        dictText = DictText.render(caseData)           // 程序性，不触发解析
        lineErrors = []; isDirty = true; active = .none
    }
    // setLidSpeed / setNu / setNCorrectors … 同构，均经各自 clamp

    // 文本路径：解析 → 合法写 CaseData（表单自动刷）；非法只标红、不污染
    public func editText(_ newText: String) {
        active = .text
        dictText = newText
        switch DictText.parse(newText) {
        case .ok(let parsed): caseData = clampAll(parsed); lineErrors = []; isDirty = true
        case .errors(let errs): lineErrors = errs       // 行级标红、不动 caseData（UC2-E2/T4）
        }
        active = .none
    }

    public func beginEditing() { if session.playback == .playing { session.pause() } }  // UC2-E3
    public func commit() {                              // D3 重置重算（接 ④-3）
        guard lineErrors.isEmpty else { return }
        session.applyCaseData(caseData); session.reset(); isDirty = false; clampNotice = nil
    }
}
```

### ④-5.6 三方同步数据流

```
表单改值 ──校验钳制──▶ CaseData ──render──▶ dict 文本   （程序性，不回触发解析）
dict 文本改 ──parse──▶ 合法? ─是─▶ 钳制 ─▶ CaseData ──@Observable──▶ 表单自动刷新
                         └─否─▶ lineErrors(行级标红)  ✗不动 CaseData ✗不重算
提交 commit ─▶ session.applyCaseData + session.reset()（D3 重置重算）
```

> 关键：**所有入口都先汇进 `CaseData`、且都过钳制** → `CaseData` 恒合法；文本是唯一可能"暂时非法"的地方，其非法被 `lineErrors` 隔离在文本侧，不外溢。

### ④-5.7 ③ ↔ ④ 对应表

| ③ 架构原文（出处）| ④-5 落成 |
|---|---|
| ADR-010 表单↔dict 双向同步、作用于 `CaseData` | `EditorVM` 以 `caseData` 为唯一事实源(A)，表单/文本为投影 |
| ADR-010「文本侧校验(UC2-E2 行级标错)」| `editText`→`parse`→`.errors`→`lineErrors`，不污染 caseData |
| §4.4 `CaseData`（冻结）| `EditorVM.caseData`（中枢）|
| UC2 主流程④ 双向同步 | `setX()`(表单→CaseData→render) + `editText()`(文本→parse→CaseData) |
| UC2-E1 / T3 越界钳制+解释 | `SafetyRules.clamp*`→`ClampResult(value,message)`→`clampNotice` |
| UC2-E2 / T4 文本非法行级标错 | `DictText.parse`→`[LineError]`→`lineErrors`，`commit` 拦截 |
| UC2-E3 运行中编辑自动暂停 | `beginEditing()`→`session.pause()` |
| UC2 主流程⑤ / D3 确认→重置重算 | `commit()`→`session.applyCaseData`+`session.reset()` |

### ④-5.8 可测试性判据

| 判据 | 设计 |
|---|---|
| **T3 越界钳制** | `setDeltaT(1.0)` → `deltaT==safeMax` 且 `clampNotice!=nil`（带原因）。|
| **T4 非法字典** | `editText(非法)` → `lineErrors` 非空、`caseData` 不变、`commit()` 被拦。|
| **T2 同步/往返** | 任意合法 `c`：`parse(render(c))==.ok(c)`；`setLidSpeed` 后 `dictText` 同步含新值。|
| 防循环 | `setDeltaT` 不触发 `editText` 路径（`active` 守卫）。|
| UC2-E3 | 运行中 `beginEditing()` → `session.playback==.paused`。|

### ④-5 小结

以 `CaseData` 为唯一事实源(A)：表单/文本皆投影、入口都经 `SafetyRules` 钳制 → `CaseData` 恒合法；文本非法被 `lineErrors` 隔离（UC2-E2）；`active` 守卫防循环；`commit` 接 ④-3 `reset` 重算(D3)、运行中编辑自动暂停(UC2-E3)。给出三方数据流 + ③↔④ 对应表 + 5 条判据。

---

## ④-6（可选）D1 侧栏 UX 评审：点节点后源码怎么呈现

> 纯 UX 评审，无新增引擎/代码契约。D1 是 ③ 唯一标注"可回退、不进不可变 ADR"的暂定项。

### ④-6.1 在干嘛 / 为什么

UC6「读源码对照」：点思维导图一个节点 → 它对应的**完整真实 OpenFOAM 源码**要显示出来。问题：**显示在哪？** ③ 暂定「固定侧栏」并留给 ④ UX 复核（D1）。④-6 复核之。

### ④-6.2 援引 ③（原文）

- `§14 D1`：UC6 detail 呈现 = **固定侧栏（地图常驻 + 源码并排）；暂定，待 UI 评审验证，效果不佳可回退浮层**。理由：overview+detail 同屏是思维导图教法核心；契合 NFR6 iPad 横屏多栏。代价：源码栏宽度受限。**可回退，不进不可变 ADR**。
- `UC6` 主流程④：展开该模块**完整真实源码**（detail，浮层或侧栏，见 D1）+ ①数学高亮 + ④结果闪烁。

### ④-6.3 两种布局对比

| | 固定侧栏 | 浮层 |
|---|---|---|
| 形态 | 屏幕两栏：地图常驻 ‖ 源码并排 | 点节点→源码弹出盖住地图 |
| 好处 | **地图+源码同屏对照**（思维导图教法命脉）；契合 iPad 横屏多栏(NFR6) | 源码占满宽，长 C++ 行舒服 |
| 代价 | 源码栏窄、长 C++ 行易挤 | **丢失地图**，看不到"我在整体何处"，破坏 overview+detail 同屏 |

### ④-6.4 评审结论（推荐 + 可回退）

1. **默认「固定侧栏」**：思维导图教法的命脉=全局地图与细节**同屏对照**，唯侧栏可达；NFR6 横屏多栏契合。
2. **补「放大源码」开关**化解唯一代价：点一下源码临时铺满全宽（舒服读长 C++），再点弹回并排。既保教法、又能舒服读码。
3. **窄屏响应式退化**：iPad 竖屏 / iPhone 过窄 → 自动退化为浮层或上下堆叠。
4. **D1 维持可回退暂定**（不进不可变 ADR）：待 **M2** 真 UI 做出后真机复核；不佳则按 ③ 预案回退纯浮层。

### ④-6 小结

确认「固定侧栏（地图常驻 + 源码并排）」为默认 + 「放大源码」开关化解窄栏代价 + 窄屏响应式退化为浮层；D1 维持可回退、待 M2 真机复核。纯 UX，无新增引擎/代码契约。

---

## ④-7　阶段末评审与冻结（v1.0）

> 评审方法（沿用③纪律）：设计阶段无可执行程序 → 不能"跑测试"(可验收) → 用**人脑系统化检查**(可评审)。两手法：**场景走查**(②用例在设计上走通、每步落具体零件) + **断言核实**(事实声称对真仓库查证)。④特有自检：接口签名"脑内可编译"、关键算法有测试判据（见各块 §x.8/9）。

### ④-7.1 场景走查（②用例 → ④ 是否接得住）

| ②用例 | 在④上的走法（落到的零件）| 结论 |
|---|---|---|
| UC1 运行案例 | 运行 → `SolveCursor.advance()`循环(④-1) → `SessionVM.apply`刷单一事实源(④-3) → ④⑤⑥刷新 | ✅ |
| UC2 编辑输入 | `EditorVM`三方同步+钳制(④-5) → `commit` → `SessionVM.reset`重算(④-3/D3)；E1钳制/E2行级报错/E3自动暂停 | ✅ |
| UC4 控制过程 | 暂停/两档单步/播放/重置 ← `SessionVM`(④-3)驱动`cursor.advance`(④-1) | ✅ |
| UC5 探查单元 | 点cell → `SessionVM.probe`(④-3) → `cursor.pressureMatrix.row(cell)`(④-2) → `MatrixRow` | ✅ |
| UC6 读源码对照 | `highlightedNodeID`(④-3)←`event.nodeID`(④-1)；源码/公式←`mappings/graph`(④-4)；侧栏(④-6) | ✅ |
| **UC3 看结果** | ④⑤云图←`velocity/pressure`快照(④-3)、⑥曲线←`residualHistory`；**"拖时间轴回放过去时刻流场"无数据源**（④-3 只存最新一帧、无逐步历史）| 🔴 **发现洞** |

> **走查发现 ④遗留-1（非阻塞）**：UC3「拖动时间轴回放流场演化」缺数据源——`SessionVM` 仅留最新 `velocity/pressure`。**解法（留⑤/M1）**：① 每时间步存一份 U/p 快照（20×20×N 内存极小）；或 ② 拖到第 N 步则 `reset`+重跑 N 步（20×20 很快）。验收 T 测试无 UC3 回放项，不阻塞冻结。

### ④-7.2 断言核实（事实声称 → 真仓库/真代码）

本会话读真实 `icoFoam.C`(L67–131) 对 ④-1/§15.2 相位行号，逐条命中：

| ④ 声称 | 真实 `icoFoam.C` | 结论 |
|---|---|---|
| L77/78/79 = ddt/div/laplacian | L77 `fvm::ddt(U)`、L78 `+fvm::div(phi,U)`、L79 `-fvm::laplacian(nu,U)` | ✅ |
| L84 = 动量预测 `-fvc::grad(p)` | L84 `solve(UEqn == -fvc::grad(p))` | ✅ |
| L88 PISO / L109–112 pEqn / L114 setReference / L126 修U | 逐条命中 | ✅ |
| L96/99/102「展示未执行」 | `ddtCorr`/`adjustPhi`/`constrainPressure` 确在真源码、M0 未实现 | ✅ 一致 |
| `U/p`=class、`phi`=struct | Fields.swift 核实 | ✅ |
| `cellFaceRefs{face,other,isOwner}` | Mesh.swift 核实 | ✅ |
| `pEqn` 对称（`laplacianSPD` upper==lower）| Fvm.swift 核实 | ✅ |
| 资源 10 条源码路径存在 | reading-plan 核实 | ✅ |

> **断言核实结论：④ 事实声称全部为真，0 处更正。**

### ④-7.3 《④ 全貌 · 大白话地图》（零代码总览）

| 块 | 它是什么（大白话）| 为什么要它 | 挂需求 |
|---|---|---|---|
| ④-1 求解游标 | 把"一口气算完的引擎"改成"**能逐帧暂停的播放器**" | 教学要算一步看一步 | FR4/FR5、T5 |
| ④-2 探针窗口 | 点一个格子，看它在矩阵里**那一行的数** | 看见"离散后的方程" | FR5/UC5、T6 |
| ④-3 调度台 | "当前状态信息板" + 播放/暂停/单步/重置**控制台** | "点一处、多处亮"的中枢 | FR5/UC4 |
| ④-4 资源+校对员 | 教学内容**数据格式** + 出版前**自动校对** | 保证"点的源码真存在" | FR4/UC6、T7 |
| ④-5 编辑闭环 | 改参数**三方同步** + **防呆钳制** | 新手**安全**改算例 | FR2/UC2、T2/T3/T4 |
| ④-6 侧栏布局 | 点节点后源码摆哪（**地图+源码同屏**）| 思维导图教法呈现 | UC6/NFR6（D1）|

> 一句话：**把引擎改成能暂停的播放器(①)，配能看矩阵的探针(②)，用调度台把它们和界面联动(③)，给教学内容定好数据格式与校对(④)、给用户安全的编辑(⑤)、和好的源码阅读布局(⑥)。**

### ④-7.4 冻结声明

场景走查（6 用例，5 通 + 1 非阻塞洞）+ 断言核实（全真、0 更正），**④ 详细设计冻结为 v1.0**。
遗留（均不阻塞、已登记）：**④遗留-1** UC3 时间轴回放需场历史/重跑（⑤/M1）；**D1** 侧栏暂定（待 M2 真机复核）。**下一阶段：⑤ 实现（M0 引擎先编译跑通）。**

---

> 状态：**④ 详细设计完成并冻结 v1.0**（④-1..④-7 全部落盘）。下一阶段 ⑤ 实现——建议另开会话，从 M0（FoamMini 编译跑通）起步，需 Mac+Xcode（引擎部分 Linux+Swift 亦可）。
