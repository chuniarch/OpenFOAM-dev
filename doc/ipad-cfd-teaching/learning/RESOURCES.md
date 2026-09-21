# 有限体积法 / OpenFOAM 资源

## Knowledge

- [Hrvoje Jasak (1996), *Error Analysis and Estimation for the Finite Volume Method with Applications to Fluid Flows*（Imperial College，全文免费）](https://spiral.imperial.ac.uk/handle/10044/1/8335)
  OpenFOAM 的奠基文献，作者是 OpenFOAM 主要作者之一。**最高优先级的一手来源。**
  用于：离散化的完整推导、面通量与非正交修正、误差分析。本工作区讲的 `w = D·A/d` 在其中以矢量形式出现。

- [Moukalled, Mangani & Darwish (2016), *The Finite Volume Method in Computational Fluid Dynamics: An Advanced Introduction with OpenFOAM and Matlab*（Springer）](https://link.springer.com/book/10.1007/978-3-319-16874-6)
  唯一一本把 FVM 理论与 OpenFOAM 实现逐章对照的教科书，含 Matlab 版教学代码 uFVM。
  用于：扩散项/对流项/压力-速度耦合的逐章细节、以及"教科书公式 ↔ OpenFOAM 代码"的对照。付费。

- [Versteeg & Malalasekera, *An Introduction to Computational Fluid Dynamics: The Finite Volume Method*](https://www.pearson.com/)
  FVM 的标准入门教材，控制体记账讲得最平实。
  用于：砖块 1–10 的传统教科书对照版本。注意：它的扩散章节以热传导为例，与本工作区的"水和墨水"口径不同，读时自行换皮。

- [OpenFOAM v13 User Guide（CFD Direct，免费在线）](https://doc.cfd.direct/openfoam/user-guide-v13/contents)
  本仓库 `OpenFOAM-dev` 属于 OpenFOAM Foundation（openfoam.org）这一支，对应的就是这份指南。
  用于：`fvSchemes` / `fvSolution` 里每个关键词的含义、cavity 算例的输入文件。

- [OpenFOAM 官方资源页（openfoam.org）](https://openfoam.org/resources/)
  用于：版本、源码、教程算例的权威入口。

## Wisdom（社区）

- [CFD Online — OpenFOAM 论坛](https://www.cfd-online.com/Forums/openfoam/)
  CFD 领域历史最久、信噪比最高的英文论坛，OpenFOAM 板块活跃。
  用于：自己写的求解器结果"看起来不对但说不上哪里不对"时，贴出算例请人诊断 —— 这是拿不到书上的那部分判断力的地方。

- [CFD-Wiki](https://www.cfd-online.com/Wiki/Main_Page)
  同站的社区维基，术语与经典算例的参考解。
  用于：查 cavity 的公认参考解，验证自己的结果。

> 学习者尚未表态是否愿意加入社区。到砖块 11 跑出第一张 cavity 图之后再提一次
> —— 那时才有"值得拿出去晒"的东西。

## Gaps

- **缺一个中文的、以「水和墨水」为主线的一手来源。** 目前所有高质量来源都用热传导或动量作为扩散的例子，
  与本工作区的口径不一致，只能由我转译。
- **缺 Swift 实现 CFD 的参考。** 现有教学代码是 Matlab（uFVM）和 C++（OpenFOAM）。
  Swift 侧只能靠本仓库自己的 `code/` 与 `ipad-cfd-teaching/main` 上的 FoamMini。
- **缺一个能交互跑的一维扩散可视化**用于建立直觉。`lessons/` 里的计算器是临时替代。
