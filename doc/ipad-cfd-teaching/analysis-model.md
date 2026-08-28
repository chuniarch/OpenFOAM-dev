# ② 需求分析模型 — 用例 + 领域模型（v0.4 + D1–D4 裁决回填）

> **⚠️ 分支已重组（2026-08-28）**：本文提到的所有 `claude/*` 分支均已合并进 **`ipad-cfd-teaching/main`** 并删除。
> 一律使用该分支；新会话请**直接在其上工作并推送**，不要再新建 `claude/*` 分支
> （当初每个会话各建一个自动命名分支，正是产出散落的根源）。会话与产出的完整对照见 `CONTEXT-INDEX.md`。


> 阶段:**②需求分析/建模**。输入:`requirements.md` v1.3。产物供 ③架构设计 与 ⑥验收测试 派生。
> 修订史:v0.1（2026-06-12 首切:用例清单 + 2 条详例 + 领域模型草图）→ **v0.2（2026-06-12 精炼:8 条用例全部补齐异常流;领域模型补基数与组合/引用;新增源码关系图数据格式草案;新增用例→验收测试派生首批;新增开放决策点清单）** → **v0.3（2026-06-15 新增 D5：FR7 AI 后端选型 + 可替换接口 + 端侧 RAG-over-本地内容）** → **v0.4（2026-06-15 D5 追加后端必要性辨析：三路线 + 默认端侧/可选 BYO-key + Keychain + 皆无需后端）**。
> 纪律:每条用例可追溯到某条 FR/NFR;领域概念是 ③ 类设计的种子;② 只建模交互与概念,不画屏幕、不写类。
> 开发分支:`ipad-cfd-teaching/main`

---

## 1. 用例模型（系统"被怎么用" — 外部视角）

### 1.1 主角（Actor）

- **自学者**（唯一主要主角）:单人、触屏、想低成本看懂 OpenFOAM。
- **AI 服务**（支持主角/外部系统,FR7·M5）:接收"代码上下文 + 提问",返回解释。

### 1.2 用例清单（每条追溯 FR/NFR）

| 用例 | 主角目标 | 主要面板 | 追溯 | 批次 |
|---|---|---|---|---|
| UC0 首次引导 | onboarding 走一遍闭环 | 浮层 | NFR2 | MVP |
| UC1 运行案例 | 装载 cavity、跑出流场 | 顶栏 / ⑨ | FR1 | MVP |
| UC2 编辑输入 | 改边界/参数并重算 | ⑦ / ⑧ | FR2 | MVP |
| UC3 看结果 | 观察矢量/云图/曲线/演化 | ④⑤⑥ | FR3 | MVP |
| UC4 控制过程 | 单步/播放/暂停求解 | ⑨ | FR5 | MVP |
| UC5 探查单元 | 点 cell 看 U/p、矩阵系数 | ② | FR5 | MVP |
| UC6 读源码对照 | 思维导图导航 → 源码↔公式↔结果 | ③①④ | FR4 | MVP |
| UC7 问 AI | 就选中代码追问 | ⑩ | FR7 | M5 |

### 1.3 全部用例详述（主流程 + 异常流）

**UC0 首次引导**（追溯 NFR2）
- 前置:首次启动（或从设置重新进入引导）。
- 主流程:① 欢迎页一句话定位（"看懂 OpenFOAM 的第一课"）→ ② 气泡引导 3–5 步:这是 cavity → 点「运行」→ 看主涡形成 → 改盖速再跑一次 → 点一个源码节点看对照 → ③ 结束,进入自由探索。
- 异常流 E1（跳过）:任意步可跳过 → 直接自由探索;设置里可重看。
- 后置:用户已经历一次"改→算→看→懂"闭环（成就感先行,NFR2 的体验落点）。

