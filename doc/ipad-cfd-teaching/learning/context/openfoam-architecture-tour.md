# 会话上下文归档 —— OpenFOAM 架构解读（第 1 课）

- **Session ID**：`session_01PPW3yiCDdM1dyZ6KAMRxd2`
- **当年 outcome 分支**：`claude/lucid-feynman-fx4lb8`（**未推送到远程**，本仓库无相关文件）
- **归档到分支**：`openfoam-learning/main`
- **配套文档**：`doc/ipad-cfd-teaching/learning/README.md`（CFD 学习阶梯，砖块 1–11）
- **一句话定位**：以 `potentialFoam` 为案例讲 OpenFOAM 的分层架构，讲完第 1 课在"选下一步方向"处停住。

> 本文档尽量保真复原当时讲过的所有内容——类比、推导、对比表格、易混点、代码引用——而不是把它们压成概要。目标读者是**日后接手继续讲课**的那一位（也许是你，也许是另一个会话）。

---

## 0. 会话缘起与用户画像

### 0.1 用户开场

用户原话：

> "我想学习这个仓库的源代码，你能作为老师教我吗？我在想我能不能通过一个具体的案例来学习整个项目的架构设计思想以及具体功能所对应的代码的设计思想？"

三个诉求同时提出：**架构设计思想** + **具体功能的代码设计思想** + **通过一个具体案例**。

### 0.2 我先做的探索

（用来确定"教什么案例合适"，不是给用户看的）

```bash
ls /home/user/OpenFOAM-dev/                # 顶层：applications/ bin/ doc/ etc/ src/ ...
ls /home/user/OpenFOAM-dev/src/            # 40 多个子模块
ls /home/user/OpenFOAM-dev/applications/solvers/
# → boundaryFoam  chemFoam  foamMultiRun  foamRun  potentialFoam
```

发现只有 5 个顶层 solver（新版 OpenFOAM 把大多数专用求解器合并到 `foamRun` + modules 了），其中 `potentialFoam` 最简短：

```bash
wc -l applications/solvers/potentialFoam/*.C applications/solvers/potentialFoam/*.H
# 202 potentialFoam.C
#   9 createControls.H
# 116 createFields.H
# 327 total
```

小、独立、又用到了所有核心机制——**选定为案例**。

### 0.3 我问的 4 个问题与用户回答

用 AskUserQuestion 一次性问了 4 个，用户答案如下：

| 问题 | 用户选择 |
|---|---|
| C++ 水平？ | **初学者**（了解基本语法，模板高级特性不熟） |
| CFD 背景？ | **了解基本概念**（知道有限体积、N-S 方程，不深入） |
| 学习侧重？ | **两者并重，由浅入深** |
| 用 potentialFoam 入门可以吗？ | **我不知道** |

### 0.4 我据此定的教学策略

- C++ 讲解要克制，**不上模板元编程**（CRTP、SFINAE、特化都往后放）；先讲能读懂代码所需的最少语法。
- CFD 数学不从头讲，重点是**"数学怎么变成代码"**。
- 架构先鸟瞰、再深入到具体代码；每课末尾给下一课预告。
- 案例仍用 `potentialFoam`（用户不知道就是我推荐算数）。
- 不催着往下走，每课末尾主动问"哪里没懂 / 要不要就当前内容多聊几句"。

---

## 1. 已讲完的第 1 课：`分层架构 + 求解器骨架`

> 讲课时的标题：**"第 1 课：OpenFOAM 的『分层架构』与求解器骨架"**
> 本课目标（原话）：让你看懂 `potentialFoam.C` 的整体结构，并理解 OpenFOAM 最核心的设计哲学——让 C++ 代码读起来像数学公式。

### 1.1 【设计哲学】代码 = 数学（Embedded DSL）

课上最先端出来的一段代码（不是 potentialFoam，是更经典的 N-S 求解器的一行，用来先震住用户）：

```cpp
solve
(
    fvm::ddt(rho, U) + fvm::div(phi, U) - fvm::laplacian(mu, U)
 ==
   -fvc::grad(p)
);
```

对应数学：

$$\frac{\partial(\rho U)}{\partial t} + \nabla\cdot(\phi U) - \nabla\cdot(\mu\nabla U) = -\nabla p$$

