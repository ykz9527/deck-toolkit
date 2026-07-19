# deck-toolkit P1:data-ref 锚点 + serve 注入 picker/热更新 + deck-editing skill 实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 让已生成的 deck 能"指哪改哪":模板给语义单元预埋 `data-ref` 锚点;`serve.sh` 在服务时注入 picker(点选拷贝引用块)与热更新脚本;新增 `deck-editing` skill 教 Claude 消费引用块做外科手术式编辑。

**Architecture:** `data-ref` 是内容、烤进 deck 文件(picker 读它、Claude grep 它定位)。picker 与热更新是**行为脚本,永不进文件**——`serve.sh` 升级成小 python server,在 `</body>` 前现场注入,故交付文件天生干净、老 deck 也能用(见 spec §5.1/§9)。

**Tech Stack:** 原生 JS(picker,无框架)、python3 http.server 子类(注入服务器)、现有 python 版 `verify.sh`、Markdown(skill 文档)。无新依赖。

## Global Constraints

- **picker/热更新绝不写进 deck 文件**:只由 `serve.sh` 服务时注入;`deck.html` 落盘版永远只含内容(含惰性 `data-ref`)。交付底线(单文件、无外部请求)对落盘文件天然成立。
- **`data-ref` 命名**:`data-ref="s{页序}-{语义slug}"`(1-based 页序);幻灯片 section 自身用 `data-ref="s{N}"`,标题用 `s{N}-title`。slug 用短 kebab,人能看懂(如 `s3-source-of-truth`)。
- **picker 剪贴板降级**:LAN `http://` 非安全上下文,`navigator.clipboard` 会失败——必须回退到"弹一个可选中 textarea 让用户手动复制"。
- **老 deck 无 data-ref**:picker 回退到"页码 + 唯一文本 + outerHTML";引用块标注 ⚠️;`deck-editing` 改到未标记元素时顺手补 data-ref。
- **零回归**:`bash tests/check-parity.sh` 在 P1 结束时仍须 PASS(P1 改的是模板/脚本/新增 skill;parity 比对的是 `p0-baseline`,模板/脚本本就在比对集里——见"验收")。**注意**:P1 会合法改动模板(加 data-ref)和 serve.sh(注入),因此 parity 会对 assets/scripts 报 FAIL。**P1 结束时须把 `p0-baseline` 的"零回归"语义收窄为"SKILL.md 内容不回归 + references 不回归",模板/脚本的 P1 变更是有意变更**——在 Task 6 更新 check-parity.sh 的注释与比对集,不要靠删测试掩盖。
- **验证靠真跑浏览器**(项目铁律):serve 起来、点选、看引用块、编辑、看热更新刷新;不靠"脚本 grep 到就算过"。
- 代码/commit message 英文;skill 文档中文正文可(沿用现有 references 风格)。

---

### Task 1: 模板预埋 data-ref + verify.sh 覆盖率检查

给 `shared/assets/deck-template.html` 的语义单元打 `data-ref`,并让 `verify.sh` 检查覆盖率(缺了就 FAIL)。

**Files:**
- Modify: `shared/assets/deck-template.html`(给 section/标题/交互根/图加 data-ref)
- Modify: `shared/scripts/verify.sh`(加覆盖率检查)
- Modify: `shared/references/deck-mechanics.md`(记 data-ref 命名约定一小节)

**Interfaces:**
- Produces:模板中每个 `<section class="...slide...">` 有 `data-ref="s{N}"`;每个 `[data-anim]`/`[data-cmp]` 交互根有 `data-ref="s{N}-{slug}"`;每张 `.apx-fig` 图有 data-ref。verify.sh 暴露两条新 check。

- [ ] **Step 1: 盘点模板里的语义单元(先看清楚要标什么)**

```bash
cd /home/fdse/ytest/deck-toolkit
grep -n 'class="slide\|data-anim\|data-cmp\|class="apx-fig' shared/assets/deck-template.html
```
Expected:列出所有 slide section、交互根、附录图的行号。记下每个 slide 的序号与主题,用来编 slug。

- [ ] **Step 2: 给 verify.sh 写覆盖率检查(先写检查,再让模板满足它 = 类 TDD)**

在 `shared/scripts/verify.sh` 的 `-- delivery floors --` 段后、`RESULT` 前,插入(用 Edit,锚定 `print("-- delivery floors`那段之后合适位置):