**UC1 运行案例**（追溯 FR1）
- 前置:App 已启动;cavity 为当前案例（MVP 唯一）。
- 主流程:① 点「运行」→ ② 装载 CaseData（0/、constant/、system/ 的结构化等价物）→ ③ 初始化场（U=0, p=0, 边界就位）→ ④ 按 controlDict 推进时间步（deltaT=0.005 至 endTime=0.5）→ ⑤ 每步广播迭代状态,④⑤⑥ 面板刷新 → ⑥ 到达 endTime,提示完成。
- 异常流 E1（数值发散,防御性）:残差爆增/出现 NaN → 立即停止、保留最后有效状态、提示"参数组合发散,已停在 t=…"（预置参数下不应触发;用户改参后可能。追溯 NFR2/C4）。
- 异常流 E2(中途控制):暂停/单步/重置 → 转 UC4。
- 后置:结果序列可经 ⑨ 时间轴回放。

**UC2 编辑输入**（追溯 FR2;异常流追溯 NFR2/C4）
- 前置:已装载 cavity（运行前、暂停中或完成后均可）。
- 主流程:① 打开 ⑦ 字典编辑器 → ② 选 patch（如 movingWall,⑧ 网格视图同步高亮该 patch）→ ③ 用控件改值（滑杆/选择器/步进器,NFR3）→ ④ 表单与 dict 文本双向同步 → ⑤ 确认 → 重置并重算 → ⑥ 新流场出现在 ④⑤。
- 异常流 E1（参数越界）:输入超出安全范围（如 deltaT 过大→Courant≫1）→ **钳制到安全范围并解释原因**（"deltaT>0.01 时 Courant>2,会发散;已限制为 0.01"）→ 回主流程 ⑤。【NFR2/C4 的落地点】
- 异常流 E2（文本非法）:文本侧手敲出非法字典 → 校验失败、行级标错、不触发重算。
- 异常流 E3（求解进行中编辑）:正在运行时进入编辑 → 自动暂停;确认修改 = 丢弃当前进度、重置重算（MVP 策略,见 §6 决策点 D3）。
- 后置:新输入成为当前 CaseData;dict 文本与表单语义一致。

**UC3 看结果**（追溯 FR3）
- 前置:至少跑过一步（有任一时刻的场数据）。
- 主流程:① 在 ④⑤ 标签间切换（矢量/流线 ↔ 压力云图）→ ② ⑥ 残差曲线随迭代累积 → ③ 捏合缩放/拖动查看局部 → ④ 经 ⑨ 拖动时间轴回放流场演化。
- 异常流 E1（空态）:从未运行 → 结果区显示空态引导:"点击运行,看顶盖如何搅出一个涡"。
- 后置:无状态变更（纯读）。

**UC4 控制过程**（追溯 FR5）
- 前置:案例已在运行或已暂停。
- 主流程:① 暂停 → ② 单步（推进一个时间步;PISO 子步以指示灯/小圆点呈现,见 §6 决策点 D2）→ ③ 观察各面板在两步间的差异 → ④ 继续播放或重置。
- 异常流 E1（重置确认）:重置丢弃全部结果 → 二次确认。
- 后置:迭代状态（时间步/PISO 子步/残差）为联动层单一事实源,所有面板一致。

**UC5 探查单元**（追溯 FR5）
- 前置:存在当前时刻场数据（暂停中或完成后体验最佳）。
- 主流程:① 在 ④/⑤ 上点某 cell → ② 浮卡显示 cell 编号、U、p → ③ 展开离散明细:该 cell 行的矩阵系数（aP、各 aN）与邻居贡献,⑧/④ 同步高亮邻居 cell（离散模板可视化）→ ④ 若处于单步模式,逐步看数值如何变化。
- 异常流 E1（点到 patch 面）:显示该 patch 的边界条件信息（类型/值）而非内部系数。
- 异常流 E2（点空白）:关闭浮卡。
- 后置:无状态变更（纯读）。

