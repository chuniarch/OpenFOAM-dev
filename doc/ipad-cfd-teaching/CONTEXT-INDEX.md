# 会话上下文造册索引

> 本文件登记 iPad CFD 教学程序项目 / OpenFOAM 学习线的**全部 Claude 会话**、它们各自的产出分支、以及产出落在仓库何处。
> 建立于 2026-08-28，起因见下方「为什么要有这份索引」。
> 同一份文件同时存在于 `ipad-cfd-teaching/main` 与 `openfoam-learning/main` 两个分支。

## 为什么要有这份索引

GitHub 用户名从 `developer-zht` 改为 `chuniarch` 后，claude.ai/code 侧边栏把同一个仓库的会话拆成了两组：改名前创建的会话，其记录里存的源仓库 URL 快照仍是 `https://github.com/developer-zht/OpenFOAM-dev`，与改名后的 `chuniarch/OpenFOAM-dev` 是两个不同字符串，因而分属两组、不会自动合并（GitHub 侧的路径重定向让旧链接照样能打开，但那是 github.com 在转发，与会话分组无关）。

借这次整理，把 5 个自动命名的 `claude/*` 分支按**两条工作线**收敛为两个语义分支，并把会话与产出的对应关系固化在这里——这样上下文跟着仓库走，不再依赖侧边栏分组。

## 两个分支

| 分支 | 装什么 | 由哪些分支合并而来 |
|---|---|---|
| `ipad-cfd-teaching/main` | 工程线：需求 → 分析 → 架构 → 详设 → 实现交接，外加 FoamMini Swift 引擎 | `claude/blissful-noether-gdnfwa` ⊃ `claude/festive-mccarthy-44aptr`，合并 `claude/wonderful-ride-ds1ee5` ⊃ `claude/modest-clarke-a70tkz` |
| `openfoam-learning/main` | 学习线：CFD 学习阶梯、扩散专题、OpenFOAM 源码解读 | `claude/ecstatic-heisenberg-oA9a8` |

命名用项目名当命名空间（而非 `docs/`），因为分支里既有文档也有 `ipad-cfd-teaching/FoamMini/` 的 Swift 源码。注意 git 约束：既然用了 `ipad-cfd-teaching/main`，就不能再有一个叫 `ipad-cfd-teaching` 的裸分支（ref 路径冲突）。

### 原分支拓扑

```
b4356dfa  架构初稿
   │
9d1cd89d  GPL 合规分析
   │
a50f08a8  FoamMini M0 引擎（Swift icoFoam/PISO cavity）
   │
ea8dc1d9  交接文档收口
   ├──────────────► claude/ecstatic-heisenberg-oA9a8      →  openfoam-learning/main
   │                （学习阶梯 + 扩散笔记 + Convection2D）
   │
   └── … ── b69963a5  stage-3 交接文档  ── claude/modest-clarke-a70tkz
                 │                          （需求 v1.0→v1.4、分析 v0.2→v0.4）
                 │
                 ├──► claude/wonderful-ride-ds1ee5   ③ 架构线 A（12 份独立 ADR，06-23 冻结）
                 │                                    ⊃ modest-clarke
                 └──► claude/festive-mccarthy-44aptr  ③ 架构线 B（ADR 内联 §13，06-13 冻结）
                        └──► claude/blissful-noether-gdnfwa   ④ 详设 → ⑤ 实现交接
                                                              ⊃ festive-mccarthy

            两条 ③ 线于 2026-08-28 合并为 ipad-cfd-teaching/main
```

## 会话总表

链接格式为 `https://claude.ai/code/<session-id>`。「分支推送过？」一列为否，表示该会话当年的产出**从未推到远程**，仓库里没有它的文件——上下文只存在于会话记录中。

### 工程线（Phase 系列）→ `ipad-cfd-teaching/main`

