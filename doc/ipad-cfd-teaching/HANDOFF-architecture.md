# iPad CFD 教学 App — 架构线交接摘要

> 用途：在**新对话**里粘贴此摘要即可接续「架构/需求/工程」线。理论教学（有限体积法原理）留在另一个对话，不在此处。
> 仓库内权威文档：`doc/ipad-cfd-teaching/architecture.md`；M0 代码：`ipad-cfd-teaching/FoamMini/`。
> 开发分支：`claude/ecstatic-heisenberg-oA9a8`（所有产物已提交并推送）。

---

## 1. 项目定位

做一个 **iPad 上的教学型 CFD App**，作为 **OpenFOAM 的「引桥课」**：在 iPad 上零环境成本走通一次「从输入到流场」的完整闭环，并能对照真实 OpenFOAM 源码，让初学者带着心智模型再去面对真正的 OpenFOAM。

**不替代 OpenFOAM**，只攻它最薄弱的「上手第一公里」。卖点差异化 = **源码入门**（看懂 OpenFOAM 的 C++）。

为什么做 iPad 版（已论证）：① 便携随时学/演示；② 桌面 OpenFOAM 要装 WSL/虚拟机/编译，门槛极高，App 一键安装；③ 初学者用不到复杂功能，简化降低心智负担；④ 触屏即时反馈、源码↔数学↔结果三联动是桌面端给不了的新教法；⑤ 可控防挫败（锁定稳定参数必出结果）。

---

## 2. 已拍板的关键决策

| 决策 | 选择 | 理由 |
|---|---|---|
| 求解引擎语言 | **Swift** | 好调试/优化、无桥接复杂度、上架成熟 |
| 源码展示 | 用户点 UI 上某函数时，**弹出真实 OpenFOAM C++ 源码**（含解释） | OpenFOAM 本就是 C++；展示真源码即「源码入门」。运行的是 Swift，展示的是 C++，二者靠「函数↔源码映射表」对齐、语义必须一致 |
| 首个案例 | **icoFoam + 顶盖驱动方腔 cavity（2D）** | OpenFOAM 入门第一课，源码仅约 100 行 |
| 案例组织 | **数据驱动、可插拔**（案例=字典数据+solver 标识，内核按字典驱动，不写死） | 加新案例=加数据，不动框架 |
| MVP 策略 | 先把**一个案例**做到极致即可发布，之后按「加数据」迭代新案例 | 精益 |
| 数学公式渲染 | **SwiftMath**（原生、离线、数学模式 LaTeX 子集） | PDE 标准记号够用；复杂排版以后局部上 KaTeX/WebView |
| 可视化 | **Metal / SwiftUI Canvas** | 矢量场/云图/流线/残差曲线 |

### iOS 平台事实（已澄清）
- iOS **可以**运行预编译 C++（Obj-C++ 或 Swift/C++ 互操作）。但**不能**在设备上编译用户现写的代码（App Store 2.5.2），也**不实际**整搬 OpenFOAM 本体（依赖 MPI/wmake/runTimeSelection 动态库）。
- 当前方案选择「引擎全 Swift + 展示真实 C++ 源码」，规避了桥接复杂度，仍达成源码入门。

---

## 3. 展示面板（9 个，按教学价值排序）

差异化王牌是前两个：
1. **数学↔代码桥**：点源码行 → 高亮对应 PDE 项（SwiftMath）。
2. **数据探针**：点某个 cell → 显示 U/p 值、离散模板、**矩阵系数**（把 `fvm` 隐式组装实体化，OpenFOAM 最难懂的部分）。
3. 源码面板（真实 C++，行高亮）
4. 速度矢量/流线　5. 压力云图　6. 残差/Courant 曲线
7. 字典编辑器（表单 ↔ dict 文本双向同步，既解决触屏体验又是教学法）
8. 网格/patch 视图　9. 时间轴控制（播放/暂停/单步 PISO）

联动核心：单一事实源 `SessionVM`（@Observable）驱动「点一处、多面板响应」。

---

## 4. 仓库现状（已提交到分支）

### 4.1 架构文档 `doc/ipad-cfd-teaching/architecture.md`
含：分层架构、Swift 类↔真实 OpenFOAM 类映射表、「方程即代码」对照、案例数据格式（用真实 cavity 取值）、函数↔源码映射机制（JSON schema）、9 面板+联动、SwiftMath 方案、M0–M4 里程碑、目录结构、风险表、**§11 GPL 许可合规分析**。

### 4.2 M0 引擎 `ipad-cfd-teaching/FoamMini/`（SwiftPM 包）
已搭好的无头 Swift 引擎，顶层 `IcoFoam.step()` 与真实 `icoFoam.C` 逐行对应：
- `Core/`：Vector2、DimensionSet、StructuredMesh（结构化方腔+owner/neighbour 寻址）、Fields（vol scalar/vector + 边界条件 + surface field）
- `Matrix/`：FvMatrix（LDU 形式，A()/H()）
- `Discretisation/`：Fvm（ddt/div/laplacian，隐式）、Fvc（grad/flux/interpolate，显式）
- `Solvers/`：LinearSolver（CG + 对称 Gauss-Seidel）、PisoControl、IcoFoam
- `Case/`：CavityCase 预设（nu=0.01、20×20、Re=10，对齐真实 tutorial）
- CLI（`foammini`）+ 验证测试（Tests/）

⚠️ **状态：代码已写但未编译验证**（开发环境无 Swift 工具链、swift.org 被网络拦截）。需在 macOS/Linux 上 `swift build && swift test && swift run foammini` 首次构建并按报错迭代。已知简化：正交网格、省略 `fvc::ddtCorr` 瞬态 Rhie-Chow、Jacobi 预处理（非 DIC）、量纲只展示不强制。

---

## 5. GPL 许可（重要，已决策但需上架前处理）

- OpenFOAM 是 **GPL v3**（传染型/copyleft）。三类风险：A 内嵌源码片段、B 移植架构（灰色）、C **GPL 与 App Store 条款冲突**（著名坑，VLC 曾被下架）。
- **当前决策**：原型期**先内嵌真实源码开发、不为合规分心**；改造列为**上架前待办**（优先方案：①源码改为外链 openfoam.org + ②源码面板用自写的等价讲解；并确认整个 App 分发许可）。详见架构文档 §11。

---

## 6. 建议的下一步（架构线）

1. 等本地 `swift build` 反馈 → 修 M0 首次编译/数值问题。
2. 整理「函数↔真实源码映射表」首批条目（icoFoam.C 的 PISO 各行）。
3. M1：Metal 可视化（矢量场/云图/残差曲线 + 时间轴）。
4. M2：源码面板 + SwiftMath + 数学↔代码桥。

> 注：用户正在另一对话里从零学习有限体积法原理（控制体/通量/组矩阵/迭代解/边界条件），打算自己动手写引擎；因此架构线的代码节奏要与其学习进度协调——不要直接代写，配合他的「自己写、我点评」模式。
