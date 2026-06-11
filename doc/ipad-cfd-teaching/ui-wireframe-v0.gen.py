#!/usr/bin/env python3
"""iPad CFD 教学 App — UI 线框图 v0（②阶段草案）生成脚本。

信息架构层级的线框：三区一轴 + 10 面板 + 需求追溯标注。
具体布局尺寸/配色/字体/动效留待 ③④ 阶段（按 NFR6 验收）。
依赖: pillow + 文泉驿正黑(CJK) + DejaVu(代码/公式)。
"""
import math
from PIL import Image, ImageDraw, ImageFont

W, H = 2480, 2060
BG = (250, 250, 252)
INK = (34, 34, 34)
GREY = (120, 120, 120)

BLUE_F, BLUE_B = (227, 242, 253), (21, 101, 192)      # 输入区 FR2
GREEN_F, GREEN_B = (232, 245, 233), (46, 125, 50)     # 结果区 FR1/FR3
PURPLE_F, PURPLE_B = (243, 229, 245), (106, 27, 154)  # 教学区 FR4/5/7
ORANGE_F, ORANGE_B = (255, 243, 224), (230, 81, 0)    # 控制 FR1/FR5
HILITE = (255, 245, 157)
RED = (198, 40, 40)

CJK = "/usr/share/fonts/truetype/wqy/wqy-zenhei.ttc"
DEJA = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
DEJAM = "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf"
import os
if not os.path.exists(DEJA):
    DEJA = CJK
if not os.path.exists(DEJAM):
    DEJAM = DEJA

def F(size):  return ImageFont.truetype(CJK, size)
def FD(size): return ImageFont.truetype(DEJA, size)
def FM(size): return ImageFont.truetype(DEJAM, size)

img = Image.new("RGB", (W, H), BG)
d = ImageDraw.Draw(img)

def panel(x1, y1, x2, y2, fill, border, dashed=False):
    if dashed:
        d.rectangle([x1, y1, x2, y2], fill=fill)
        step = 28
        for x in range(x1, x2, step):
            d.line([x, y1, min(x + 14, x2), y1], fill=border, width=5)
            d.line([x, y2, min(x + 14, x2), y2], fill=border, width=5)
        for y in range(y1, y2, step):
            d.line([x1, y, x1, min(y + 14, y2)], fill=border, width=5)
            d.line([x2, y, x2, min(y + 14, y2)], fill=border, width=5)
    else:
        d.rectangle([x1, y1, x2, y2], fill=fill, outline=border, width=5)

def arrow(x1, y1, x2, y2, color, width=6, dashed=False):
    if dashed:
        n = max(int(math.hypot(x2 - x1, y2 - y1) / 26), 1)
        for i in range(0, n, 2):
            t0, t1 = i / n, min((i + 1) / n, 1.0)
            d.line([x1 + (x2 - x1) * t0, y1 + (y2 - y1) * t0,
                    x1 + (x2 - x1) * t1, y1 + (y2 - y1) * t1], fill=color, width=width)
    else:
        d.line([x1, y1, x2, y2], fill=color, width=width)
    a = math.atan2(y2 - y1, x2 - x1)
    L = 26
    d.polygon([(x2, y2),
               (x2 - L * math.cos(a - 0.45), y2 - L * math.sin(a - 0.45)),
               (x2 - L * math.cos(a + 0.45), y2 - L * math.sin(a + 0.45))], fill=color)

# ---------- 标题 ----------
d.text((50, 24), "iPad 横屏 · UI 线框 v0 ——「三区一轴」信息架构", font=F(46), fill=INK)
d.text((1200, 36), "（②需求分析/建模 阶段草案 · 待用例走查验证）", font=F(32), fill=GREY)

# ---------- 设备外框 ----------
d.rounded_rectangle([30, 100, 2450, 1768], radius=40, outline=INK, width=8)

# ---------- 顶栏 ----------
panel(50, 120, 2430, 214, ORANGE_F, ORANGE_B)
d.text((80, 142), "顶栏   案例: cavity · icoFoam", font=F(36), fill=INK)
d.text((900, 142), "[ 运行 ]  [ 暂停 ]  [ 单步 ]  [ 重置 ]", font=F(36), fill=ORANGE_B)
d.text((2080, 148), "←FR1/FR5", font=F(30), fill=GREY)

# ---------- 左列：输入区 ----------
panel(50, 234, 610, 1000, BLUE_F, BLUE_B)
d.text((80, 254), "⑦ 字典编辑器", font=F(38), fill=BLUE_B)
d.text((80, 306), "（表单 / dict 文本 双向同步）←FR2", font=F(28), fill=GREY)
rows = [("movingWall  U", "(1 0 0)  [滑杆]"),
        ("fixedWalls", "noSlip  [选择器]"),
        ("nu  运动黏度", "0.01  [步进器]"),
        ("deltaT", "0.005  [锁定范围]")]