```python
print("-- data-ref anchors (P1: picker/edit locating) --")
slide_tags = re.findall(r'<section[^>]*class="[^"]*slide[^"]*"[^>]*>', s)
slides_missing = [t for t in slide_tags if 'data-ref=' not in t]
check(f"every slide section has data-ref ({len(slide_tags)} slides)", not slides_missing,
      f"{len(slides_missing)} slide(s) missing data-ref — the picker locates by it")
iroots = re.findall(r'<[^>]*\bdata-(?:anim|cmp)="[^"]*"[^>]*>', s)
iroots_missing = [t for t in iroots if 'data-ref=' not in t]
check(f"every interaction root has data-ref ({len(iroots)} roots)", not iroots_missing,
      f"{len(iroots_missing)} interaction root(s) missing data-ref")
```

- [ ] **Step 3: 跑 verify,确认新检查此刻 FAIL(模板还没打 data-ref)**

```bash
cd /home/fdse/ytest/deck-toolkit
bash shared/scripts/verify.sh shared/assets/deck-template.html 2>&1 | grep -A1 'data-ref anchors'
```
Expected:`every slide section has data-ref` 一行为 `FAIL`(模板尚未打标),证明检查有效。

- [ ] **Step 4: 给模板打 data-ref**

用 Edit 给 `shared/assets/deck-template.html`:
- 每个 `<section class="...slide...">` 加 `data-ref="s{N}"`(N=该页 1-based 序号);
- 每页标题元素加 `data-ref="s{N}-title"`;
- 每个 `[data-anim]`/`[data-cmp]` 交互根加 `data-ref="s{N}-{slug}"`(slug 取该交互主题,如 `s{N}-compare`);
- 每张 `.apx-fig` 图加 `data-ref="s{N}-fig"`。
保持已有属性不动,只加 `data-ref`。

- [ ] **Step 5: 跑 verify,确认全绿(除模板本就设计内的 PLACEHOLDER-REDRAW FAIL 外)**

```bash
cd /home/fdse/ytest/deck-toolkit
bash shared/scripts/verify.sh shared/assets/deck-template.html 2>&1 | grep -A1 'data-ref anchors'
```
Expected:两条 data-ref 检查都 `OK`。(整体 RESULT 仍会因 PLACEHOLDER-REDRAW 而 ISSUES,那是模板固有设计,不管。)

- [ ] **Step 6: 在 deck-mechanics.md 记命名约定**

在 `shared/references/deck-mechanics.md` 加一小节 "data-ref 锚点"(约定见 Global Constraints:`s{N}` / `s{N}-title` / `s{N}-{slug}` / `s{N}-fig`;生成 deck 时打,picker 与 deck-editing 靠它定位)。

- [ ] **Step 7: 提交**

```bash
cd /home/fdse/ytest/deck-toolkit
git add shared/assets/deck-template.html shared/scripts/verify.sh shared/references/deck-mechanics.md
git commit -m "feat(template): data-ref anchors on semantic units + verify.sh coverage check"
```

---

### Task 2: picker.js(点选拷贝引用块的注入脚本)

新建 `shared/assets/picker.js`——一个自执行 IIFE,提供点选模式、hover 高亮、shift 多选、生成引用块、复制到剪贴板(含非安全上下文降级)。此文件**不进 deck**,由 serve 注入(Task 3)。

**Files:**
- Create: `shared/assets/picker.js`

**Interfaces:**
- Produces:注入后,页面右下角出现 `📍 pick` 按钮;点选后引用块进剪贴板(或降级 textarea)。引用块格式见代码 `block()`。

- [ ] **Step 1: 写 picker.js**

创建 `shared/assets/picker.js`:

