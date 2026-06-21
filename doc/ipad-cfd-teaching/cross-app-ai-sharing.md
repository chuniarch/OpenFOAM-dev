# 跨项目 AI 共享层约定 + StyleTwin 实现起手（AIKit）

> **用途**：让两款 iOS App —— **StyleTwin/穿搭分身**（`developer-zht/virtual-try-on`）与 **iPad CFD 教学 App**（本仓库，AI 功能 = FR7「问 AI」/ UC7 / M5）—— **共享同一套 AI "管道"代码**。
> **实施顺序（需求方定）**：**先在 StyleTwin 里实现这套 AI 层**（它更早开工），**再回流复用到本项目**。本文件两个 repo 各放一份。
> **状态**：v0.1 前瞻约定（草案）。本项目 AI 在 M5、尚未开工；StyleTwin 即将开工——故本文件**主要服务 StyleTwin 的实现讨论**，并保证"可被本项目复用"。
> **给接手会话的话**：需求方是产品方+学习者、非工程师；讨论实现细节时先用大白话讲"在干嘛/为什么"，代码/接口落文档，关键选型交其拍板。

---

## §0 一句话定调

两边 **AI 功能不同**（StyleTwin = 图像点评/生成/抠图；CFD = 基于代码上下文的多轮文字问答），但两边 **AI 管道相同**（连模型、流式输出、发数据前征同意、失败重试降级、不被厂商锁死）。
**共享的是"管道"，不是各自的功能逻辑。** 比喻：服装店和书店卖的东西不同，但可以装**同一套收银系统**。

---

## §1 共享什么 / 不共享什么

| 共同点 | 两边都要 | 共享？ | 做成什么 |
|---|---|---|---|
| **Provider 抽象**（换模型不改上层）| StyleTwin C-5/D6/NFR-6；CFD FR7 | ✅ 强 | `AIProvider` 协议 + 各家实现 |
| **流式回答** | StyleTwin NFR-1；CFD UC7④ | ✅ 强 | `AsyncThrowingStream<AIChunk>` + `ChatSession` |
| **聊天 UI 组件** | StyleTwin FR-2 展示；CFD UC7 多轮 | ✅ 中 | 通用 SwiftUI 组件 |
| **同意/披露**（发数据前）| StyleTwin FR-11/NFR-3；CFD UC7-E3 | ✅ 中（机制共享、文案各异）| 通用同意流程 |
| **网络韧性**（超时/重试/退避/降级）| StyleTwin NFR-2；CFD UC7-E2/NFR5 | ✅ 强 | 通用工具 |
| **请求/上下文组装** | 各自不同 | ❌ | 各 App 自己的 request builder |
| **图像生成 / 抠图分割** | 仅 StyleTwin | ❌ | StyleTwin 专属 provider，不进共享层 |

> 共享层只覆盖 **"多模态聊天补全 + 流式"** 这个最大公约数。StyleTwin 的图像生成/分割是它自己的 provider，**不放进 AIKit**。

---

## §2 共享接口契约（草案 —— 多模态 + 流式，从第一天就留好）

```swift
// ============ AIKit / Core（零 SwiftUI、零业务、可单测）============

public protocol AIProvider: Sendable {
    func complete(_ request: AIRequest) async throws -> AIResponse                 // 一次性
    func stream(_ request: AIRequest) -> AsyncThrowingStream<AIChunk, Error>       // 流式
}

public struct AIRequest: Sendable {
    public var system: String?                 // system prompt
    public var messages: [AIMessage]           // 多轮历史 + 当前问题
    public var attachments: [AIAttachment]     // ★多模态：图片等（StyleTwin 点评必需）★
    public var options: AIOptions
}
public struct AIMessage: Sendable, Equatable { public enum Role { case user, assistant }; public var role: Role; public var text: String }
public enum   AIAttachment: Sendable { case image(Data, mime: String) }            // 可扩展
public struct AIChunk: Sendable { public var textDelta: String; public var isFinal: Bool }
public struct AIResponse: Sendable { public var text: String; public var usage: AIUsage? }
public struct AIUsage: Sendable { public var inputTokens: Int; public var outputTokens: Int }  // 成本计量(StyleTwin NFR-5)
public struct AIOptions: Sendable { public var model: String?; public var temperature: Double?; public var maxTokens: Int? }

// 聊天会话状态机（@Observable，UI 只读它）
@MainActor @Observable public final class ChatSession {
    public private(set) var messages: [AIMessage] = []
    public private(set) var streamingText = ""                 // 正在流入的助手消息
    public private(set) var state: ChatState = .idle
    private let provider: AIProvider
    public init(provider: AIProvider, system: String? = nil)
    public func send(_ text: String, attachments: [AIAttachment] = []) async   // 发→流→追加；可取消/重试
    public func cancel()
    public func retryLast() async
}
public enum ChatState: Sendable, Equatable { case idle, sending, streaming, failed(String) }

// 发数据前的同意/披露（机制共享、文案各 App 注入）
public struct AIConsent: Sendable {
    public var scopeText: String        // "你的提问与所引代码 / 你的人像照片 将发送给 AI 服务"
    public var providerName: String
    public var retentionNote: String    // 保留多久 / 是否用于训练
}
```

