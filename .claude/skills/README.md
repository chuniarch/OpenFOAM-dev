# 项目 Skills（来自 mattpocock/skills）

本目录下的 25 个 skill 全部复制自 **[mattpocock/skills](https://github.com/mattpocock/skills)**。

| 项 | 值 |
|---|---|
| 上游仓库 | https://github.com/mattpocock/skills |
| 插件名 | `mattpocock-skills` v1.2.3 |
| 复制自 commit | `c55ee46073ed923f86ce59a5eb3b6d895095d1b7`（2026-09-18） |
| 作者 | Matt Pocock — https://www.aihero.dev |
| 协议 | MIT（见 `LICENSE-mattpocock-skills`） |
| 复制日期 | 2026-09-21 |

## 为什么是复制而不是装插件

上游把它发布为 Claude Code 官方市场里的插件（`claude plugins install mattpocock-skills`）。
但**云端会话（claude.ai/code）跑在临时容器里，会话结束即回收**，在容器里装的插件下次就没了。
把 skill 目录提交进仓库，任何一个打开本仓库的会话都会自动加载它们。

代价：**不会自动更新**。要升级见下方「如何更新」。

## 首次使用

在会话里跑一次（每个仓库一次）：

```
/setup-matt-pocock-skills
```

它会问三件事：用哪个 issue tracker（GitHub / Linear / 本地文件）、triage 用什么标签、文档存哪。

## 清单

「仅手动」= skill 声明了 `disable-model-invocation: true`，只有你显式打 `/名字` 才会启用；
「可自动触发」= Claude 判断任务匹配时会自行加载。

| Skill | 作用 | 触发方式 |
|---|---|---|
| `/ask-matt` | 路由器：问它「我这种情况该用哪个 skill」 | 仅手动 |
| `/code-review` | 按 Standards / Correctness 两个维度审查自某个基点以来的改动 | 可自动触发 |
| `/codebase-design` | 设计「深模块」的共用词汇表 | 可自动触发 |
| `/diagnosing-bugs` | 难缠 bug 与性能回归的诊断循环 | 可自动触发 |
| `/domain-modeling` | 建立并打磨项目的领域模型与术语 | 可自动触发 |
| `/grill-me` | 用不留情面的追问来打磨一个方案或设计 | 仅手动 |
| `/grill-with-docs` | 同上，并顺手产出 ADR 和术语表 | 仅手动 |
| `/grilling` | 压力测试你的想法、决策或计划 | 可自动触发 |
| `/handoff` | 把当前对话压缩成交接文档，给下一个 agent 接手 | 仅手动 |
| `/implement` | 按 spec 或 ticket 实现一块工作 | 仅手动 |
| `/improve-codebase-architecture` | 扫描代码库找可深化之处，出 HTML 报告，再逐条追问 | 仅手动 |
| `/prototype` | 做一次性原型来回答某个设计问题 | 可自动触发 |
| `/research` | 对着高可信一手资料做调研，结果落盘成 Markdown | 可自动触发 |
| `/resolving-merge-conflicts` | 解决进行中的 merge / rebase 冲突 | 可自动触发 |
| `/setup-matt-pocock-skills` | 初始化本仓库（tracker、标签、文档位置） | 仅手动 |
| `/tdd` | 测试驱动开发，红-绿-重构 | 可自动触发 |
| `/teach` | **有状态地教你一个概念**，在工作区里维护学习记录 | 仅手动 |
| `/to-questionnaire` | 把你答不了的决策变成一份问卷交给别人填 | 仅手动 |
| `/to-spec` | 把当前对话直接写成 spec 并发到 issue tracker | 仅手动 |
| `/to-tickets` | 把计划拆成一组「曳光弹」ticket，各自声明阻塞关系 | 仅手动 |
| `/triage` | 按状态机流转 issue 与外部 PR：分类、核实、追问 | 仅手动 |
| `/wait-what` | 「刚才那段没听懂，重讲」 | 仅手动 |
| `/wayfinder` | 规划超出单次会话容量的大块工作，画成决策 ticket 地图 | 仅手动 |
| `/wizard` | 生成交互式 bash 向导，带人走只有人能做的步骤 | 可自动触发 |
| `/writing-for-agents` | 写给 agent 看的文档（编写 skill、改 AGENTS.md / CLAUDE.md 时用） | 可自动触发 |

## 名称冲突提醒

`/code-review` 与 Claude Code **内置的** `/code-review` 同名。项目 skill 优先，
所以在本仓库里打 `/code-review` 走的是 Matt 这一版（Standards + Correctness 两轴），
不是内置那版（按 effort level 找 bug）。想要内置那版时请注意这一点。

## 如何更新

```bash
git clone --depth 1 https://github.com/mattpocock/skills /tmp/mp-skills
# 用 /tmp/mp-skills/.claude-plugin/plugin.json 里的 skills 列表逐个覆盖本目录，
# 然后更新本文件顶部的 commit 与日期
```

或者放弃这种方式，改用上游推荐的两条官方路线之一（**两者只能选一个，都装会重复**）：

```bash
claude plugins install mattpocock-skills        # Claude Code 插件，自动更新
npx skills@latest add mattpocock/skills         # 把可编辑的文件写进项目
```

## 分支说明

本目录目前只在 `openfoam-learning/main` 分支上。若希望在 `master` 或其他分支的会话里也可用，
需要把 `.claude/` 目录合并过去。