**UC6 读源码对照**（追溯 FR4;思维导图导航）
- 前置:任意时刻（教学内容离线内嵌,NFR5）。
- 主流程:① 打开 ③ 源码视图,呈现**思维导图态**:节点 = 源码模块（UEqn 组装、PISO 循环、各 fvm/fvc 算子…）,边 = 有类型关系（组装/数据流/数学等价…,见 §3）→ ② 缩放浏览整体结构（overview）→ ③ 点某节点（如 `fvm::laplacian`）→ ④ 展开该模块**完整真实源码**（detail,浮层或侧栏,见 §6 决策点 D1）+ ① 数学面板高亮 ν∇²U + ④ 结果面板闪烁受影响区域 → ⑤ 沿边跳转相邻节点,在整体↔细节间往返。
- 异常流 E1（无映射内容）:节点未覆盖 → 占位"本教程未覆盖此模块"。
- 异常流 E2（运行联动）:求解正在运行时,当前执行节点高亮脉冲(执行游标)。
- 后置:无状态变更;当前选中节点进入联动层单一事实源。

**UC7 问 AI**（追溯 FR7,M5;异常流追溯 NFR5/C3）
- 前置:设备联网;通常自 UC6 选中某节点进入。
- 主流程:① 长按节点/源码段 →「问 AI」→ ② 对话框预载**上下文包**（symbol + 源码段 + 公式 + 预写解释,将来可含当前求解状态）→ ③ 用户输入问题（免手敲代码）→ ④ AI 流式回答 → ⑤ 可连续追问,上下文保持。
- 异常流 E1（断网）:入口置灰 + 提示"AI 答疑需联网;全部教学内容仍离线可用"（NFR5 分层可用性）。
- 异常流 E2（服务失败/超时）:可重试,不影响其他面板。
- 异常流 E3（隐私）:首次使用披露"提问与所引代码将发送至 AI 服务"（C3/隐私次生需求）。
- 后置:对话历史本会话内保留（是否持久化 → M5 细化）。

> 方法论注记:**异常流不是边角料——它是 NFR 与约束在用例里现身的位置**(UC2-E1 = NFR2/C4;UC7-E1 = NFR5;UC7-E3 = C3 次生)。

---

## 2. 领域模型（系统"内部用哪些概念" — 内部视角）

### 2.1 领域概念（名词表）

| 概念 | 含义 | 备注 |
|---|---|---|
| Case | 算例 = 输入数据 + 求解器标识 | M0 `CavityCase` → 数据驱动 `CaseData` |
| Mesh / Cell / Face / Patch | 网格拓扑与几何 | 2D 结构化方腔(20×20) |
| Field（Vol/Surface） | 体场/面场（U、p、phi） | internal + 每 patch 边界值 |
| BoundaryCondition | patch 上的边界条件 | 4 种（fixedValue/noSlip/zeroGradient/empty） |
| ControlSettings | schemes / solution / PISO / 时间控制 | 来自 `system/` 三字典 |
| Operator（Fvm/Fvc） | 离散算子（隐式/显式） | **Fvm→Matrix,Fvc→Field:类型即教学** |
| Matrix（FvMatrix） | 稀疏方程对象（A/H/==/setReference） | |
| LinearSolver | 解线性系统（CG/Gauss-Seidel） | 产出 Residual |
| SolveStep / Iteration | 时间步、PISO 子步、残差序列 | 联动层"单一事实源"的迭代状态 |
| Residual | 每次线性求解的收敛度量 | ⑥ 曲线的数据源 |
| **SourceModule** | 一段真实 OpenFOAM 源码单元（函数/类/代码块） | **思维导图的节点** |
| **Relationship** | SourceModule 间的**有类型有向关系** | **思维导图的边（v0.1 新增概念）** |
| MappingEntry | 绑定 SourceModule ↔ 公式(LaTeX) ↔ 解释(MD) | 资源层 JSON |
| ContextPack（M5） | 喂给 AI 的上下文包 = MappingEntry 内容 +（可选）求解状态 | FR7 |
| AIConversation（M5） | 围绕某 ContextPack 的多轮问答 | FR7 |

### 2.2 概念关系图（含基数;`1`=恰一,`*`=多,`0..1`=可选）

