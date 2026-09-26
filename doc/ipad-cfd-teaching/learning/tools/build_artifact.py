#!/usr/bin/env python3
"""把 lessons/*.html 打包成可发布的自包含页面，并做发布前检查。

用法：  python3 tools/build_artifact.py lessons/0005-from-row-to-sheet.html 输出路径.html

做的事：
  1. 取出 <title>、Google Fonts 链接和 <body> 内容（发布时外层骨架由平台补上）；
  2. 把 ../assets/lesson.css 内联成 <style>，把 ../assets/quiz.js 内联成 <script>；
  3. 检查，任何一项不过就报错退出：
     - 不再有任何 ../ 相对引用（发布后这些路径都不存在）；
     - <script> 开闭数量一致（内联的 JS 里若含闭合标签字面量会提前截断脚本）；
     - 每条练习解释 data-fb 都完整（解释里的英文直引号会截断属性，请用「」）。
"""
import re, sys, io, os
from html.parser import HTMLParser

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)

class _FB(HTMLParser):
    def __init__(self):
        super().__init__(); self.bad = []; self.count = 0
    def handle_starttag(self, tag, attrs):
        keys = [k for k, _ in attrs]
        if 'data-fb' in keys:
            self.count += 1
            extra = set(keys) - {'class', 'hidden', 'data-fb'}
            if extra: self.bad.append(dict(attrs)['data-fb'][:40])

def build(src_path, out_path):
    css  = io.open(os.path.join(ROOT, 'assets/lesson.css'), encoding='utf-8').read()
    quiz = io.open(os.path.join(ROOT, 'assets/quiz.js'),   encoding='utf-8').read()
    src  = io.open(src_path, encoding='utf-8').read()

    p = _FB(); p.feed(src)
    if p.bad: sys.exit(f'✗ {src_path}: {len(p.bad)} 条练习解释被截断（多半是英文直引号）：{p.bad}')

    title = re.search(r'<title>.*?</title>', src, re.S).group(0)
    fonts = re.findall(r'<link rel="preconnect"[^>]*>|<link rel="stylesheet" href="https://fonts\.googleapis[^>]*>', src)
    body  = re.search(r'<body>(.*)</body>', src, re.S).group(1).strip()
    body  = body.replace('<script src="../assets/quiz.js"></script>', '<script>\n' + quiz + '\n</script>')
    body  = body.replace('<a href="../formula-cheatsheet.md">公式速查表</a> · <a href="../GLOSSARY.md">术语表</a> · <a href="../README.md">砖块总索引</a>',
                         '仓库里的 <code>formula-cheatsheet.md</code>（公式速查表）、<code>GLOSSARY.md</code>（术语表）、<code>README.md</code>（砖块总索引）')
    page = title + '\n' + '\n'.join(fonts) + '\n<style>\n' + css + '\n</style>\n\n' + body + '\n'

    left = re.findall(r'(?:src|href)="\.\./[^"]*"', page)
    if left: sys.exit(f'✗ {src_path}: 仍有相对引用 {left}')
    if page.count('<script') != page.count('</script>'):
        sys.exit(f'✗ {src_path}: <script> 开闭数量不一致')
    io.open(out_path, 'w', encoding='utf-8').write(page)
    print(f'✓ {src_path} → {out_path}（{len(page)} 字节，练习解释 {p.count} 条全部完整）')

if __name__ == '__main__':
    if len(sys.argv) != 3: sys.exit(__doc__)
    build(sys.argv[1], sys.argv[2])
