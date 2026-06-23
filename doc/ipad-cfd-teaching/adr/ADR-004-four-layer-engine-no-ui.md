# ADR-004 — 四层分层 + 引擎零 UI 依赖

- 状态：已接受（2026-06-10 评审冻结并验证，2026-06-23 正规化为 ADR）
- 追溯：可调试/可单测（ASR）、演进策略；architecture §1、§1.1

## 背景

"好调试、好优化、可单测"是架构显著需求；演进策略要求"加案例不改框架"。若 UI 与计算混写则不可单测、不可独立优化。

## 决策

系统分四层：**展示层（SwiftUI+Metal）/ 联动层（@Observable ViewModel）/ 引擎层（纯 Swift FVM Core）/ 资源层（Bundle 内嵌）**。引擎层为独立 SwiftPM 包、**零 UI 依赖**，可独立单元测试。

## 后果

- ＋ 引擎可与真 icoFoam 对拍；UI 只读其状态、调其 `step()`。
- 已验证（§1.1）：`FoamMiniEngine` 全部源码 import 仅 `Foundation`，无 SwiftUI/UIKit/Metal。
- 约束 ADR-009：引擎事件须保持此纪律（`SolverEvent` 为纯数据枚举，不含 UI 类型）。

## 被否决的选项

- **UI 与计算混写**：被"不可单测、不可独立优化"否决。