**给用户点破的话**：这就是 OpenFOAM 最神奇的地方——C++ 代码长得跟数学公式几乎一一对应。背后是 **运算符重载 + 模板 + 抽象类型** 的组合艺术。

**引出的抽象术语**：**嵌入式领域特定语言（Embedded DSL）**。让领域专家（CFD 工程师）能直接"写数学"，而不是被指针、循环、稀疏矩阵的细节淹没。

> 📌 **教学意图**：先给一次强烈的"哇"体验，让用户认识到 OpenFOAM 不是普通 C++ 项目，架构设计是它值得看的核心原因。

### 1.2 【分层架构】这个魔术是怎么变出来的

画的层级图（原文照抄）：

```
┌─────────────────────────────────────────────────────┐
│  应用层：solvers (potentialFoam, foamRun ...)        │
│  ─ 一份 .C 文件，几百行，写得像数学                  │
└────────────────────────┬────────────────────────────┘
                         │ uses
┌────────────────────────▼────────────────────────────┐
│  离散化层：finiteVolume (fvm::, fvc::, fvMatrix)     │
│  ─ 把 ∇·、∇²、∂/∂t 翻译成稀疏矩阵                   │
└────────────────────────┬────────────────────────────┘
                         │ uses
┌────────────────────────▼────────────────────────────┐
│  场与网格层：volScalarField, fvMesh, surfaceField     │
│  ─ "场"的概念抽象 + 量纲检查                         │
└────────────────────────┬────────────────────────────┘
                         │ uses
┌────────────────────────▼────────────────────────────┐
│  核心层 (src/OpenFOAM)：容器、IO、字典、并行 Pstream  │
│  ─ List, Field<T>, dictionary, IOobject ...          │
└─────────────────────────────────────────────────────┘
```

**给用户的结论**：每一层只关心自己的事，上层通过非常清晰的接口调用下层。一个 200 行的 `potentialFoam.C` 背后，是上百万行的基础设施——这就是为什么它是"架构教科书"。

### 1.3 【值得学习的设计思想】5 个高频出现的模式

课上没有展开，只在开场简介里列成表格，作为"往后几课要逐个揭开"的地图：

| 设计思想 | 在 OpenFOAM 中的体现 |
|---|---|
| **领域特定语言 (DSL)** | `solve(fvm::ddt(U) + fvm::div(phi,U) == -fvc::grad(p))` 长得像数学 |
| **运行时多态 (RTS)** | 字典文件配置就能切换湍流模型、边界条件、求解器，无需重新编译 |
| **模板元编程** | `Field<Type>`、`GeometricField<Type, PatchField, GeoMesh>` 等高度抽象 |
| **量纲安全** | `dimensionedScalar` 在编译/运行时检查物理量纲，错误的方程根本算不出来 |
| **分层架构** | 数据结构 → 网格 → 场 → 离散化 → 求解器，层层封装 |

> 📌 **教学意图**：让用户看到"这个仓库里有五件设计精品，一件一件来"，避免只学到一个具体案例就止步。

### 1.4 【案例数学背景】potentialFoam 求的是什么

一行数学：

$$\nabla^2 \Phi \;=\; \nabla \cdot \phi, \qquad U = \nabla \Phi$$

**没有多讲物理**（用户懂基本 CFD）。只强调：**势流 = 无粘、无旋**，`Φ` 是速度势，主要用途是"给 N-S 求解器做初场"。

### 1.5 【求解器骨架】potentialFoam.C 的 7 段结构

**教学策略**：不逐行看，先分段，让用户对每段"在干什么"有肌肉记忆，再往里塞细节。

