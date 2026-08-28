# 会话上下文归档 · 「Doc — 跨项目文档使用」

> **会话**：Doc — 跨项目文档使用（即 `CONTEXT-INDEX.md` 会话总表·工程线中的对应行）
> **Session**：`session_01UswR7WBNeQx7KqgqYez294`（https://claude.ai/code/session_01UswR7WBNeQx7KqgqYez294）
> **outcome 分支**：`claude/vibrant-meitner-r7lsht` —— 从未推送到远程，会话全程未在仓库落过一个提交；**本文件是该会话在仓库中的唯一落地**。
> **会话日期**：2026-08-28（归档于同日）
> **主题一句话**：在另一个项目 / 另一个会话里，怎样"描述"才能用上本仓库的说明文档——交接文档跨项目、跨会话复用的方法论。
> **阅读目标**：读完本文即可完整掌握该会话的勘察结论、产出与方法论，无需回看会话记录。

---

## 0. TL;DR

1. 会话回答的核心问题：**在另一个项目的 Claude 会话里引用本仓库的说明文档，描述必须写全「三要素」**——
   ① 文件在哪（仓库 + **分支** + 路径；"分支"是当时最容易漏的一项，因为文档只存在于 `claude/*` 分支上，新会话默认检出的 master 根本看不见）；
   ② 读哪几个文件；
   ③ 读完按什么指示做（例如按 `HANDOFF-requirements.md` §0「给接手模型的关键指示」执行）。
2. 会话从当时最全的分支 `claude/modest-clarke-a70tkz` 导出了 4 份交接文档
   （HANDOFF-requirements / HANDOFF-architecture / requirements SRS v1.2 / architecture v0.2），
   经会话的文件发送通道直接交付给了用户（用户设备上应存有这 4 个 `.md` 副本）。
3. 针对"消费方会话在本机另一个 git 仓库"这一最终限定场景，给出三个方案：
   **复制进消费方项目（首推）／跨仓库 `git show`／`gh api` 远程拉取**；云端会话另有对应做法（`add_repo`／直接粘贴／setup 脚本）。
4. 会话诊断出根因：**产出只落在自动命名的一次性 outcome 分支上，新会话默认看不见**——并建议把文档并入默认可见的分支。
   这一建议后来由更系统的方案落实：语义分支收敛（`ipad-cfd-teaching/main` / `openfoam-learning/main`）+ `CONTEXT-INDEX.md` 造册 + 本 `context/` 归档目录。

---

## 1. 会话要解决的问题

用户的提问分三步收窄，每一步都推翻了上一步答案的一部分前提：

1. **泛问**：「如果我想在另一个项目的对话中使用到该项目的说明文件，我应该怎么在另一个项目的 session 中进行描述？」
2. **纠偏**：在得到"仓库里没有 CLAUDE.md、说明文件是 README.org 和 doc/"的回答后，用户指出：**带 claude 字样的那几个分支里才有说明文件**——第一轮回答只查了当前检出分支（master 工作副本），漏了远程分支。
3. **限定场景**：「我开启的新对话是**本地路径下的一个 git 仓库**」——排除了云端会话方案，要求针对"本机另一个项目目录里的 Claude Code 会话"给出可操作做法。

这三步本身就是一个有价值的教训（见 §5 结论 D3）：提问者与回答者都被"文档在哪"绊住过——正因为产出散落在 outcome 分支上。

## 2. 勘察结论：说明文档在仓库中的真实分布（会话时点快照）

会话用 `git ls-remote` / `git fetch` / `git diff --name-status master...` / `git show` 做了勘察，结论如下。
**注意：以下是 2026-08-28 会话进行时的远程快照**，与仓库现状已有出入（现状见 §7）。

### 2.1 总体事实

- **仓库任何分支上都没有 `CLAUDE.md`**（master 与三个 claude 分支都查过，新增文件清单中亦无）。
- master 上没有项目说明文档；根目录只有 OpenFOAM 自带的 `README.org` 与 `doc/` 等。
- 「说明文件」实指 `doc/ipad-cfd-teaching/` 下的交接/设计文档（另有 `ipad-cfd-teaching/FoamMini/README.md`，属 Swift 工程自带说明）。

### 2.2 当时远程可见的分支及其文档清单

当时 `git ls-remote --heads origin` 只见 4 个头：master 与三个 claude 分支。三个分支相对 master 的新增文件呈**严格超集链**：