```javascript
(function () {
  if (window.__deckPicker) return; window.__deckPicker = true;
  var picking = false, selected = [];

  var btn = document.createElement('button');
  btn.textContent = '📍 pick';
  btn.style.cssText = 'position:fixed;right:12px;bottom:12px;z-index:99999;font:600 13px system-ui;padding:6px 10px;background:#111;color:#fff;border:1px solid #444;border-radius:4px;cursor:pointer';
  var hl = document.createElement('div');
  hl.style.cssText = 'position:fixed;pointer-events:none;z-index:99998;border:2px solid #c0673a;background:rgba(192,103,58,.12);display:none';
  var toast = document.createElement('div');
  toast.style.cssText = 'position:fixed;left:50%;bottom:56px;transform:translateX(-50%);z-index:99999;font:13px system-ui;background:#111;color:#fff;padding:8px 12px;border-radius:4px;display:none;max-width:80vw';
  function mount(){ document.body.appendChild(btn); document.body.appendChild(hl); document.body.appendChild(toast); }
  if (document.body) mount(); else document.addEventListener('DOMContentLoaded', mount);

  function refEl(el){ return el && el.closest ? el.closest('[data-ref]') : null; }
  function slideOf(el){ return el && el.closest ? el.closest('section[class*="slide"]') : null; }
  function show(msg){ toast.textContent = msg; toast.style.display = 'block'; }
  function setPicking(on){ picking = on; btn.textContent = on ? '✓ picking (Esc)' : '📍 pick'; if (!on) hl.style.display = 'none'; }

  btn.addEventListener('click', function (e){ e.stopPropagation(); setPicking(!picking); if (picking){ selected = []; show('点选要改的元素;Shift 多选'); } });
  document.addEventListener('keydown', function (e){ if (e.key === 'Escape') setPicking(false); });

  document.addEventListener('mousemove', function (e){
    if (!picking) return;
    var t = refEl(e.target) || e.target;
    if (!t || t === btn || t === toast){ hl.style.display = 'none'; return; }
    var r = t.getBoundingClientRect();
    hl.style.display = 'block'; hl.style.left = r.left + 'px'; hl.style.top = r.top + 'px';
    hl.style.width = r.width + 'px'; hl.style.height = r.height + 'px';
  }, true);

  document.addEventListener('click', function (e){
    if (!picking || e.target === btn) return;
    e.preventDefault(); e.stopPropagation();
    var t = refEl(e.target) || e.target;
    if (!e.shiftKey) selected = [];
    selected.push(t);
    copyRefs();
  }, true);

  function slideMeta(sl){
    if (!sl) return { idx: '?', nav: '', title: '' };
    var slides = Array.prototype.slice.call(document.querySelectorAll('section[class*="slide"]'));
    var titleEl = sl.querySelector('[data-ref$="-title"], h1, h2, h3, .slide-title');
    return { idx: slides.indexOf(sl) + 1, nav: sl.getAttribute('data-nav') || '', title: titleEl ? titleEl.textContent.trim().slice(0, 60) : '' };
  }
  function block(el){
    var m = slideMeta(slideOf(el));
    var r = refEl(el); var ref = r ? r.getAttribute('data-ref') : null;
    var html = el.outerHTML.replace(/\s+/g, ' ').trim(); if (html.length > 400) html = html.slice(0, 400) + '…';
    var out = ['📍 第 ' + m.idx + ' 页' + (m.nav ? ' · [' + m.nav + ']' : '') + (m.title ? ' · 「' + m.title + '」' : '')];
    if (ref) out.push('🔑 data-ref="' + ref + '"   ← Claude grep 唯一命中');
    else out.push('⚠️ 该元素无 data-ref;靠页码+片段定位,Claude 请顺手补一个 data-ref');
    out.push('📄 片段:' + html);
    return out.join('\n');
  }
  function copyRefs(){
    var text = selected.map(block).join('\n\n') + '\n\n✏️ 我的指令:';
    var ok = function (){ show('已复制 ' + selected.length + ' 处引用 → 粘到 Claude Code,补上指令'); };
    if (navigator.clipboard && navigator.clipboard.writeText) navigator.clipboard.writeText(text).then(ok, function (){ manual(text); });
    else manual(text);
  }
  function manual(text){
    var box = document.createElement('textarea');
    box.value = text;
    box.style.cssText = 'position:fixed;left:50%;top:50%;transform:translate(-50%,-50%);z-index:100000;width:80vw;height:40vh;font:12px monospace;padding:8px';
    document.body.appendChild(box); box.focus(); box.select();
    show('非 https 无法自动复制:手动 Ctrl/Cmd+C,再点空白关闭');
    var close = function (ev){ if (ev.target !== box){ box.remove(); document.removeEventListener('click', close, true); } };
    setTimeout(function (){ document.addEventListener('click', close, true); }, 300);
  }
})();
```

- [ ] **Step 2: 语法自检(node 解析,不依赖浏览器)**

```bash
cd /home/fdse/ytest/deck-toolkit
node --check shared/assets/picker.js && echo "picker.js syntax OK"
```
Expected:`picker.js syntax OK`。(若无 node,用 `python3 -c "import esprima"` 不可行则跳过,靠 Task 3 浏览器验证。)