y = 366
for k, v in rows:
    d.rectangle([80, y, 580, y + 64], outline=BLUE_B, width=2)
    d.text((96, y + 14), k, font=FM(26), fill=INK)
    d.text((330, y + 14), v, font=F(26), fill=GREY)
    y += 84
d.rectangle([80, y + 6, 580, y + 240], fill=(248, 250, 255), outline=BLUE_B, width=2)
for i, ln in enumerate(["boundaryField {", "  movingWall {", "    type fixedValue;",
                        "    value uniform (1 0 0);", "  } ..."]):
    d.text((96, y + 18 + i * 42), ln, font=FM(26), fill=INK)

panel(50, 1020, 610, 1560, BLUE_F, BLUE_B)
d.text((80, 1040), "⑧ 网格 / patch 视图", font=F(38), fill=BLUE_B)
d.text((80, 1092), "patch 点选高亮  ←FR2", font=F(28), fill=GREY)
gx1, gy1, gx2, gy2 = 160, 1150, 500, 1490
for i in range(7):
    t = i / 6
    d.line([gx1 + (gx2 - gx1) * t, gy1, gx1 + (gx2 - gx1) * t, gy2], fill=(150, 170, 200), width=2)
    d.line([gx1, gy1 + (gy2 - gy1) * t, gx2, gy1 + (gy2 - gy1) * t], fill=(150, 170, 200), width=2)
d.rectangle([gx1, gy1, gx2, gy2], outline=BLUE_B, width=4)
d.line([gx1, gy1, gx2, gy1], fill=RED, width=10)
d.text((gx1 + 30, gy1 - 44), "movingWall（高亮）", font=F(26), fill=RED)

# ---------- 中列：结果区 ----------
panel(630, 234, 1660, 1280, GREEN_F, GREEN_B)
d.rectangle([650, 252, 990, 312], fill=(200, 230, 201), outline=GREEN_B, width=3)
d.text((668, 264), "④ 矢量 / 流线", font=F(30), fill=INK)
d.rectangle([1000, 252, 1320, 312], outline=GREEN_B, width=2)
d.text((1018, 264), "⑤ 压力云图", font=F(30), fill=GREY)
d.text((1380, 264), "←FR1/FR3", font=F(28), fill=GREY)
cx, cy = 1020, 800
for rx, ry in [(300, 260), (210, 180), (120, 100), (50, 40)]:
    d.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], outline=GREEN_B, width=4)
arrow(cx + 297, cy - 30, cx + 300, cy + 6, GREEN_B, 4)
arrow(cx - 297, cy + 30, cx - 300, cy - 6, GREEN_B, 4)
d.ellipse([cx - 10, cy - 10, cx + 10, cy + 10], fill=GREEN_B)
d.text((cx - 64, cy + 56), "主涡", font=F(28), fill=GREEN_B)

# ② 探针浮卡
d.rectangle([1126, 916, 1646, 1256], fill=(225, 225, 228))           # 阴影
d.rectangle([1110, 900, 1630, 1240], fill=(255, 255, 255), outline=PURPLE_B, width=5)
d.text((1134, 918), "② 数据探针（点 cell 弹出）", font=F(32), fill=PURPLE_B)
d.text((1134, 974), "cell #247", font=FM(28), fill=INK)
d.text((1134, 1022), "U = (0.31, -0.02)   p = 0.012", font=FM(28), fill=INK)
d.text((1134, 1070), "离散模板 / 矩阵系数 aP aN ...", font=F(28), fill=INK)
d.text((1134, 1170), "←FR5", font=F(26), fill=GREY)

panel(630, 1300, 1660, 1560, GREEN_F, GREEN_B)
d.text((660, 1318), "⑥ 残差 / Courant 曲线  ←FR3", font=F(34), fill=GREEN_B)
d.line([700, 1530, 1600, 1530], fill=GREY, width=3)
d.line([700, 1390, 700, 1530], fill=GREY, width=3)
pts_p = [(700 + i * 90, 1400 + 105 * (1 - math.exp(-i / 2.6))) for i in range(11)]
pts_u = [(700 + i * 90, 1430 + 80 * (1 - math.exp(-i / 2.2))) for i in range(11)]
d.line(pts_p, fill=GREEN_B, width=5)
d.line(pts_u, fill=(120, 170, 90), width=5)
d.text((1480, 1395), "p", font=FD(28), fill=GREEN_B)
d.text((1480, 1448), "U", font=FD(28), fill=(120, 170, 90))

# ---------- 右列：教学区 ----------
panel(1680, 234, 2430, 790, PURPLE_F, PURPLE_B)
d.text((1710, 254), "③ 源码面板 — 真实 icoFoam.C  ←FR4", font=F(36), fill=PURPLE_B)
code = ["fvVectorMatrix UEqn", "(", "    fvm::ddt(U)", "  + fvm::div(phi, U)",
        "  - fvm::laplacian(nu, U)", ");", "solve(UEqn == -fvc::grad(p));"]