```
Case 1──1 ControlSettings
  │1
  ├──1 Mesh ◆──* Cell      （◆=组合:Cell/Face/Patch 随 Mesh 生灭）
  │     ◆──* Face
  │     ◆──* Patch
  └──* Field(U,p,phi) ──defined-on──1 Mesh
            │1 ◆──per Patch──1 BoundaryCondition

Solver(IcoFoam) ──uses──* Operator(Fvm/Fvc)
   │                      Fvm.* ──assembles──▶ 1 Matrix
   │                      Fvc.* ──returns────▶ 1 Field
   │drives                Matrix ──solved-by──1 LinearSolver ──reports──* Residual
   └──* SolveStep ◆──* PISO子步（cavity: nCorrectors=2）

── 教学/源码侧 ──
SourceModule 1──0..1 MappingEntry ◆── Formula(LaTeX) + Explanation(MD)
SourceModule 1──*(出边) Relationship *(入边)──1 SourceModule   ←思维导图
MappingEntry ──packaged-as──▶ ContextPack(M5) ──grounds──▶ AIConversation(M5)
```

### 2.3 组合 vs 引用（生命周期声明）

- **组合（◆,部分随整体生灭）**:Mesh◆{Cell,Face,Patch};Field◆{internal 值,各 patch 边界值};SolveStep◆{PISO 子步};MappingEntry◆{公式,解释}。
- **引用（独立生命周期）**:Field→Mesh(场建在网格上,不拥有网格);Relationship→SourceModule(边引用节点);ContextPack→MappingEntry。
- 教学意义:组合/引用之分将来直接对应 Swift 值类型/引用语义的选型讨论(④ 阶段)。

### 2.4 思维导图概念的归属

- 用户看到的"源码思维导图" = **{SourceModule 节点} + {Relationship 边}** 之上的用户视图;点节点 → 取其 MappingEntry(源码段+公式+解释)。
- **对数据模型的实质影响**:原"函数↔源码映射表"只有节点(symbol→源码段);思维导图要求**新增边数据**——见 §3 格式草案。③ 资源层契约由 `mappings` 扩为 `mappings + graph(nodes,edges)`。

---

## 3. 源码关系图数据格式（草案 → ③ 资源层契约的种子）

### 3.1 JSON 形态

```json
{
  "nodes": [
    {
      "id": "icoFoam.UEqn",
      "kind": "equationAssembly",
      "title": "UEqn — 动量方程组装",
      "sourceFile": "applications/legacy/incompressible/icoFoam/icoFoam.C",
      "lineStart": 75, "lineEnd": 80,
      "mappingId": "icoFoam.UEqn"
    },
    { "id": "fvm.laplacian", "kind": "operator", "title": "fvm::laplacian — 隐式扩散", "...": "..." }
  ],
  "edges": [
    { "from": "icoFoam.UEqn", "to": "fvm.laplacian",
      "type": "assembles", "arrow": "single", "label": "隐式 · 进左端" },
    { "from": "icoFoam.pEqn", "to": "concept.continuity",
      "type": "derivedFrom", "arrow": "single", "label": "由 ∇·U=0 导出" }
  ]
}
```

### 3.2 字段与枚举

| 字段 | 取值/说明 |
|---|---|
| node.kind | `solver` \| `equationAssembly` \| `operator` \| `field` \| `control` \| `concept`(无源码的纯概念锚点,如"连续性方程") |
| edge.type | `assembles`(组装进方程) \| `calls`(调用) \| `dataFlow`(数据流,如 phi→div) \| `contributesLHS`(隐式进左端,fvm) \| `contributesRHS`(显式进右端,fvc) \| `derivedFrom`(数学推导) \| `mathEquiv`(数学等价对照) \| `inherits`(继承,留给 fvPatchField 树) |
| edge.arrow | `single`(有向) \| `double`(双向,如 mathEquiv) \| `none`(并列关联) |
| edge.label | 可选,箭头上的标注文字 |

注意 `contributesLHS/RHS`:**fvm/fvc 之分(OpenFOAM 最核心抽象)直接成为边的类型**——思维导图天然把这张王牌可视化了。

### 3.3 校验规则（资源构建期 lint）