```cpp
int main(int argc, char *argv[])
{
    // ━━━ ① 注册命令行选项 ━━━
    argList::addOption("pName", ...);
    argList::addBoolOption("writePhi", ...);

    // ━━━ ② 加载算例：时间、网格、字段 ━━━
    #include "setRootCaseFunctionObjects.H"  // 解析 case 目录
    #include "createTime.H"                   // 创建 runTime
    #include "createMesh.H"                   // 读取网格
    #include "createFields.H"                 // 创建 U, phi, p, Phi 字段

    // ━━━ ③ 初始化通量 ━━━
    MRF.makeRelative(phi);
    adjustPhi(phi, U, p);

    // ━━━ ④ 核心：解势流方程（含非正交修正循环）━━━
    while (potentialFlow.correctNonOrthogonal())
    {
        fvScalarMatrix PhiEqn
        (
            fvm::laplacian(dimensionedScalar(dimless, 1), Phi)
         ==
            fvc::div(phi)
        );
        PhiEqn.solve();

        if (potentialFlow.finalNonOrthogonalIter())
            phi -= PhiEqn.flux();   // 更新通量
    }

    // ━━━ ⑤ 从通量重构速度场 ━━━
    U = fvc::reconstruct(MRF.absolute(phi));

    // ━━━ ⑥ 写出结果 ━━━
    U.write(); phi.write();

    // ━━━ ⑦ 可选：再算个压力场 ━━━
    if (args.optionFound("writep")) { ... }

    return 0;
}
```

**给用户说的话**：先认识这 7 段的骨架，后面填血肉。

**未讲、但需注意**：
- 段②里 `#include "createFields.H"` 是 OpenFOAM 独特的"用 #include 拆分主函数体"惯例。C++ 圈通常不这样用，但 OpenFOAM 用来把主函数保持在**可读的高度**，同时避免弄出一堆一次性的自由函数。这是一个惯例上的"设计选择"，值得在 Lesson 5 展开吐槽/辩护一次。
- 段④的 `while (potentialFlow.correctNonOrthogonal())` 是**非正交修正循环**。用户勾选了"了解基本概念"，所以我没展开——这条循环是 OpenFOAM 处理非正交网格的通用手法，值得单独一节小课或作为"番外"。

### 1.6 【最关键洞察】fvm 与 fvc 双子星（本课最重要的一节）

聚焦第 ④ 段的心脏代码：

```cpp
fvScalarMatrix PhiEqn
(
    fvm::laplacian(dimensionedScalar(dimless, 1), Phi)  // 左边: ∇²Φ
 ==
    fvc::div(phi)                                        // 右边: ∇·φ
);
PhiEqn.solve();
```

给的对照表（保真原文）：

| 代码 | 数学含义 | 设计奥秘 |
|---|---|---|
| `fvm::laplacian(...)` | ∇²Φ（**隐式**离散） | `fvm` = "finite volume **matrix**"，返回矩阵系数 |
| `fvc::div(phi)` | ∇·φ（**显式**计算） | `fvc` = "finite volume **calculus**"，返回字段值 |
| `==` | 等号 | 重载！把左右两边组装成线性方程组 `A x = b` |
| `fvScalarMatrix` | 离散后的线性系统 | 它内部就是 `A`（稀疏矩阵）和 `b`（向量） |

**核心洞察原文照抄**：

> `fvm::` 和 `fvc::` 是 OpenFOAM 离散化的"双子星"——
> - **`fvm`** 产生**矩阵系数**（用于隐式求解，必须解线性方程组）
> - **`fvc`** 产生**已知字段**（用于显式计算，直接代入数值）
>
> 一个方程的左边通常是 `fvm::`（未知量），右边是 `fvc::`（已知量）。

**跟已有学习阶梯的接口**：
- 砖块 3（一整排盒子 → 联立方程组）里"把一堆盒子摆成矩阵"的过程，**就是 fvm::laplacian 在做的事**。
- 砖块 8A/9（显式 vs 隐式）里"右边全用旧值/新值"的区别，**就是 fvc 与 fvm 的区别**。

这一节要让用户体会到："我自己写过的 Swift 代码所做的事，OpenFOAM 把它做成了一个抽象层。"

### 1.7 【小结】第 1 课让用户带走三件事（原文照抄）

1. **OpenFOAM 的设计哲学**：让代码 = 数学公式，靠的是 C++ 运算符重载 + 模板
2. **分层架构**：从底层容器到顶层求解器，每层只关心自己的抽象
3. **求解器骨架**：注册参数 → 加载网格/场 → 组装方程 → 求解 → 输出

---

## 2. 引用过的源码位置（可直接跳）

课上明确引用（用户可以点开对照读）：