| 分支（当时 tip） | doc/ipad-cfd-teaching/ 下的说明文档 | 其他新增 |
|---|---|---|
| `claude/ecstatic-heisenberg-oA9a8`（`ea8dc1d9`） | HANDOFF-architecture.md、architecture.md | `ipad-cfd-teaching/FoamMini/` 全套（Package.swift + README + 引擎源码 13 个 .swift + 测试） |
| `claude/ipad-cfd-handoff-arch-1dud7f`（`04db6d84`） | 上行全部 + HANDOFF-requirements.md | 同上 |
| `claude/modest-clarke-a70tkz`（`0257325d`） | 上行全部 + requirements.md → **共 4 份，最全** | 同上 |

谱系（由各文档头部自述相互印证）：`ecstatic-heisenberg` ⊂ `ipad-cfd-handoff-arch-1dud7f` ⊂ `modest-clarke`。
（`HANDOFF-architecture.md` 自述"开发分支 1dud7f，已含 ecstatic-heisenberg 全部提交"；`requirements.md` 自述"开发分支 modest-clarke，上游交接 HANDOFF-requirements.md"。）

### 2.3 四份文档各是什么（按当时读到的头部）

| 文件 | 是什么 | 关键头部信息（当时） | 行数（导出时） |
|---|---|---|---|
| `HANDOFF-requirements.md` | 「需求对齐 + 软件工程教学」线的交接文档 | 用途明写"在**新对话**中读取此文件，接续该线"；§0 是「给接手模型的关键指示」（用户是需求方 + 学习者，每步先讲软件工程理论再实操，「第一课/第二课」式教学）；日期 2026-06-10；**头部甚至预警了本会话要解决的问题**："新会话默认检出 master，须先 fetch 该分支才能看到本文件" | 83 |
| `HANDOFF-architecture.md` | 「需求/架构设计」线的交接摘要 | 用途明写"在**新对话**里**粘贴**此摘要"；只含需求与架构设计，不含 FVM 理论与代码实现；产品定位：iPad 教学型 CFD App，OpenFOAM 的「引桥课」 | 101 |
| `requirements.md` | 需求规格（SRS） | 当时为 **v1.2**（2026-06-11；v1.0 定稿 06-10）；v1.2 要点：FR7 升格正式需求（双支柱，M5）、NFR5 改写为分层可用性、新增 NFR6 界面质量；状态：经需求方逐条确认，是架构设计的输入与追溯锚点 | 122 |
| `architecture.md` | 架构设计文档 | 当时为 **v0.2**（2026-06-10）；§2 类映射与 §4 案例数据结构已对照本仓库逐项核实并冻结 | 394 |

一个当时就注意到的现象：两份 HANDOFF 的"开发分支"字段停留在写作时点的 `1dud7f`，而更新的 `requirements.md` 指向 `modest-clarke`——**文档里写死 outcome 分支名会腐化**，应以最新文档的指向为准（这一点在 §7 得到进一步应验：`1dud7f` 现已从远程消失）。

## 3. 产出一：导出并交付 4 份交接文档

**做了什么**：用 `git show origin/claude/modest-clarke-a70tkz:doc/ipad-cfd-teaching/<文件名>`（无需切换分支）把 4 份文档逐一导出为独立文件，经会话的文件发送通道交付到用户设备。共 700 行。

**为什么挑这 4 份**：它们就是当时仓库里全部的项目级说明文档（§2.1），且其中两份 HANDOFF 本来就是**为"新对话接续"这一目的而写**的——用户想做的事（跨项目复用）正是这些文档的设计用途。FoamMini 的 README 未导出：它属于 Swift 工程本体，不是跨会话交接材料。

**为什么以 `modest-clarke-a70tkz` 为导出源**（会话中的决定 D1，理由见 §5）：三分支呈严格超集链，它是唯一含全部 4 份的；且含当时最新的 SRS（v1.2，2026-06-11）；`requirements.md` 头部自证其开发分支即此分支。

## 4. 产出二：跨项目/跨会话文档使用策略（本会话的核心方法论）

### 4.0 描述三要素（总公式）

在任何"消费方会话"里引用另一个仓库的文档，描述必须写全：

> **① 文件在哪**：仓库 + 分支 + 路径（文件不在默认分支时，漏掉分支 = 消费方必然找不到）
> **② 读哪几个**：明确文件清单，别让对方猜
> **③ 读完做什么**：按哪份文档的哪节指示行动（本项目的惯例锚点是 HANDOFF 文档的 §0）