- [ ] **Step 3: 提交**

```bash
cd /home/fdse/ytest/deck-toolkit
git add shared/assets/picker.js
git commit -m "feat(picker): click-to-copy reference-block overlay (injected, never in the deck file)"
```

---

### Task 3: serve.sh 升级为注入服务器(picker + 热更新)

把 `shared/scripts/serve.sh` 从 `python3 -m http.server` 换成一个小 python server:服务 deck 页面时在 `</body>` 前注入 picker.js 与热更新脚本;其它资源照常。

**Files:**
- Rewrite: `shared/scripts/serve.sh`

**Interfaces:**
- Consumes: `shared/assets/picker.js`(Task 2),按脚本自身位置定位(`$BASH_SOURCE/../assets/picker.js`)。
- Produces:`serve.sh <deck.html> [port]` 起服务;GET deck 返回注入版;HEAD deck 返回真实 mtime 供热更新比对。

- [ ] **Step 1: 重写 serve.sh**

把 `shared/scripts/serve.sh` 全文替换为:

```bash
#!/usr/bin/env bash
# Serve a deck on 0.0.0.0, injecting the picker + hot-reload before </body>.
# The picker/hot-reload are NEVER written into the deck file — only injected in
# transit, so the on-disk deck stays a clean, mailable single file.
# Usage: ./serve.sh [path/to/deck.html] [port]
set -u
F="${1:-showcase_deck/index.html}"
[ -f "$F" ] || { echo "no deck at: $F  (build it to showcase_deck/index.html first)"; exit 1; }
PORT="${2:-8770}"
DIR="$(cd "$(dirname "$F")" && pwd)"; BASE="$(basename "$F")"
SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PICKER="$SKILL_DIR/assets/picker.js"
IP="$(hostname -I 2>/dev/null | awk '{print $1}')"; [ -n "${IP:-}" ] || IP="127.0.0.1"
echo "Serving $DIR on 0.0.0.0:$PORT  →  http://$IP:$PORT/$BASE   (picker + hot-reload injected)"
cd "$DIR" && exec python3 - "$PORT" "$BASE" "$PICKER" <<'PY'
import sys, os, http.server, socketserver
port = int(sys.argv[1]); deck = sys.argv[2]; picker_path = sys.argv[3]
picker = open(picker_path, encoding="utf-8").read() if os.path.exists(picker_path) else "/* picker.js not found */"
HOT = ("(function(){var last=null;setInterval(function(){"
       "fetch(location.pathname||'/',{method:'HEAD',cache:'no-store'})"
       ".then(function(r){var m=r.headers.get('Last-Modified');"
       "if(last&&m&&m!==last){location.reload();}last=m;}).catch(function(){});},1000);})();")
INJECT = ("<script>" + picker + "</script>\n<script>" + HOT + "</script>\n</body>").encode("utf-8")

class H(http.server.SimpleHTTPRequestHandler):
    def _is_deck(self):
        p = self.path.split("?")[0].lstrip("/")
        return p == "" or p == deck
    def do_GET(self):
        if self._is_deck():
            with open(deck, "rb") as f: html = f.read()
            html = html.replace(b"</body>", INJECT, 1) if b"</body>" in html else html + INJECT
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(html)))
            self.send_header("Cache-Control", "no-store")
            self.end_headers(); self.wfile.write(html)
        else:
            super().do_GET()
    def do_HEAD(self):
        # For the deck, fall through to the real file so Last-Modified (mtime)
        # reflects edits — that is what the injected hot-reload polls.
        if self._is_deck() and self.path.split("?")[0].lstrip("/") == "":
            self.path = "/" + deck
        super().do_HEAD()

socketserver.TCPServer.allow_reuse_address = True
with socketserver.TCPServer(("0.0.0.0", port), H) as httpd:
    try: httpd.serve_forever()
    except KeyboardInterrupt: pass
PY
```

- [ ] **Step 2: 起服务并确认注入生效(真跑)**