```swift
// ============ AIKit / UI（可选 SwiftUI 子模块）============
// 通用聊天组件：消息气泡列表、流式文本视图、输入条、加载/重试态、同意弹窗。
// 依赖 Core；各 App 内嵌它、套自己的主题。
```

---

## §3 各 App 专属（不共享，但都"喂"同一个 `AIRequest`）

- **StyleTwin**：`穿搭图 + 偏好 → AIRequest`（image attachment + 点评 system prompt）；另有 `ImageGenProvider`/`SegmentationProvider`（自有，不共享）。
- **CFD 教学**：`ContextPack → AIRequest`（symbol + 源码段 + 公式 + 解释 + 可选求解状态 → system + messages）。**接点 = 本项目 `architecture.md §16` 的 `contextPackHook`**（早为此预留）。

---

## §4 ★两 App 的关键差异（设计共享层时必须照顾，否则回流会卡住）★

| 维度 | StyleTwin | CFD 教学 App | 对共享层的要求 |
|---|---|---|---|
| 联网 | **在线必需** | **离线优先**（NFR5：AI 是唯一需联网的层，其余全离线）| `ChatSession` 须有"离线/置灰"降级态 |
| 后端 | **有自有后端**（可后端代理调 AI、藏密钥）| **端上 App，可能无后端** | `AIProvider` 须容纳**两种实现**：① 后端代理 ② 端上直连 |
| 模态 | 多模态（图像）| 纯文字 | `AIRequest.attachments` 从一开始就留（CFD 用空数组）|
| 轮次 | 单轮点评为主 | 多轮追问 | `ChatSession` 按多轮设计，单轮是其退化 |

> **最该记住的一条**：StyleTwin 有后端，容易把"调 AI"写死成"只走自家后端"。**别写死**——把 `AIProvider` 设计成接口，让"后端代理"和"端上直连"都是它的实现之一。否则将来 CFD（端上、离线优先）没法复用。

### §4.1 所以要写两套代码吗？——不。一个接口、两个小实现

常见疑问：CFD 想"用户自填 API key、端上直连"，StyleTwin"强制走后端"——**这不需要两套代码**，而是**同一个 `AIProvider` 接口、两个小实现**：

- `DirectProvider`（CFD）：拿用户填的 API key，端上直接 HTTPS 调模型厂商。≈ 一个文件。
- `BackendProxyProvider`（StyleTwin）：调自家后端，后端藏 key 再转发模型。≈ 一个文件。

二者**实现同一个 `AIProvider`**（同样的 `complete`/`stream`）。它们**上面的一切**——`ChatSession`、聊天 UI、`AIRequest`、同意流、重试降级——**只写一次、完全不变**，根本不知道自己在跟哪种 Provider 说话。

> 比喻：墙上**插座**形状统一（接口），背后电从**市电/太阳能/发电机**来（实现）都行；电器（ChatSession/UI）只认插座、不管电从哪来。

- **写一次（共享，≈9 成代码）**：`AIProvider` 协议 + 值类型 + `ChatSession` + 聊天 UI + 同意流 + 韧性。
- **每 App 各写一小块（≈1 成）**：自己的 Provider 实现（CFD 一个 `DirectProvider`、StyleTwin 一个 `BackendProxyProvider`）。

> 设计建议：**让 StyleTwin 后端的 AI 接口"长得像 `AIProvider`"**（同样收 messages+attachments+options、流式吐 text delta），这样 `BackendProxyProvider` 只是薄薄一层转发，回流到 CFD 时几乎零摩擦。

---

## §5 待定实现决策（留给 StyleTwin 的实现讨论拍板）