### 4.1 场景 A：消费方会话在本机另一个 git 仓库（用户最终限定的场景）

三个方案按推荐顺序：

#### 方案一（首推）：把文档复制进消费方项目

把 4 份文件放进消费方项目（如 `docs/ipad-cfd-teaching/`），会话里用 `@` 引用。会话中给出的示例描述：

> 开始前请先完整阅读 @docs/ipad-cfd-teaching/HANDOFF-requirements.md 和 @docs/ipad-cfd-teaching/HANDOFF-architecture.md，这是上一个项目的交接文档；按 HANDOFF-requirements.md 第 0 节「给接手模型的关键指示」的要求继续工作，必要时再参考同目录下的 requirements.md（SRS v1.2）和 architecture.md（v0.2）。

还可在消费方项目的 `CLAUDE.md` 里加一行 `@docs/ipad-cfd-teaching/HANDOFF-requirements.md`，实现每次会话自动加载。

- **适用**：长期、反复使用；希望文档随消费方项目一起受版本控制、脱离源仓库独立演化。
- **取舍**：产生副本，**上游更新不会自动同步**——本次归档时已实证这条代价：会话导出的快照是 requirements v1.2 / architecture v0.2，而仓库如今已是 v1.4 / v0.3（见 §7），用户手里的副本已落后。用它就要接受"以复制时点为准"，或定期手动拉新。

#### 方案二：本机已有本仓库克隆——跨仓库 `git show`

不复制文件，在消费方会话里写明"另一个仓库 + 分支 + 路径"，让 Claude 直接跨目录读。会话中给出的示例描述：

> 说明文件在本机另一个仓库 ~/OpenFOAM-dev 的 claude/modest-clarke-a70tkz 分支上（master 上没有）。请先运行 `git -C ~/OpenFOAM-dev fetch origin claude/modest-clarke-a70tkz`，然后用 `git -C ~/OpenFOAM-dev show origin/claude/modest-clarke-a70tkz:doc/ipad-cfd-teaching/HANDOFF-requirements.md`（其余三个文件同理）读取全部说明，再按其中指示继续。

`git show` 的好处：不必切换那个仓库当前检出的分支。若改用直接读文件（`@` 绝对路径），则需先把目标分支检出，且可能要 `--add-dir`／`/add-dir` 授权目录访问。

- **适用**：同机有克隆；偶尔查阅；想始终读到指定分支上的准确版本而非副本。
- **取舍**：依赖本机路径与**分支名**（名称会腐化——`1dud7f` 已被删除即是例证）；描述必须写全三要素；换一台机器即失效。

#### 方案三：本机无克隆——从 GitHub 按需拉取

会话中给出的示例描述（仓库名按当时的用户名，现应更新为 `chuniarch`，见 §7）：

> 说明文件在 GitHub 仓库 developer-zht/OpenFOAM-dev 的 claude/modest-clarke-a70tkz 分支 doc/ipad-cfd-teaching/ 目录下，共 4 个 .md。请用 `gh api -H "Accept: application/vnd.github.raw" "/repos/developer-zht/OpenFOAM-dev/contents/doc/ipad-cfd-teaching/HANDOFF-requirements.md?ref=claude/modest-clarke-a70tkz"` 逐个读取，然后按其中指示继续。

- **适用**：任意机器，只要有网络；只需要几个文件、不想克隆整个大体量的 OpenFOAM 仓库。
- **取舍**：依赖网络与认证（私有仓库需 `gh` 已登录）；同样承受分支名腐化风险；URL 里的用户名在改名后需要更新（GitHub 重定向能兜底，但不宜依赖）。公开仓库可改用 `raw.githubusercontent.com` 直接 `curl`。

### 4.2 场景 B：消费方会话在云端（Claude Code on the web）

云端会话在隔离容器里，只克隆该会话选定的仓库：本机路径一律无效，用户级 `~/.claude/CLAUDE.md` 也不加载。可行做法：

1. **把本仓库加进会话**（仓库须在账号授权范围内）。会话中给出的示例描述：
   > 请把 developer-zht/openfoam-dev 仓库添加到本会话。注意默认检出的是 master，说明文件在另一个分支上：请先执行 `git fetch origin claude/modest-clarke-a70tkz`，然后读取该分支 `doc/ipad-cfd-teaching/` 目录下的 4 份文档，按照其中「给接手模型的关键指示」继续工作。

   （Claude 会经 `list_repos` / `add_repo` 把仓库克隆进容器。取舍：仓库必须已授权；OpenFOAM 体量大，克隆有耗时。）