1. `edge.from/to` 必须存在于 `nodes`;
2. `edge.type/arrow` 必须在枚举内;
3. 非 `concept` 节点的 `sourceFile:lineStart-lineEnd` 必须真实存在(对照仓库核验,延续 architecture.md §2.1 的评审纪律);
4. **无孤儿节点**:每个节点至少一条边或被标记为根——与第一课"产物无孤儿"同构,纪律复用。

### 3.4 icoFoam 首批边清单（示例切片,完整表属 ③ 资源制作）

| from | to | type | label |
|---|---|---|---|
| icoFoam | icoFoam.UEqn | assembles | 动量预测 |
| icoFoam.UEqn | fvm.ddt | contributesLHS | ∂U/∂t |
| icoFoam.UEqn | fvm.div | contributesLHS | ∇·(UU),用 phi |
| icoFoam.UEqn | fvm.laplacian | contributesLHS | ν∇²U |
| fvc.grad(p) | icoFoam.UEqn | contributesRHS | −∇p |
| field.phi | fvm.div | dataFlow | 对流通量 |
| icoFoam | icoFoam.piso | calls | 压力修正循环 |
| icoFoam.piso | icoFoam.pEqn | assembles | 压力方程 |
| icoFoam.pEqn | concept.continuity | derivedFrom | 由 ∇·U=0 导出 |
| icoFoam.pEqn | field.phi | dataFlow | pEqn.flux() 修正通量 |

---

## 4. 用例 → 界面对账

- **UC6 重塑 ③ 源码面板**:由"平铺滚动代码"改为"节点图(overview) + 详情(detail)"——既是 FR4 呈现升级,也是 NFR6"避开经典 CAE 观感"的着力点(走查推翻原设计的实例)。
- 其余用例与 9+1 面板草案一一对应(§1.2 第三列)。
- 走查纪律:每条用例在 `ui-wireframe-v0` 信息架构上走一遍;走不顺 → 改架构或改图。

## 5. 用例 → 验收测试派生（首批,供 ⑥ 阶段展开）

| 测试 | 源 | 判据 |
|---|---|---|
| T1 预置运行 | UC1 主流程 | 预置参数跑至 endTime=0.5,无 NaN/崩溃;涡心位置与参考解一致(FR1 验收) |
| T2 改参重算 | UC2 主流程 | 盖速改 2 m/s → dict 文本同步更新 → 重算后流场变化方向正确 |
| T3 越界钳制 | UC2-E1 | deltaT 输入 1.0 → 被钳制至安全上限并给出原因提示,不发散 |
| T4 非法字典 | UC2-E2 | 文本侧注入非法 token → 行级报错,不触发重算 |
| T5 单步一致性 | UC4 | 暂停-单步 n 次的场 = 连续跑 n 步的场(逐位一致) |
| T6 探针正确性 | UC5 | 选中 cell 的 aP/aN 与引擎矩阵该行一致 |
| T7 映射真实性 | UC6 | 每个非 concept 节点的源码行区间在真实仓库存在且内容一致 |
| T8 断网降级 | UC7-E1 | 飞行模式:AI 入口置灰有提示,其余全部可用(NFR5) |

## 6. 开放决策点（带去 ③ 的待决清单）

> **状态(2026-06-13)：D1–D4 已在 ③ 由需求方裁决，见 `architecture.md §14`。** D2=时间步+PISO 子步两档（定调 §15 引擎事件接口粒度）、D3=重置重算、D4=手工定坐标，均稳定；D1=固定侧栏（暂定、可回退浮层）。