```bash
cd /home/fdse/ytest/deck-toolkit
mkdir -p /tmp/p1demo/showcase_deck && cp shared/assets/deck-template.html /tmp/p1demo/showcase_deck/index.html
bash shared/scripts/serve.sh /tmp/p1demo/showcase_deck/index.html 8781 &
sleep 1
echo "--- 注入的 picker 是否在响应里 ---"
curl -s http://127.0.0.1:8781/index.html | grep -c '__deckPicker'
echo "--- 热更新脚本是否在 ---"
curl -s http://127.0.0.1:8781/index.html | grep -c 'location.reload'
echo "--- HEAD 有 Last-Modified 吗 ---"
curl -sI http://127.0.0.1:8781/index.html | grep -i 'Last-Modified' | head -1
```
Expected:前两个各 `1`(picker 与热更新都注入了);HEAD 有 `Last-Modified` 头。

- [ ] **Step 3: 确认热更新的 mtime 会变**

```bash
M1=$(curl -sI http://127.0.0.1:8781/index.html | grep -i 'Last-Modified')
touch /tmp/p1demo/showcase_deck/index.html; sleep 1
M2=$(curl -sI http://127.0.0.1:8781/index.html | grep -i 'Last-Modified')
[ "$M1" != "$M2" ] && echo "mtime 变了 → 浏览器会 reload ✓" || echo "mtime 没变 ✗ 需排查"
kill %1 2>/dev/null || true
```
Expected:`mtime 变了 → 浏览器会 reload ✓`。

- [ ] **Step 4: 提交**

```bash
cd /home/fdse/ytest/deck-toolkit
git add shared/scripts/serve.sh
git commit -m "feat(serve): inject picker + hot-reload at serve time (deck file stays clean)"
```

---

### Task 4: deck-editing skill(教 Claude 消费引用块、外科手术改)

新增 skill `skills/deck-editing/`:一份 `SKILL.md` + 一份 `references/edit-loop.md`。`install.sh` 已按 `skills/*` 自动扇出(P0),无需改 install。

**Files:**
- Create: `skills/deck-editing/SKILL.md`
- Create: `skills/deck-editing/references/edit-loop.md`

**Interfaces:**
- Consumes:picker 生成的引用块格式(Task 2 `block()`);`data-ref` 约定(Task 1)。
- Produces:一个可被 `showcase-deck`/`paper-deck` 在"改已生成 deck"时引用的编辑回路 skill。

- [ ] **Step 1: 写 SKILL.md**

创建 `skills/deck-editing/SKILL.md`,frontmatter + 正文:

```markdown
---
name: deck-editing
description: Use when iterating on an ALREADY-GENERATED deck (built by showcase-deck / paper-deck) — the user pasted a picker "引用块" (a 📍/🔑/📄 reference), or asks to change a specific slide/element or restructure the deck. Not for building a deck from scratch.
---

# Deck Editing (iterate on a built deck)

打磨一份**已经生成**的 HTML deck。后端就是当前这个对话——没有独立工具。两类改动:

## 区域级改(用户粘来一个"引用块")
picker(serve 时注入,见 shared/scripts/serve.sh)让用户点选元素、把引用块拷到剪贴板粘回这里。引用块长这样:
```
📍 第 3 页 · [为何好] · 「…」
🔑 data-ref="s3-source-of-truth"   ← grep 唯一命中
📄 片段:<div ... data-ref="s3-source-of-truth"> … </div>
✏️ 我的指令:把左右对比换成上下
```
步骤见 references/edit-loop.md。核心:**grep `data-ref` 唯一定位 → 只改那一处 → verify → 靠热更新回显**。

## 结构级改(加/删/重排页、换主线)
- 主线在模板的 `MAINLINE` 数组一处改。
- 重排/增删页:操作对应的 `<section class="slide" data-ref="sN">`;改动后**重编 data-ref 的页序号**(见 edit-loop.md)。

## 铁律
- 改之前 `cp index.html index.html.bak`;verify FAIL 就回滚,别把坏页留给用户。
- 用户在 serve,改完文件即热更新——**不要**自己重启服务器。
- 遇到没有 data-ref 的元素:定位后**顺手补一个** `data-ref="sN-slug"`(约定见 shared/references/deck-mechanics.md)。
```

- [ ] **Step 2: 写 references/edit-loop.md**