y = 330
for i, ln in enumerate(code):
    if i == 4:
        d.rectangle([1700, y - 6, 2410, y + 44], fill=HILITE)
    d.text((1716, y), ln, font=FM(30), fill=INK)
    y += 62
d.text((2120, 322), "L75–84", font=FM(24), fill=GREY)

panel(1680, 810, 2430, 1160, PURPLE_F, PURPLE_B)
d.text((1710, 830), "① 数学面板（数学↔代码桥）←FR4", font=F(36), fill=PURPLE_B)
d.text((1710, 910), "∂U/∂t + ∇·(UU) − ν∇²U = −∇p", font=FD(40), fill=INK)
d.rectangle([2062, 900, 2240, 962], outline=RED, width=5)
d.text((1710, 1000), "∇·U = 0  →  压力泊松方程", font=FD(34), fill=GREY)
d.text((1710, 1070), "高亮项与源码行同步", font=F(28), fill=GREY)

panel(1680, 1180, 2430, 1560, PURPLE_F, PURPLE_B, dashed=True)
d.text((1710, 1200), "⑩ AI 对话  ←FR7", font=F(36), fill=PURPLE_B)
d.rectangle([2210, 1196, 2410, 1252], fill=(106, 27, 154))
d.text((2238, 1206), "M5 后置", font=F(30), fill=(255, 255, 255))
d.rectangle([1710, 1270, 2400, 1330], fill=(235, 220, 240))
d.text((1726, 1282), "引用: fvm::laplacian(nu, U)", font=FM(28), fill=INK)
d.text((1710, 1360), "“为什么这一项用隐式离散？”", font=F(30), fill=INK)
d.rectangle([1710, 1430, 2400, 1496], outline=PURPLE_B, width=3)
d.text((1726, 1444), "继续追问…", font=F(28), fill=GREY)
d.text((1710, 1512), "断网置灰（NFR5 分层可用性）", font=F(26), fill=GREY)

# ---------- 底栏 时间轴 ----------
panel(50, 1580, 2430, 1740, ORANGE_F, ORANGE_B)
d.text((80, 1600), "⑨ 时间轴  ←FR5", font=F(36), fill=ORANGE_B)
d.text((80, 1664), "[运行] [暂停] [单步]", font=F(30), fill=INK)
d.line([560, 1680, 1900, 1680], fill=ORANGE_B, width=8)
d.ellipse([1190, 1656, 1238, 1704], fill=ORANGE_B)
d.text((1960, 1660), "t = 0.245 s", font=FD(32), fill=INK)
d.text((2200, 1604), "PISO 子步", font=F(26), fill=GREY)
d.ellipse([2330, 1606, 2360, 1636], fill=ORANGE_B)
d.ellipse([2370, 1606, 2400, 1636], outline=ORANGE_B, width=4)

# ---------- 联动箭头 ----------
arrow(1690, 588, 1620, 700, RED, 6, dashed=True)   # ③ → 结果区
arrow(2050, 600, 2110, 894, RED, 6)                # ③ → ①
d.text((1330, 600), "一处操作 · 多处响应（联动层）", font=F(30), fill=RED)

# ---------- 图例 ----------
ly = 1800
d.text((50, ly), "分区 ↔ 需求追溯：", font=F(34), fill=INK)
legend = [(BLUE_F, BLUE_B, "输入区（改什么）FR2"), (GREEN_F, GREEN_B, "结果区（看什么）FR1/FR3"),
          (PURPLE_F, PURPLE_B, "教学区（懂什么）FR4/FR5/FR7"), (ORANGE_F, ORANGE_B, "运行控制 FR1/FR5")]
x = 380
for f, b, t in legend:
    d.rectangle([x, ly + 2, x + 44, ly + 46], fill=f, outline=b, width=4)
    d.text((x + 58, ly + 4), t, font=F(30), fill=INK)
    x += 58 + len(t) * 31 + 60
d.text((50, ly + 80), "布局立意：左改 → 中看 → 右懂 + 底部时间轴 = 学习闭环「改→算→看→懂」；② 探针为浮层不占常驻区。",
       font=F(30), fill=GREY)
d.text((50, ly + 140), "本图只定信息架构（有什么/在哪区/怎么联动）；具体布局尺寸、配色、字体、动效 = ③④阶段产物，按 NFR6 验收。",
       font=F(30), fill=GREY)
d.text((50, ly + 200), "状态：②阶段草案 v0 —— 将由用例走查验证（每个用例在本布局上走一遍，不顺则改）。",
       font=F(30), fill=GREY)

out = "/home/user/OpenFOAM-dev/doc/ipad-cfd-teaching/ui-wireframe-v0.png"
img.save(out)
print("saved", out, img.size)
