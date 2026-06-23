# ADR-007 — 数学公式渲染 = SwiftMath

- 状态：已接受（2026-06-10 评审冻结，2026-06-23 正规化为 ADR）
- 追溯：NFR5（离线）、NFR4；architecture §7

## 背景

公式渲染须离线可用（NFR5）、快（NFR4）、PDE 标准记号足够。WebView 方案重、有"在线感"、慢。

## 决策

用 **SwiftMath**（iosMath 维护分支）原生渲染数学模式 LaTeX 子集：`latex` 字段（ADR-010 mappings）→ `MTMathView`。复杂排版/长推导若需要，**局部**升级为 `WKWebView + KaTeX`，不影响整体。

## 后果

- ＋ 离线、快、无 WebView；与解释文字（Markdown）分区排版。

## 被否决的选项

- **全局 KaTeX + WebView**：被"重、慢、在线感"否决（保留为局部升级位）。