| 文件 | 引用范围 | 讲了什么 |
|---|---|---|
| `applications/solvers/potentialFoam/potentialFoam.C` | 全文 1–202 行 | 求解器骨架（本课主角） |
| ↑ 同上 | 行 37–48 | `#include` 里出现的模块：`argList`、`nonOrthogonalSolutionControl`、`fvcFlux`、`fvcReconstruct`、`fvmLaplacian` 等——**引子**，让用户看到"一个求解器需要用到哪些模块" |
| ↑ 同上 | 行 82–88 | ② 加载算例段（time / mesh / fields） |
| ↑ 同上 | 行 85 | `nonOrthogonalSolutionControl potentialFlow(mesh, "potentialFlow");` |
| ↑ 同上 | 行 101–117 | ④ 核心求解循环（本课最重要的一段） |
| ↑ 同上 | 行 103–108 | `fvScalarMatrix PhiEqn(fvm::laplacian(...) == fvc::div(phi));` |
| ↑ 同上 | 行 123 | `U = fvc::reconstruct(MRF.absolute(phi));` 从通量重构速度 |
| `applications/solvers/potentialFoam/createFields.H` | 全文 1–117 行 | 读过但**没在课上展开**，留给下一课 |
| ↑ 同上 | 行 2–13 | `volVectorField U` 的构造（IOobject + mesh） |
| ↑ 同上 | 行 17–28 | `surfaceScalarField phi(..., fvc::flux(U));` |
| ↑ 同上 | 行 59–72 | `volScalarField p` 的构造（含 `dimensionedScalar(pName, sqr(dimVelocity), 0)` 量纲） |
| ↑ 同上 | 行 90–103 | `volScalarField Phi` 的构造（量纲 `dimLength*dimVelocity`） |
| `src/OpenFOAM/`（目录） | 只列了子目录 | 底层模块：`containers`、`fields`、`db`、`dimensionSet`、`meshes` 等——引子 |
| `src/finiteVolume/`（目录） | 只提到名字 | 离散化层的所在 |

**下一课要开始细读的文件**：`applications/solvers/potentialFoam/createFields.H`（全文）+ 追进 `volVectorField`、`IOobject`、`dimensionedScalar` 的定义。

---

## 3. 会话最后停在哪 / 我给的三个方向

第 1 课讲完，末尾给用户留了三个选项让他挑（**用户还没回**就被要求归档了）：

1. **卡壳复盘**：上面这一课，哪里觉得最不懂？重新讲。
2. **原地深化**：就当前内容多聊几句——比如 `fvm::` 与 `fvc::` 的区别、什么是"非正交修正"。
3. **要执行时序图**：帮你画一个从命令行启动到写出结果的完整流程图。

（继续讲的默认下一步是第 2 课，见下节。）

---

## 4. 第 2 课的原定教学计划（尚未开讲）

**标题**：核心数据结构

**要拆的 4 个具体问题**（原文照抄末尾预告）：

1. **`volVectorField U` 到底是个什么对象？** 为什么它能直接用 `=` 赋值、用 `+ - * /` 运算？
2. **`IOobject` 是干嘛的？** 为什么每个场都要"包"它一层？
3. **`dimensionedScalar` 是怎么实现"量纲检查"的？** 为什么 `1m + 1kg` 会编译错误？
4. **`fvMesh` 内部存了什么？**

**入手点**：把 `createFields.H` 全文当讲义，逐段展开。

**要提到的类层次结构（心里打的草稿，还没画出来给用户）**：

```
GeometricField<Type, PatchField, GeoMesh>          ← 模板基类
  ├─ volVectorField        = GeometricField<vector, fvPatchField, volMesh>
  ├─ volScalarField        = GeometricField<scalar, fvPatchField, volMesh>
  ├─ surfaceScalarField    = GeometricField<scalar, fvsPatchField, surfaceMesh>
  └─ ...
```

**要讲清的核心机制**：
- `GeometricField` = **内部字段 + 边界字段 + 量纲**（三合一）
- **表达式模板**（expression templates）让 `a + b*c` 不产生临时对象——用户是初学者不深讲实现，但至少要指出"OpenFOAM 用这招避免了大数组运算的性能陷阱"。
- `IOobject` 是**注册到数据库 + 决定读写策略**的中间层——它把"这个场叫什么、从哪读、要不要写"和"这个场的数值是什么"解耦。
- `dimensionedScalar` = `scalar 值 + dimensionSet 量纲`；`+` `-` 要求量纲相同，`*` `/` 会**把量纲也乘除**。这是**编译期基础设施 + 运行期检查**的组合。

