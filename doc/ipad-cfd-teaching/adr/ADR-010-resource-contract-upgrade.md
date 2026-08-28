# ADR-010 — 资源层契约升级：mappings + graph(nodes/edges) + ContextPack 挂点 + AIProvider 接口

- 状态：已接受（2026-06-23）
- 追溯：requirements §9、FR4、FR7；analysis-model §2.4、§3、ADR-001
- 关系：裁定 **D4**，并落地 analysis-model §2.4 的 `Relationship` 概念

## 背景

② 长出三个必须进资源层的新东西：(1) `Relationship`（思维导图的**边**）——原映射表只有节点；(2) `ContextPack`（FR7 喂 AI 的上下文包）；(3) `AIProvider`（ADR-001 可替换接口）。**D4 已定手工坐标**，节点须带 `x,y`。FR7 虽 M5 才实现，挂点 ③ 不能堵死。

## 考虑过的选项

- **O1 维持 mappings-only**：被 requirements §9 / analysis-model §2.4 否决——无边数据则无思维导图。
- **O2 边数据并进 mapping 单文件 vs 独立 graph 文件**：取**独立 `graph.json` + `mappings.json`**，节点用 `mappingId` 引用映射条目，职责分离、lint 清晰。

## 决策

资源层契约 v0.3 = `{mappings.json, graph.json}`：

- `graph.json`：`nodes[{id, kind, title, sourceFile, lineStart, lineEnd, mappingId, x, y}]`（**x,y = D4 手工坐标**）+ `edges[{from, to, type, arrow, label}]`，枚举依 analysis-model §3.2。
- `mappings.json`：MappingEntry 依 architecture §5（id/title/swiftSymbol/源码行/explanationMD/latex/relatedImpl）。
- **构建期 lint**（复用 analysis-model §3.3 四条）：边端点存在 / 枚举合法 / 非 `concept` 节点源码行对照真仓库存在（= 验收测试 T7）/ 无孤儿节点。
- **ContextPack 生成挂点**：纯函数 `makeContextPack(nodeID, iterationState?) -> ContextPack`，从 MappingEntry（+可选求解状态）组装。③ 立形状，M5 用。
- **AIProvider 接口预留**（指回 ADR-001）：`protocol AIProvider { func answer(_ pack: ContextPack, prompt: String) -> AsyncStream<String> }`，留默认端侧 + 可选 BYO-key 两档实现位。

## 后果

- ＋ 兑现 requirements §9 思维导图、analysis-model §2.4 `Relationship` 落地。
- ＋ graph 的 `nodeID` 与 ADR-009 的 `SolverEvent.nodeID` 共用一套命名 → 运行时执行游标与静态结构图天然对齐（同一 id 空间）。
- ＋ ContextPack/AIProvider 形状现在定 → M5 加 FR7 = "加实现，不改框架"。
- － 两份 JSON + lint 维护成本。缓解：lint 复用"无孤儿"纪律 + 对照仓库核验（§2.1 评审纪律）。
- － 手工坐标节点增多时维护累。缓解：MVP 节点少；`x,y` 设为可选，缺省可走自动布局器，格式不排斥。

## 被否决的选项

- **mappings-only**：被 requirements §9 否决。
- **坐标自动布局**（D4 落选）：被"节点少 + 教学语义优先 + 无外部依赖"暂否（格式不堵死，节点增多时可回收）。