2. **直接把 HANDOFF 内容粘贴进新对话**——这正是 HANDOFF-architecture.md 头部写明的设计用途（"在新对话里粘贴此摘要"）。取舍：一次性；长文占上下文；未粘贴的部分引用不到。
3. **提交进消费方仓库**（即方案一的云端形态）或在**环境 setup 脚本里 clone** 本仓库后按绝对路径引用。

### 4.3 Claude Code 机制速查（会话中经 claude-code-guide 子代理对照官方文档核查；文档版本 2026-06）

| 机制 | 语法/位置 | 要点与坑 |
|---|---|---|
| CLAUDE.md `@` import | 在 CLAUDE.md 里写 `@路径`（支持相对、绝对、`~`） | 会话启动时展开加载；**嵌套上限 4 跳**；首次遇到外部 import 会弹授权，**拒绝则永久禁用 import** |
| 提示词中 `@文件` 提及 | `@src/x.js`、`@~/other/CLAUDE.md`（相对/绝对/`~` 均可） | 文件全文纳入上下文；**连带加载该文件所在目录及各级父目录的 CLAUDE.md** |
| `--add-dir` / `/add-dir` | `claude --add-dir ../other-project` | 只授予文件读写；**不会**自动发现该目录的 CLAUDE.md/.claude 配置；要加载须设 `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1`；持久化写 settings 的 `permissions.additionalDirectories` |
| 用户级记忆 | `~/.claude/CLAUDE.md`、`~/.claude/rules/*.md` | 本机全项目生效，先于项目规则加载；**云端会话不加载** |
| 云端会话 | 单仓库容器 | 托管环境提供 `list_repos`/`add_repo` 扩充会话仓库；也可 setup 脚本 clone |

文档出处：`code.claude.com/docs/en/memory`（import／用户级记忆／additional directories）、`…/common-workflows`（`@` 文件引用）、`…/claude-code-on-the-web`（云端环境）。

## 5. 结论与决定（含理由）

**D1 · 以 `claude/modest-clarke-a70tkz` 为唯一导出源。**
理由：三分支文件集呈严格超集链，它是唯一含全部 4 份文档的；含当时最新的 SRS v1.2；`requirements.md` 头部自证开发分支即它。两份 HANDOFF 头部写的 `1dud7f` 属写作时点残留，以更新的 `requirements.md` 指向为准。

**D2 · 首推「复制进消费方项目」（方案一）。**
理由：一次复制后彻底消除对外部路径、分支名、网络与认证的依赖；文档进入消费方版本库随项目走；可被 CLAUDE.md import 自动加载。接受的代价：副本不随上游更新（§4.1 已实证）。判断依据是用户场景为"长期在另一个项目里接续工作"，稳定性权重高于新鲜度。

**D3 · 根因诊断：outcome 分支不可见问题。**
"找不到说明文件"不是文件不存在，而是**产出只落在自动命名的一次性 `claude/*` 分支上，新会话默认检出 master 看不见**。本会话第一轮回答自己就踩了这个坑（只查工作副本便断言"没有说明文件"），被用户纠正——这个错误本身就是根因最好的证明。当时给出的对策有二：短期靠描述三要素点名分支；长期建议把 `doc/ipad-cfd-teaching/` 并入默认可见的分支。
**归档时补记**：长期对策已被更系统的工程落实——语义分支收敛（`ipad-cfd-teaching/main` / `openfoam-learning/main`）+ `CONTEXT-INDEX.md` 造册 + 本 `context/` 目录归档未推送会话。本文件正是该体系补上的最后一块：本会话自己的上下文。

**D4 · 事实结论：本仓库没有 CLAUDE.md（当时任何分支）。**
「说明文件」在本仓库语境下 = `doc/ipad-cfd-teaching/` 的交接/设计文档。若希望某些指示对每个会话自动生效，可另行考虑在默认分支加 CLAUDE.md，但那是当时未做的决定，不属于本会话产出。