| 会话 | Session ID | 当年的 outcome 分支 | 分支推送过？ | 最后停在哪 |
|---|---|---|---|---|
| Phase 1 & 2 — 需求工程 & 需求分析 | `session_01REXFAgf6o5ngWdocqYAH3D` | `claude/modest-clarke-a70tkz` | ✅ | 复核全部文档找 ADR；确认 ③ 尚无正式 ADR，给出 8 条候选决策（FR7 AI 后端优先） |
| Phase 3 — 架构设计 | `session_011ChCfMnEd8TpgR5CBVKD72` | `claude/awesome-einstein-4ebjgx` | ❌ → 已回填 `context/phase3-architecture.md` | 详设交接已备：architecture.md §1–17 映射、教学速查卡、FoamMini M0 定位、④ 工作计划 7 项 |
| Phase 3+ — Architecture Design Recording | `session_01HBuV1PbrZ636drTHLZVvaH` | `claude/wonderful-ride-ds1ee5` | ✅ | ③ 冻结 v0.3（12 份 ADR、8 用例走查），等选下一步 |
| Phase 4 — 详细设计 | `session_01PPftrcwP89b5EFVwnCpCWi` | `claude/festive-mccarthy-44aptr` | ✅ | ④ 冻结 v1.0，问要不要先列 M0 起步命令清单 |
| Phase 6 — implementation kickoff | `session_012Lx1PNwGP88e4HqZxHwwTm` | `claude/blissful-noether-gdnfwa` | ✅ | 问先跑通验证，还是先补 DimensionSet / Mesh 单测 |
| Doc — 跨项目文档使用 | `session_01UswR7WBNeQx7KqgqYez294` | `claude/vibrant-meitner-r7lsht` | ❌ → 回填中 | 从 modest-clarke 导出 4 份交接文档，给了 3 种跨仓库用法 |

### 学习线（OpenFOAM 系列）→ `openfoam-learning/main`

| 会话 | Session ID | 当年的 outcome 分支 | 分支推送过？ | 最后停在哪 |
|---|---|---|---|---|
| OpenFOAM — 创作者背景 | `session_01Q9JqJAFZy8pD8yhkqSbUxE` | `claude/pensive-planck-zxB9l` | ❌ → 已回填 `learning/context/openfoam-origins.md` | 已答：OpenFOAM 创始人是机械工程 + CFD 背景，非纯 CS |
| OpenFOAM — 最小案例教学 | `session_01GN44s8UkLopir3Bhbt3P2q` | `claude/ecstatic-heisenberg-oA9a8` | ✅ | 学习阶梯（砖块 1–11）成文，开场提示词已生成 |
| OpenFOAM — 架构解读 | `session_01PPW3yiCDdM1dyZ6KAMRxd2` | `claude/lucid-feynman-fx4lb8` | ❌ → 已回填 `learning/context/openfoam-architecture-tour.md` | 第 1 课讲完，等选方向：澄清概念 / 进第 2 课 / 要执行流程图 |
| OpenFOAM — 学习 icoFoam cavity 案例 | `session_016L4vj8vVVvVokMSbxz95VN` | `claude/lucid-dirac-hic034` | ❌ → 已回填 `learning/context/icofoam-cavity-walkthrough.md` | 讲完 U 和 p，问要不要继续讲 ν（粘度）和 φ（面通量） |

### 其他相关会话

| 会话 | Session ID | 说明 |
|---|---|---|
| Phase 0 — 架构解读 | `session_014cezmDEefazTL8T43SgC6T` | 已归档。对流-扩散分析、离散误差 vs 迭代误差、二阶收敛验证、三条可靠性判据。分支 `claude/wizardly-mayer-2AkHA` 未推送 |
| 有限体积法 CFD 求解器学习 | `session_015Jk9J73ix6BRyxs31T8ExB` | **改名后新组**里的会话，现为**学习线的活动会话**。已通读 `openfoam-learning/main` 全部上下文并接手：代跑验收了砖块 10 的 `Convection2D.swift`，补上「数值扩散」一课，正进砖块 11A（`a_P` / `H(U)`）。产出一律直接写 `openfoam-learning/main`；自动分支 `claude/fvm-cfd-solver-learning-v9280l` 作废、从未推送 |