创建 `skills/deck-editing/references/edit-loop.md`,含:
1. **区域级回路**(逐步):① 从引用块取 `data-ref`;② `grep -n 'data-ref="s3-source-of-truth"' showcase_deck/index.html` 唯一定位;③ 若命中 >1 或 0,回退到引用块的"页码 + 📄 片段里的唯一文本"再 grep;④ `cp` 备份;⑤ 用 Edit 只改那一处(锚定 data-ref 所在元素);⑥ `bash <skill>/scripts/verify.sh showcase_deck/index.html`,FAIL 则从备份回滚;⑦ 不重启 serve,热更新自动刷新。
2. **无 data-ref 的降级**:引用块带 ⚠️ 时,用 📄 片段里最独特的一段文本定位,改完给该元素补 `data-ref="sN-slug"`。
3. **结构级**:换 `MAINLINE`;重排/增删 slide section 后,把受影响页的 `data-ref="sN..."` 与 `sN-title` 等页序号重编(给出一个"从上到下重新编号"的小检查:`grep -n 'data-ref="s' index.html` 核对序号连续)。
4. **多选/跨页**:引用块按页分组时逐块处理,每处独立 verify。

- [ ] **Step 3: 安装并确认 deck-editing 被扇出**

```bash
cd /home/fdse/ytest/deck-toolkit
bash install.sh >/dev/null 2>&1
ls ~/.claude/skills/deck-editing/SKILL.md ~/.claude/skills/deck-editing/references/edit-loop.md
grep '^name:' ~/.claude/skills/deck-editing/SKILL.md
```
Expected:两个文件都在;`name: deck-editing`。

- [ ] **Step 4: 提交**

```bash
cd /home/fdse/ytest/deck-toolkit
git add skills/deck-editing/
git commit -m "feat(deck-editing): skill to iterate on a built deck via picker reference blocks"
```

---

### Task 5: showcase-deck 接上 data-ref + 编辑回路

让生成 skill 知道要打 data-ref、并在"改已生成 deck"时走 deck-editing。

**Files:**
- Modify: `skills/showcase-deck/SKILL.md`

**Interfaces:**
- Consumes:data-ref 约定(Task 1)、deck-editing skill(Task 4)。

- [ ] **Step 1: 在 SKILL.md 的 workflow / reliability 段补两点**

用 Edit 给 `skills/showcase-deck/SKILL.md`:
- 在填模板那一步补一句:**给每个语义单元打 `data-ref`**(约定见 shared/references/deck-mechanics.md;section=`sN`、标题=`sN-title`、交互根=`sN-slug`、图=`sN-fig`),这样用户能点选让 AI 精确改。
- 加一句:**要在已生成 deck 上迭代改,用 `deck-editing` skill**(用户在 serve 里点选拷贝引用块粘回来)。

- [ ] **Step 2: 装好并确认 name 未破坏(parity 仍认)**

```bash
cd /home/fdse/ytest/deck-toolkit
bash install.sh >/dev/null 2>&1
grep '^name:' ~/.claude/skills/showcase-deck/SKILL.md
```
Expected:`name: showcase-deck`(只加了正文,没动 frontmatter name)。

- [ ] **Step 3: 提交**

```bash
cd /home/fdse/ytest/deck-toolkit
git add skills/showcase-deck/SKILL.md
git commit -m "docs(showcase-deck): stamp data-ref when building; point to deck-editing for iteration"
```

---

### Task 6: 收窄 parity 语义 + 端到端真跑验证

P1 有意改了模板(加 data-ref)与 serve.sh,`p0-baseline` 的"逐字节"对模板/脚本不再成立。把 parity 的零回归语义**收窄为"SKILL.md 内容 + references 不回归"**(模板/脚本的 P1 变更是有意的),并跑一遍完整用户路径。

**Files:**
- Modify: `tests/check-parity.sh`(把 assets/scripts 的比对改成"P1 有意变更"说明,保留 SKILL.md-除name + references 的零回归)

**Interfaces:**
- Consumes:P1 的模板/serve 变更。

- [ ] **Step 1: 看 P1 后 parity 对 assets/scripts 报什么**

```bash
cd /home/fdse/ytest/deck-toolkit
bash tests/check-parity.sh || true
```
Expected:`references` 与 `SKILL.md`(除 name)仍 `OK`;`assets`、`scripts`、`scripts permission bits` 可能 `FAIL`(模板加了 data-ref、serve.sh 重写)——这是**有意变更**,不是回归。

- [ ] **Step 2: 收窄 parity——assets/scripts 不再要求逐字节等于 p0-baseline**