**D5 · 方法论教训：给文档指路要用稳定坐标。**
文档正文里写死 outcome 分支名（如 HANDOFF 头部的 `1dud7f`）会随分支清理而腐化；指路应指向**语义分支 + 仓库内相对路径**（如今即 `ipad-cfd-teaching/main` 的 `doc/ipad-cfd-teaching/`）。此教训在归档时已两度应验（`1dud7f` 被删；用户名改名使旧 URL 靠重定向续命）。

## 6. 会话止点与原定下一步

- **止点**：完成 4 份文档导出与交付、讲完三方案后，会话以一个待用户表态的 offer 收尾：*"如果你以后还想让这边的会话直接看到这些文件……我可以帮你把这组文档推到我的工作分支，方便你合入 master。"*
- **原定下一步（未执行）**：用户确认后，把 `doc/ipad-cfd-teaching/` 那组文档提交到工作分支 `claude/vibrant-meitner-r7lsht` 并推送，供用户合入 master。用户未接这个 offer，工作分支因此从未有过提交、从未推送——这正是本会话在 `CONTEXT-INDEX.md` 里"分支推送过？= ❌"的由来。
- **实际发展**：那个"下一步"被更彻底的方案取代——用户随后发起了语义分支收敛与上下文造册工程；本归档任务（在 `ipad-cfd-teaching/main` 上写下本文件）就是本会话线的收口动作，原 offer 就此关闭。

## 7. 归档时的现状勘定（2026-08-28 核实；本节内容属归档时补记，非会话原有产出）

1. **GitHub 用户名已由 `developer-zht` 改为 `chuniarch`**。旧路径靠 GitHub 重定向仍可用，但 §4 各示例里的 `developer-zht` 今后应写 `chuniarch`。
2. **4 份文档的规范位置已变**：如今就在本分支（`ipad-cfd-teaching/main`）的 `doc/ipad-cfd-teaching/`，且已演进——`requirements.md` 到 **v1.4**（新增 §9 设计愿景、§10 系统画像等）、`architecture.md` 到 **v0.3 冻结**（另存在 `architecture-v0.3-adr-line.md` 双版待收敛，见 `CONTEXT-INDEX.md`「未决项」）；目录里还多了 stage3/4/5 交接、12 份 ADR、详设等后续产出。两份 HANDOFF 内容未变，头部的 `1dud7f` 分支指针**已失效**（该分支已从远程删除；其内容是 `modest-clarke` 的子集，后者现镜像为 `archive/phase1-2-requirements` 并已收敛进本分支）。
3. **会话导出快照（v1.2 / v0.2）的回溯途径**：用户设备上的 4 份副本；或在 `archive/phase1-2-requirements` 的提交历史中定位对应时点。
4. **今后引用这些文档的标准描述（更新版）**——用稳定坐标替换会话当时的 outcome 分支写法：

   > 说明文档在 GitHub 仓库 chuniarch/OpenFOAM-dev 的 **ipad-cfd-teaching/main** 分支 `doc/ipad-cfd-teaching/` 目录。请先读 `CONTEXT-INDEX.md` 了解全局，再按需读取 HANDOFF-stage5.md（实现线最新交接）或 HANDOFF-requirements.md 等，并按所读文档的「给接手模型的关键指示」继续工作。

   本地会话把仓库/分支换成本机克隆路径 + `git show origin/ipad-cfd-teaching/main:…` 即可；云端会话则先请求把 `chuniarch/OpenFOAM-dev` 加入会话再 fetch 该分支。接续工程线时，优先以 `CONTEXT-INDEX.md` 与最新的 HANDOFF-stage5 为入口，而不是本会话当年导出的那 4 份早期文档。

---

## 附 · 会话过程速览

| 轮次 | 用户输入（概要） | 本会话的动作与回答（概要） |
|---|---|---|
| 1 | 泛问：如何在另一个项目的会话里使用本项目的说明文件 | 查根目录（误判"无说明文件"）；经 claude-code-guide 子代理核查官方机制；按"本地/云端"两场景作答（§4.3 机制即此轮产出） |
| 2 | 纠偏：说明文件在 claude 分支里 | `ls-remote`+fetch+diff 勘察三分支（§2）；确认 HANDOFF 文档的交接用途；提出"三要素"与合入默认分支的建议 |
| 3 | 限定：新对话是本地路径下的 git 仓库 | 从 `modest-clarke` 导出 4 份文档并发送（§3）；给出本地三方案（§4.1）；留下同步 offer 后收尾（§6） |
| 4 | 归档指令 | 写下本文件并推送至 `ipad-cfd-teaching/main` |
