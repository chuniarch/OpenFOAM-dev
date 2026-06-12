# ② 需求分析模型 — 用例 + 领域模型（v0.1 草案）

> 阶段：**②需求分析/建模**。输入：`requirements.md` v1.3。产物供 ③架构设计 与 ⑥验收测试 派生。
> 状态：**首切草案**，待用例走查精炼。纪律：每条用例可追溯到某条 FR；领域概念是 ③ 类设计的种子。
> 开发分支：`claude/modest-clarke-a70tkz`

---

## 1. 用例模型（系统"被怎么用" — 外部视角）

### 1.1 主角（Actor）

- **自学者**（唯一主要主角）：单人、触屏、想低成本看懂 OpenFOAM。
- **AI 服务**（支持主角 / 外部系统，FR7 · M5）：接收"代码上下文 + 提问"，返回解释。

### 1.2 用例清单（每条追溯 FR）

| 用例 | 主角目标 | 主要面板 | 追溯 | 批次 |
|---|---|---|---|---|
| UC1 运行案例 | 装载 cavity、跑出流场 | 顶栏 / ⑨ | FR1 | MVP |
| UC2 编辑输入 | 改边界/参数并重算 | ⑦ / ⑧ | FR2 | MVP |
| UC3 看结果 | 观察矢量/云图/曲线/演化 | ④⑤⑥ | FR3 | MVP |
| UC4 控制过程 | 单步/播放/暂停求解 | ⑨ | FR5 | MVP |
| UC5 探查单元 | 点 cell 看 U/p、矩阵系数 | ② | FR5 | MVP |
| UC6 读源码对照 | 浏览源码 ↔ 公式 ↔ 结果（思维导图导航） | ③①④ | FR4 | MVP |
| UC7 问 AI | 就选中代码追问 | ⑩ | FR7 | M5 |
| UC0 首次引导 | onboarding 走一遍闭环 | 浮层 | NFR2 | MVP |

### 1.3 详细用例（含异常流）

**UC2 编辑边界/参数**（追溯 FR2；异常流追溯 NFR2 / C4）
- 前置：已装载 cavity。
- 主流程：① 打开 ⑦ 字典编辑器 → ② 选 patch（如 movingWall）→ ③ 改值（滑杆/选择器）→ ④ 表单与 dict 文本双向同步 → ⑤ 触发重算 → ⑥ ④⑤ 面板刷新新流场。
- 异常流 E1（参数越界）：输入超出安全范围（如 deltaT 过大致 Courant ≫ 1）→ 系统**钳制到安全范围并提示原因**，不接受发散参数 → 回主流程 ⑤。【NFR2 防挫败 / C4 锁参数的落地点】
- 异常流 E2（dict 文本非法）：文本侧手敲出非法字典 → 校验失败、定位错误、不重算。

**UC6 读源码并对照**（追溯 FR4；用思维导图导航）
- 前置：案例运行中或已出结果。
- 主流程：① 打开 ③ 源码视图（**思维导图态**：模块节点 + 关系边）→ ② 看见 icoFoam 顶层结构（UEqn 组装、PISO 循环、各 `fvm`/`fvc` 算子及其关系）→ ③ 点某节点（如 `fvm::laplacian`）→ ④ 展开该模块完整真实源码 + ① 数学面板高亮 ν∇²U + ④ 结果面板闪烁受影响区域 → ⑤ 在"整体 ↔ 细节"间缩放往返。
- 异常流：节点暂无映射内容 → 显示"该模块本教程未覆盖"占位。
- 备注：本用例把"一处操作、多处响应"（联动层）演示得最充分。

---

## 2. 领域模型（系统"内部用哪些概念" — 内部视角，首切）

### 2.1 领域概念（名词表）

| 概念 | 含义 | 备注 |
|---|---|---|
| Case | 算例 = 输入数据 + 求解器标识 | M0 `CavityCase` → 数据驱动 `CaseData` |
| Mesh / Cell / Face / Patch | 网格拓扑与几何 | 2D 结构化方腔 |
| Field（Vol / Surface） | 体场 / 面场（U、p、phi） | 含 internal + boundary |
| BoundaryCondition | patch 上的边界条件 | 4 种（枚举） |
| ControlSettings | schemes / solution / PISO / 控制字典 | 来自 `system/` |
| Operator（Fvm / Fvc） | 离散算子（隐式 / 显式） | 返回 Matrix / Field |
| Matrix（FvMatrix） | 稀疏方程对象（A / H / ==） | |
| LinearSolver | 解线性系统（CG / Gauss-Seidel） | |
| SolveStep / Iteration | 时间步、PISO 子步、残差 | 联动层"单一事实源"的迭代状态 |
| **SourceModule** | 一段真实 OpenFOAM 源码单元（函数 / 类） | **思维导图的节点** |
| **Relationship** | 源码模块间的**有类型关系**（调用 / 数据流 / 隐式显式 / 继承） | **思维导图的边 —— 本轮新增** |
| MappingEntry | 把 概念/算子 ↔ SourceModule + 公式 + 解释 绑定 | 资源层 JSON |
| AIConversation（M5） | 围绕某 SourceModule 上下文的问答 | FR7 |

### 2.2 关系图（概念草图）

```
        Case ──has──> ControlSettings
         │ has
         ├──> Mesh ──contains──> Cell / Face / Patch
         └──> Field(U,p,phi) ──defined-on──> Mesh
                  │ has (per Patch)
                  └──> BoundaryCondition

  Solver(IcoFoam) ──uses──> Operator(Fvm/Fvc) ──assembles──> Matrix
        │                                                      │ solved-by
        │ drives                                               v
        └──> SolveStep/Iteration ──reports──> Residual    LinearSolver

  ── 教学 / 源码侧 ──
  MappingEntry ──maps──> SourceModule <──Relationship──> SourceModule
        │ binds                  (节点)      (typed 边 = 思维导图)
        ├──> Formula(LaTeX)
        └──> Explanation(MD) ──referenced-by──> AIConversation(M5)
```

### 2.3 思维导图概念的归属（你的想法落在哪）

- 用户看到的"源码思维导图" = 在 **{SourceModule 节点} + {Relationship 边}** 之上的**用户视图**；点节点 → 取其 `MappingEntry`（源码段 + 公式 + 解释）。
- **本轮新增的领域要求**：原"函数↔源码映射表"只有"节点"（symbol → 源码段），思维导图要求再补一层 **Relationship（边）数据**——关系类型 + 可选箭头标注。**这是你那个想法对数据模型的实质影响**：③ 资源层数据格式须新增 `relationships` 表，而不止 `mappings`。

---

## 3. 用例 → 界面 对账

- **UC6 重塑了 ③ 源码面板**：从"平铺滚动代码"变为"节点图 + 详情"（overview + detail）。这正是 NFR6"避开经典 CAE 观感"的着力点之一。
- 其余用例与 9+1 草案面板一一对应（见 §1.2）。
- **走查纪律**：每条用例在 `ui-wireframe-v0` 的信息架构上走一遍；走不顺 → 改架构或改图（UC6 已促使 ③ 改形，即是一例）。

---

## 4. 下一步

- 精炼领域模型关系基数（一对多 / 组合等），补全各用例异常流。
- ③ 资源层数据格式新增 `relationships`（支撑思维导图）。
- 由用例派生 ⑥ 验收测试用例（每条主流程 + 关键异常流一条测试）。