用 Edit 改 `tests/check-parity.sh`:把 `cmp_path assets`、`cmp_path scripts` 与权限位那段,替换为对 **P1 有意变更**的说明性检查——改为验证"内容零回归"的稳定子集:references 逐字节 + SKILL.md(除 name)+ **模板仍是合法单文件**(`assets/deck-template.html` 存在且 `verify.sh` 结构检查不因 P1 变更而崩)。具体:
```bash
# references content must never regress (content-source-agnostic base):
cmp_path references
# assets/scripts legitimately changed in P1 (data-ref anchors; injecting serve.sh).
# Assert they still exist and the template still parses as a single file rather
# than byte-equality to p0-baseline.
for f in assets/deck-template.html scripts/serve.sh scripts/verify.sh; do
  [ -f "$INSTALLED/$f" ] && echo "  OK  $f present" || { echo " FAIL: $f missing"; fail=1; }
done
```
(保留 SKILL.md-除name 与 references 的逐字节零回归;删掉 assets/scripts 的逐字节与权限位比对,并在脚本头注释里写明"P1 起模板/脚本按 P1 spec 有意演进"。)

- [ ] **Step 3: 跑 parity,确认 PASS(新语义)**

```bash
cd /home/fdse/ytest/deck-toolkit
bash install.sh >/dev/null 2>&1
bash tests/check-parity.sh; echo "exit=$?"
```
Expected:references / SKILL.md OK,assets/scripts present,`RESULT: PASS`,exit 0。

- [ ] **Step 4: 端到端真跑(项目铁律 — 不可省)**

```bash
cd /home/fdse/ytest/deck-toolkit
rm -rf /tmp/p1e2e && mkdir -p /tmp/p1e2e/showcase_deck
cp shared/assets/deck-template.html /tmp/p1e2e/showcase_deck/index.html
bash ~/.claude/skills/showcase-deck/scripts/serve.sh /tmp/p1e2e/showcase_deck/index.html 8782 &
sleep 1
echo "① 注入 picker+热更新:" ; curl -s http://127.0.0.1:8782/index.html | grep -c '__deckPicker'
echo "② deck 文件本身不含 picker(交付干净):" ; grep -c '__deckPicker' /tmp/p1e2e/showcase_deck/index.html
echo "③ 模拟一次 data-ref 定位改(取一个存在的 ref):"
REF=$(grep -oE 'data-ref="s[0-9][^"]*"' /tmp/p1e2e/showcase_deck/index.html | head -1)
echo "   选中的 ref = $REF ; grep 命中次数:"; grep -c "$REF" /tmp/p1e2e/showcase_deck/index.html
kill %1 2>/dev/null || true
```
Expected:① `1`(注入了);② `0`(**落盘文件干净、不含 picker**——注入而非烤入的证明);③ ref 唯一(命中 1 次,可精确定位)。

- [ ] **Step 5: 浏览器肉眼验(必须真看)**

起 `serve.sh` 指向 `/tmp/p1e2e/showcase_deck/index.html`(0.0.0.0),把 LAN URL 给用户;确认:点 `📍 pick` → hover 高亮 → 点一个元素 → 剪贴板/降级框出现正确引用块(带 `data-ref`);暗/暖主题都看一眼。**这一步由控制者或用户在真浏览器完成,不能用 curl 代替。**

- [ ] **Step 6: 提交**

```bash
cd /home/fdse/ytest/deck-toolkit
git add tests/check-parity.sh
git commit -m "test(parity): narrow zero-regression to SKILL.md+references; template/serve intentionally evolve in P1"
```

---

## 验收(P1 Definition of Done)

- 模板每个 slide/交互根都有 `data-ref`;`verify.sh` 覆盖率检查通过。
- `serve.sh` 服务时注入 picker + 热更新;**deck 落盘文件不含二者**(端到端 Step 4 ② = 0)。
- picker:点选(shift 多选)→ 生成引用块 → 复制(非安全上下文降级到手动框);浏览器肉眼验过(Step 5)。
- 热更新:改文件 → mtime 变 → 浏览器自动刷新。
- `deck-editing` skill 装好(`name: deck-editing`);`showcase-deck` SKILL.md 已接上 data-ref + 编辑回路。
- `bash tests/check-parity.sh` PASS(新语义:SKILL.md 除 name + references 零回归;模板/脚本按 P1 有意演进)。

## 不在本计划内(留 P2)

- `paper-deck` skill + 论文导图脚本(P2 会同样打 data-ref、复用 deck-editing 与注入式 serve)。
- 多后端适配(独立面板 / OpenCode / 裸 API)。
