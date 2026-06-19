# iPad CFD 教学程序 · ④ 详细设计文档（detailed-design.md）

> 版本：**v0.1（进行中 · ④详细设计开工）**　|　日期：2026-06-13
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

> 状态：**④-1、④-2、④-3 详设完成并落盘**（待 ④-7 统一评审冻结）。下一步 **④-4**：资源层 §16 契约落成具体 `Codable` 类型 + 构建期 lint 工具（接 UC6 / T7）。
