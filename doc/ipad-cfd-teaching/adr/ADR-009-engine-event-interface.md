# ADR-009 — 引擎事件接口：算子级 + PISO 子步级广播

- 状态：已接受（2026-06-23）
- 追溯：FR4、FR5、UC4、UC5、UC6-E2；architecture §1.1（缺口）、§3；analysis-model D2
- 关系：本 ADR 填补 architecture §1.1 记录的最大设计缺口，并裁定 **D2**

## 背景

§3 要求"每个算子执行时向联动层广播：我在执行 + 对应真实源码哪一段"。FR4（当前执行行高亮）、UC6-E2（思维导图执行游标）、UC4/UC5（单步 + cell 探针矩阵系数）全依赖它。**D2 已定"时间步 + PISO 子步两档"**，故事件须达子步粒度。

已核实事实（`ipad-cfd-teaching/FoamMini/Sources/FoamMiniEngine/Solvers/IcoFoam.swift`）：引擎当前对外仅 `step(time:) -> StepReport`（每时间步一次）+ `run(endTime:onStep:)`，够不到子步与算子级——即 §1.1 记录的缺口。

## 考虑过的选项

- **O1 维持粗粒度 StepReport**：被 FR4/FR5/D2 否决——驱动不了执行游标，也做不了子步单步。
- **O2 裸回调 `onEvent:` 闭包**：能发事件，但暂停/单步/背压语义难做、线程耦合。
- **O3 强类型事件流 `AsyncStream<SolverEvent>`**（采纳）：UI 异步消费；暂停 = 停止拉取，单步 = 拉取到下一个子步边界即停，天然契合 UC4。

## 决策

1. 定义 `enum SolverEvent`，覆盖：时间步边界 / **PISO 修正子步边界（D2）** / 算子执行（每个 `fvm`/`fvc` 带源码锚点 id）/ 矩阵组装完成 / 线性求解 + 残差 / 场更新。每个事件携带 `nodeID`（指回资源层 graph 节点/MappingEntry）+ payload。
2. 引擎暴露 `func events() -> AsyncStream<SolverEvent>`，**保留** `step()`/`run()` 供 headless/测试用。
3. 单步 = 消费到下一个"子步边界"事件即暂停（D2 两档：时间步边界 / PISO 子步边界）。
4. `nodeID` 与资源层 graph/MappingEntry 共用一套字符串 id（如 `"fvm.laplacian"`），联动层据此驱动源码高亮/公式/执行游标/探针。

## 后果

- ＋ FR4 执行行高亮、UC6-E2 执行游标、UC4/UC5 单步（D2 两档）、UC5 探针矩阵系数 全部有数据源。
- ＋ AsyncStream 天然支持暂停（停止消费）/单步（消费一个）/背压，契合 UC4。
- ＋ 不破 ADR-004：`SolverEvent` 是 Foundation-only 纯数据枚举。
- － 引擎 `step()` 内需在每个算子/子步处 `yield` 事件，增复杂度并耦合"教学锚点 id"。缓解：id 作可选元数据，`run()` 不订阅时零开销；事件 schema 与资源层 graph 共用同一 nodeID 命名（单一来源）。
- － T5（单步一致性·逐位一致）要求事件驱动单步与 `run()` 连续跑结果逐位一致。缓解：二者走同一 `step()` 代码路径，事件仅观测不改状态。

## 被否决的选项

- **O1 粗粒度 StepReport**：被 FR4/FR5/D2 否决。
- **O2 裸回调闭包**：被 UC4 暂停/单步语义 + 背压需求否决（不如 AsyncStream 自然）。