## 归档分支

原 `claude/*` 分支的完整历史已镜像到 `archive/*` 分支，可随时取回：

| 归档分支 | 原分支 | 对应会话 |
|---|---|---|
| `archive/phase1-2-requirements` | `claude/modest-clarke-a70tkz` | Phase 1 & 2 — 需求工程 & 需求分析 |
| `archive/phase3plus-adr-line` | `claude/wonderful-ride-ds1ee5` | Phase 3+ — Architecture Design Recording |
| `archive/phase4-detailed-design` | `claude/festive-mccarthy-44aptr` | Phase 4 — 详细设计 |
| `archive/phase6-implementation` | `claude/blissful-noether-gdnfwa` | Phase 6 — implementation kickoff |
| `archive/openfoam-minimal-case` | `claude/ecstatic-heisenberg-oA9a8` | OpenFOAM — 最小案例教学 |

取回：`git checkout -b tmp origin/archive/phase6-implementation`

原本计划用 tag 归档（tag 不可变、更适合归档语义），但云端会话的 git 凭据只授权推送分支引用，
推 tag 与删除远程引用均返回 403。如需改成 tag，在本地克隆执行：

```
git fetch origin 'refs/heads/archive/*:refs/heads/archive/*'
for b in phase1-2-requirements phase3plus-adr-line phase4-detailed-design phase6-implementation openfoam-minimal-case; do
  git tag "archive/$b" "origin/archive/$b" && git push origin "refs/tags/archive/$b" && git push origin --delete "archive/$b"
done
```

### 待清理：原 `claude/*` 分支

同样因为凭据不允许删除远程引用，以下 5 个自动命名的分支仍留在远程，内容已全部收进
`archive/*` 与两个语义分支，可安全删除：

```
git push origin --delete \
  claude/modest-clarke-a70tkz claude/wonderful-ride-ds1ee5 claude/festive-mccarthy-44aptr \
  claude/blissful-noether-gdnfwa claude/ecstatic-heisenberg-oA9a8 \
  tmp-permission-probe
```

（或在 GitHub 网页 Branches 页面逐个删除。）

## 已裁决

**两份 v0.3 架构文档已收敛（2026-08-28）。** ③ 阶段曾被两个会话各自冻结，产生两份都叫 v0.3 的
`architecture.md`。按「保留最新修改」裁决：

- **正文 §0–§13 取 2026-06-23 版**（`894b0436`，比 2026-06-13 版 `a627bc71` 晚 10 天）。该版把 ADR
  拆成 `adr/` 下 12 份独立文件、§0 更详细、新增 §6.1 协作视图，§13 评审记录走查 8 个用例 + 3 个质量场景
  （06-13 版 §17 只走查 5 个场景）。
- **06-13 版独有的 §14–§17 整体接续在 §13 之后，章节号不变**。原因：06-23 版没有这些章节号，而
  `detailed-design.md` 引用它们共 57 处（§14×4、§15×26、§16×24、§17×3）——直接丢弃会让 ④ 详细设计
  过半的交叉引用悬空。
- **§17 已被 §13 取代**，节内加了注记。保留它仅因 ④-2（UC5 矩阵行只读访问器）的立项依据出自 §17.1 的
  走查发现；该缺口在 06-23 线中由 ADR-009 的 `.matrixAssembled` 事件另行解决。
- 中转文件 `architecture-v0.3-adr-line.md` 已删除（内容已成为 `architecture.md` 正文）。
- `analysis-model.md` 早前已合并：v0.4 的 D5 后端必要性辨析 + 06-13 线的 D1–D4 裁决列。