---

## 5. 我在脑子里酝酿过的完整课程规划

（用户当时没看到这个骨架；写在这里，便于后续会话续讲）

| 课 | 标题 | 重点 |
|---|---|---|
| **1** | 分层架构 + 求解器骨架 | ✅ 已讲完 |
| 2 | 核心数据结构 | `volVectorField`、`IOobject`、`dimensionedScalar`、`fvMesh` |
| 3 | 离散化的优雅 —— `fvm::` 和 `fvc::` | 为什么代码读起来像数学？`fvm::laplacian(p)` 是怎么变成稀疏矩阵的？隐式 vs 显式 |
| 4 | 运行时多态 (RTS) | 字典文件配置就能切换实现、`addToRunTimeSelectionTable` 宏、边界条件当例子 |
| 5 | 求解器主循环 | 综合所有概念，完整解读 `potentialFoam.C`；顺便把"用 `#include` 拆主函数"的惯例讨论一下 |

**可选延伸**：
- 番外 A：非正交修正循环到底在修什么
- 番外 B：`incompressibleFluid`（PISO/SIMPLE）——真的动量-连续性耦合，接砖块 11
- 番外 C：写一个自定义边界条件（RTS 实操）
- 番外 D：Pstream 是怎么把上面的抽象平行化的

---

## 6. 与 `learning/README.md` 的交叉引用

**同一分支上已有的 CFD 学习阶梯**（砖块 1–11，见 `doc/ipad-cfd-teaching/learning/README.md`）**从下往上**搭知识，本会话的架构解读**从上往下**剖代码。两条线的对应关系：

| 学习阶梯砖块 | 对应 OpenFOAM 代码 | 本课程哪里会讲到 |
|---|---|---|
| 砖块 1–2（两盒子、进=出） | `fvScalarMatrix` 里最小行 | Lesson 3 |
| 砖块 3（联立方程组=矩阵） | `fvm::laplacian` 产出的矩阵 | Lesson 3 |
| 砖块 4（`常数 = D·A/Δx`） | `laplacianScheme` 里的面系数计算 | Lesson 3 |
| 砖块 5（边界处理） | `fvPatchField` 派生类（fixedValue、zeroGradient） | Lesson 2 + Lesson 4 |
| 插页 A/B/C（迭代/求解器） | `lduMatrix` 上的 solver（GAMG、PCG…） | Lesson 3 延伸 |
| 砖块 8A/9（显式/隐式） | `fvc::` vs `fvm::` | **Lesson 1 已讲过一次；Lesson 3 展开** |
| 砖块 10（对流、迎风） | `divScheme`、`upwind` | Lesson 3 |
| 砖块 11（PISO） | `incompressibleFluid` / 老 `icoFoam` | 番外 B |

**用户的学习"闭环"**：先在 Swift 里从零手搓（砖块 1–11 学过 4 层翻译：物理 → 数学 → 数据 → 代码），再来读 OpenFOAM 会发现"原来我写过的每件事，OpenFOAM 都做成了一层抽象"。这是本课程一直要往回勾的价值锚点。

---

## 7. 归档时的关键注意事项（写给下一位讲者）

1. **用户是 C++ 初学者**——克制模板炫技，先讲能读懂代码的最少语法。CRTP/SFINAE/表达式模板都可以提"它在这里被用到了、性质是 X"，但不必展开实现。
2. **用户已经手搓过砖块 1–10**——所有 Lesson 都可以往回勾"这就是你砖块 X 写过的那个东西"，让新概念着床更快。
3. **教学节奏**：每课末尾主动问 3 个方向（卡壳复盘 / 原地深化 / 直接下一课），别自动往下走。
4. **课名和编号**：接上 "第 2 课：核心数据结构"，别把编号打乱。
5. **fvm vs fvc 这个洞察 Lesson 1 已给过一次**——Lesson 3 展开时要说"这是你上次听过一次的双子星，现在我们打开它的实现"，让用户感受到复利。
6. **命名**：本会话曾用 GitHub 用户名 `developer-zht`，2026 年已改为 `chuniarch`；仓库路径旧的会自动重定向，不影响任何操作。