| # | 决策点 | 候选 | 归属 | 裁决（→ architecture.md §14）|
|---|---|---|---|---|
| D1 | UC6 的 detail 呈现 | 浮层 vs 固定侧栏(一区或两区) | ③ UX 架构 | **固定侧栏**（暂定可回退）|
| D2 | 单步粒度 | 仅时间步 vs 时间步+PISO 子步两档 | ③(影响引擎事件接口) | **时间步+PISO 子步两档** |
| D3 | 编辑后重算策略 | 重置重算(MVP) vs 从当前时刻续算 | ③/④ | **重置重算(MVP)** |
| D4 | 图布局算法 | 手工定坐标(MVP,节点少) vs 自动布局 | ③ 资源层/渲染 | **手工定坐标(MVP)** |
| D5 | FR7 AI 后端选型 | ①云端前沿模型 ②Apple 自带模型(Foundation Models) ③Core AI 端侧自带小模型 + RAG ④混合 | ③ 立接口 + M5 选型 | 见下方 D5 展开（③ 只立可替换接口，选型推迟到 M5）|

**D5 展开**(2026-06-15 新增,缘起需求方提供 Apple Core AI 线索):

- **可替换接口(③ 现在就要立)**:把 AI 提供方抽象成可换后端的接口——输入 `ContextPack`(symbol + 源码段 + 公式 + 预写解释 +(可选)求解状态),输出(流式)答案。四个后端实现同一接口,选型推迟到 M5 按当时模型质量定,**③ 不得堵死**。
- **四后端权衡**:① 云端前沿模型(最强;但在线/计费/隐私 + GPL 外发);② Apple 自带模型(免管模型,离线免费私密;但通用、设备受限);③ **Core AI 端侧自带小模型 + RAG**(离线/免费/私密 + 可自选模型;代价:选型/App 体积/小模型质量);④ 混合(端侧优先、难题回退云端)。
- **关键 · 与静态层协同**:端侧小模型的"教错"风险,用 **RAG 锚定在我们已有的 `MappingEntry`(已核实的源码 + 公式 + 解释,见 §2.1/§3)** 上化解——模型只就我们给的正确内容复述/答疑,不裸用其 CFD 记忆。这把 `requirements.md` §7「答案语义一致性」风险变成可控工程,也兑现 §10「静态层是 AI 的弹药库」。
- **对离线的影响**:③/④ 任一端侧方案都可能让 FR7 从「在线可选」升级为「离线可用」,松动 `requirements.md` §7 开放问题①(届时回填 NFR5)。

**D5 追加(2026-06-15 · 后端必要性辨析)**:

- **结论:本 app 的 FR7 三条路线都不需要自建后端。** 后端的本质 = 保管密钥 + 按"终端用户"限流/防滥用 + 跨用户共享/聚合 + 重型/中心化计算(大模型/多模型编排/长任务) + 审计脱敏。这些对本 app 几乎都不成立:单用户(无跨用户聚合)、单模型秒级问答(无编排/长任务)、低 PII(审计脱敏弱);"同一用户多设备同步"用 iCloud/CloudKit + SwiftData 即可,**不需后端**。
- **限流辨析**:供应商只能按 key/账户限速 + 设账户消费上限,**做不到按终端用户限**;"每人每天 N 次/异常掐断某用户"才需自建后端——而 **BYO-key 把此问题转移给用户后,它消失**(烧用户自己的账户、限用户自己的 key)。
- **三路线(皆无需后端)**:
  1. **默认 · 端侧(Core AI / Foundation Models + RAG)**:零门槛、离线、免费、无 key;最贴 NFR1/NFR5/防挫败;代价 = 小模型质量(RAG 锚定我们已核实内容缓解)。
  2. **可选(高级用户) · BYO-key 直连云端**:用户自带 key、自付费、前沿质量、零服务器;**密钥必须存 iOS Keychain(UI 打码 ≠ 安全,勿入 UserDefaults/明文)**;有上手门槛、与 NFR1 冲突,故仅作可选档、非默认。
  3. **不推荐 · 自有 key + 薄代理后端**:你付费 + 永久运维 + 破坏纯离线;仅当确需后端独有能力时才值,本 app 基本不需要。
- **实现**:D5 的可替换接口让"默认端侧 + 可选 BYO-key 云端"共存,二者皆无需后端;**仅当用开发者自己的 key 走云端时,才需要一台薄代理后端**(只为密钥保管 + 成本控制)。

---

> 状态:②收口候选版。再走查一轮无新增缺口后冻结,进入 ③ 需求→架构。
