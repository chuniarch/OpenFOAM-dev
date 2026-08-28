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
| Phase 3 — 架构设计 | `session_011ChCfMnEd8TpgR5CBVKD72` | `claude/awesome-einstein-4ebjgx` | ❌ | 详设交接已备：architecture.md §1–17 映射、教学速查卡、FoamMini M0 定位、④ 工作计划 7 项 |
| Phase 3+ — Architecture Design Recording | `session_01HBuV1PbrZ636drTHLZVvaH` | `claude/wonderful-ride-ds1ee5` | ✅ | ③ 冻结 v0.3（12 份 ADR、8 用例走查），等选下一步 |
| Phase 4 — 详细设计 | `session_01PPftrcwP89b5EFVwnCpCWi` | `claude/festive-mccarthy-44aptr` | ✅ | ④ 冻结 v1.0，问要不要先列 M0 起步命令清单 |
| Phase 6 — implementation kickoff | `session_012Lx1PNwGP88e4HqZxHwwTm` | `claude/blissful-noether-gdnfwa` | ✅ | 问先跑通验证，还是先补 DimensionSet / Mesh 单测 |
| Doc — 跨项目文档使用 | `session_01UswR7WBNeQx7KqgqYez294` | `claude/vibrant-meitner-r7lsht` | ❌ | 从 modest-clarke 导出 4 份交接文档，给了 3 种跨仓库用法 |

### 学习线（OpenFOAM 系列）→ `openfoam-learning/main`

| 会话 | Session ID | 当年的 outcome 分支 | 分支推送过？ | 最后停在哪 |
|---|---|---|---|---|
| OpenFOAM — 创作者背景 | `session_01Q9JqJAFZy8pD8yhkqSbUxE` | `claude/pensive-planck-zxB9l` | ❌ | 已答：OpenFOAM 创始人是机械工程 + CFD 背景，非纯 CS |
| OpenFOAM — 最小案例教学 | `session_01GN44s8UkLopir3Bhbt3P2q` | `claude/ecstatic-heisenberg-oA9a8` | ✅ | 学习阶梯（砖块 1–11）成文，开场提示词已生成 |
| OpenFOAM — 架构解读 | `session_01PPW3yiCDdM1dyZ6KAMRxd2` | `claude/lucid-feynman-fx4lb8` | ❌ | 第 1 课讲完，等选方向：澄清概念 / 进第 2 课 / 要执行流程图 |
| OpenFOAM — 学习 icoFoam cavity 案例 | `session_016L4vj8vVVvVokMSbxz95VN` | `claude/lucid-dirac-hic034` | ❌ | 讲完 U 和 p，问要不要继续讲 ν（粘度）和 φ（面通量） |

### 其他相关会话

| 会话 | Session ID | 说明 |
|---|---|---|
| Phase 0 — 架构解读 | `session_014cezmDEefazTL8T43SgC6T` | 已归档。对流-扩散分析、离散误差 vs 迭代误差、二阶收敛验证、三条可靠性判据。分支 `claude/wizardly-mayer-2AkHA` 未推送 |
| 有限体积法 CFD 求解器学习 | `session_015Jk9J73ix6BRyxs31T8ExB` | **改名后新组**里的会话。正在重走本仓库 `learning/README.md` 的砖块 1（两个盒子之间墨水怎么流），当前等你回答。分支 `claude/fvm-cfd-solver-learning-v9280l` 未推送 |

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
  claude/blissful-noether-gdnfwa claude/ecstatic-heisenberg-oA9a8
```

（或在 GitHub 网页 Branches 页面逐个删除。）

## 未决项

**两份 v0.3 架构文档尚未收敛。** ③ 阶段被两个会话各自冻结过一次：

- `architecture.md`（2026-06-13，Phase 4 线）：ADR 台账内联在 §13，续写到 §14–§17。`detailed-design.md` 与 `HANDOFF-stage4/5.md` 建立在此版之上。
- `architecture-v0.3-adr-line.md`（2026-06-23，Phase 3+ 线）：ADR 拆成 12 份独立文件（`adr/`），§13 改为架构评审记录，§0 更详细，新增 §6.1 协作视图。

两版在 §0–§12 各有改动，合并时**未做正文合并**——④ 详细设计只见过 06-13 那版。需要人工裁决后收敛为单一 v0.4。`analysis-model.md` 已完成合并（v0.4 的 D5 + ④ 线的 D1–D4 裁决列）。