| # | 决策点 | 候选 |
|---|---|---|
| D-A | 流式传输怎么做 | 各家 SDK 原生流 / 自解析 SSE / URLSession bytes 流 |
| D-B | 多模态图片载荷 | base64 内联 / 先上传取 URL 再传引用（影响隐私：人像）|
| D-C | Provider 注入粒度 | 编译期注入 / 运行时配置切换 |
| D-D | 重试/降级统一形状 | 哪些错误可重试、退避参数、降级到什么 |
| D-E | 密钥管理 | 端上存（CFD 可能要）/ 走自有后端代理（StyleTwin 优先）|
| D-F | 成本计量 | 用 `AIUsage` 归因（StyleTwin NFR-5）；CFD 较轻 |

---

## §6 复用机制（"先 StyleTwin、再 CFD"的落地节奏）

1. **StyleTwin 里从第一行就隔离**：把 §2 的 Core 放进独立模块 `AIKit/`，**零 SwiftUI、零穿搭业务**（穿搭逻辑在外面调它）。UI 组件放 `AIKit/UI`。
2. **先在 StyleTwin 跑通**：实现 `AIProvider`（含"后端代理"实现）、`ChatSession`、聊天组件，服务 FR-2 点评。
3. **第二次用时再抽包**（CFD 到 M5）：把 `AIKit/` 抽成 **Swift Package**，两 App 都 `import AIKit`。CFD 只需再写自己的"端上直连 Provider 实现" + "`ContextPack → AIRequest` builder"。
4. **GPL 隔离（CFD 专属坑）**：CFD App 内嵌 GPL 的 OpenFOAM 源码（`architecture.md §11`）。**`AIKit` 必须不沾 GPL**（本就与领域无关），CFD 的 GPL 敏感代码**不进** AIKit，免得"传染"到 StyleTwin。
5. **纪律对齐**：`AIKit/Core` 零 UI、可单测——和本项目"引擎只算、UI 只画"同一招（关注点分离），天然好测好复用。

---

## §7 追溯（哪个共享件服务两边哪条需求）

| 共享件 | StyleTwin | CFD 教学 |
|---|---|---|
| `AIProvider` 抽象 | C-5 / D6 / NFR-6 | FR7（可换模型、不锁定）|
| 流式 `ChatSession` | NFR-1 / FR-2 | UC7④ 流式回答、UC7⑤ 连续追问 |
| 聊天 UI 组件 | FR-2 展示 | UC7 ②③④⑤ |
| 同意/披露 | FR-11 / NFR-3 | UC7-E3（披露"代码将发给 AI"）|
| 韧性（重试/降级）| NFR-2 | UC7-E2 可重试、NFR5 断网降级 |
| request builder（不共享）| 图片→请求 | `ContextPack→请求`（架构 §16 `contextPackHook`）|

---

## §8 StyleTwin 实现会话 · 开场白（复制到 virtual-try-on 的 session 即可启动实现讨论）

```
我要在 StyleTwin（virtual-try-on）里实现一套 AI 层，并要让它将来能被我另一个 App
（iPad CFD 教学 App）复用。请读本仓库的《跨项目 AI 共享层约定》(cross-app-ai-sharing.md)，
重点 §2 共享接口契约、§4 两 App 关键差异、§5 待定实现决策、§6 复用机制。

请按这套带我做实现（我是产品方+学习者、非工程师，先大白话讲"在干嘛/为什么"再写代码，
关键选型交我拍板）：
1) 先把 AIKit/Core 的接口（AIProvider / AIRequest / ChatSession / AIConsent）落成可编译版；
   ——多模态+流式从第一天留好，且 AIProvider 要能同时容纳"后端代理"和"端上直连"两种实现
     （否则将来 CFD 那个端上/离线优先的 App 没法复用，见 §4）。
2) 就 §5 的 D-A..D-F 逐条给我选项、交我拍板；
3) 先实现"后端代理 Provider + 流式 ChatSession + 聊天组件"，服务 StyleTwin FR-2 图文点评；
4) 全程把 AIKit 和穿搭业务隔离（零 SwiftUI 的 Core），方便将来抽成独立包；保持不沾 GPL。
```

---

> 与本项目主线的关系：这是 FR7/M5 的**前瞻备忘**，不进 ④ 详细设计的冻结范围（④ 聚焦 M0 引擎线）。等本项目推进到 M5、且 StyleTwin 的 AIKit 已跑通，再据本约定把 AIKit 抽包引入。
