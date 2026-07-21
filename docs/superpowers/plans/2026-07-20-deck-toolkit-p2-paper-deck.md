# deck-toolkit P2 — paper-deck 技能 + 论文导图脚本 实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 新增 `paper-deck` 技能,把一篇论文 PDF 讲成单文件 HTML deck;方法图重画成交互、结果图用轻量脚本抽原图内联——共用现有 `shared/` 底座,与 `showcase-deck` 并列。

**Architecture:** 复用 P0 建成的 `shared/` 底座(模板 / 视觉 / 交互库 / verify / serve / 注入式 picker)。P2 只加三样内容源专属的东西:一个无重依赖的论文导图脚本 `shared/scripts/extract-pdf-figures.sh`(poppler 渲染+可选裁剪→base64 内联),以及 `skills/paper-deck/` 下的一个 SKILL.md + 两份"论文的魂"reference。`install.sh` 已泛化到 `skills/*`,新技能自动被扇出安装,无需改动。

**Tech Stack:** bash + poppler-utils(`pdftoppm` / `pdfinfo`,已装 v0.86.1)、base64;文档为 Markdown;测试夹具用 ghostscript(已装 9.50)现生成、ImageMagick(`identify`,已装)做尺寸断言;技能被 Claude Code / Codex 以 SKILL.md 加载。

## Global Constraints

- **单文件铁律**:deck 必须是一个自洽 HTML,可单独邮件发送。脚本产出的图必须是 `data:` URI 内联,`verify.sh` 的 "no sibling asset files" 只放行 `data:` 开头的 `src`。
- **无重依赖**:不引入 PDF 解析栈(pypdf / pymupdf / pdf2image 等)。只用系统 poppler + base64;缺失时响亮报错并指路"改手画 inline SVG"。
- **底座唯一事实源**:模板 / 视觉 / 交互库 / verify.sh / serve.sh 一律不复制、不改;paper-deck 只写自己独有的魂与流程,底座相关一律引用 `shared/`(装好后是技能目录下的平铺 `references/*`、`scripts/*`、`assets/*`)。
- **语言规则**:reference / SKILL / 本计划正文用中文;代码、命令、路径、commit message、data-ref 命名用英文。
- **诚实分级(论文语境)**:三档 = **论文声称 / 已复现 / 存疑**(不是 shipped/partial/planned)。
- **输出位置**:paper-deck 的 deck 固定构建到项目根的 **`paper_deck/index.html`**(与 showcase-deck 的 `showcase_deck/index.html` 区分,避免同目录互相覆盖)。因此 verify/serve 都要显式传路径:`scripts/verify.sh paper_deck/index.html`、`scripts/serve.sh paper_deck/index.html`。
- **data-ref 约定**:沿用 P1 的 `sN` / `sN-title` / `sN-{slug}` / `sN-fig`;抽出的结果图用 `sN-fig`。
- **提交纪律**:显式路径 `git add <path...>` + `git commit -m "..." -- <path...>`(共享 checkout 防串味);`git commit` 的 `-m` 必须在 `--` 之前。

---

## 文件结构

- **Create** `shared/scripts/extract-pdf-figures.sh` — 论文导图脚本(唯一的真代码)。输入 PDF + 页码(+ 可选裁剪框)→ poppler 渲染 → base64 → 打印一段自洽 `<figure class="apx-fig">` 内联片段到 stdout。
- **Create** `tests/extract-pdf-figures.test.sh` — 该脚本的行为测试;运行时用 gs 现生成一个 2 页夹具 PDF,断言片段结构、data: URI、裁剪尺寸、坏输入报错。
- **Create** `skills/paper-deck/SKILL.md` — 新技能入口;镜像 showcase-deck 的质量哲学,换成论文语境,写清方案 C 图表处理与 PDF 摄入方式。
- **Create** `skills/paper-deck/references/extract-the-paper-soul.md` — "论文的魂 → Paper Brief"(镜像 extract-the-soul,换论文阅读顺序、Brief 字段、论文诚实分级、术语忠实)。
- **Create** `skills/paper-deck/references/paper-narrative.md` — 论文叙事骨架(镜像 narrative-spine,spine = 动机→缺口→idea→方法→结果→局限)。
- **Create** `tests/check-paper-deck.sh` — 安装/自洽校验:隔离 HOME 跑 `install.sh`,断言 paper-deck 扇平、自洽、5 份 reference、脚本可执行;并回归断言 showcase-deck 仍正确安装。
- **不改**:`install.sh`(已泛化)、`shared/scripts/verify.sh`(方法图当 apx-fig / 交互,floors 与内容源无关)、`shared/scripts/serve.sh`、`skills/deck-editing/*`、`skills/showcase-deck/*`、模板与视觉/交互库。

---

## Task 1: 论文导图脚本 `extract-pdf-figures.sh`

**Files:**
- Create: `shared/scripts/extract-pdf-figures.sh`
- Test: `tests/extract-pdf-figures.test.sh`

**Interfaces:**
- Consumes: 系统 `pdftoppm` / `pdfinfo`(poppler)、`base64`;测试另需 `gs`、`identify`(ImageMagick)。
- Produces: CLI `extract-pdf-figures.sh <pdf> <page> [--crop Xf,Yf,Wf,Hf] [--dpi N] [--id REF] [--caption TXT] [--out PNG]`;成功时向 **stdout** 打印一段
  ```html
  <figure class="apx-fig" data-ref="<REF>">
    <img alt="..." style="max-width:100%;height:auto" src="data:image/png;base64,...."/>
    <figcaption class="apx-cap">...</figcaption>   <!-- 仅当给了 --caption -->
  </figure>
  ```
  失败(缺工具 / 文件不存在 / 页码非法 / 裁剪算成 0)时向 **stderr** 打印 `extract-pdf-figures: <原因>` 并以非 0 退出。`--crop` 为页面**分数** `left,top,width,height`(各 0..1),脚本按 `pdfinfo` 页尺寸 × dpi 折算像素喂给 `pdftoppm -x -y -W -H`。默认整页,默认 dpi=150,默认 `--id fig-p<page>`。

- [ ] **Step 1: 先写失败测试**

创建 `tests/extract-pdf-figures.test.sh`:

```bash
#!/usr/bin/env bash
# Behaviour test for extract-pdf-figures.sh. Generates its own 2-page fixture PDF
# with ghostscript (no committed binary, no dependency on any real paper), then
# asserts the emitted snippet is a single-file-safe inline figure.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$HERE/../shared/scripts/extract-pdf-figures.sh"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
fail=0
ok(){ echo "  OK  $1"; }
bad(){ echo " FAIL $1"; fail=1; }

# --- build a deterministic 2-page letter PDF via ghostscript ---
cat > "$TMP/fixture.ps" <<'PS'
/Helvetica findfont 48 scalefont setfont
72 700 moveto (Figure One page) show
showpage
/Helvetica findfont 48 scalefont setfont
72 700 moveto (Figure Two page) show
showpage
PS
gs -q -dNOPAUSE -dBATCH -sDEVICE=pdfwrite -sOutputFile="$TMP/sample.pdf" "$TMP/fixture.ps" \
  || { echo "cannot build fixture PDF (ghostscript?)"; exit 2; }

# --- T1: whole page → inline apx-fig snippet, single-file safe ---
out="$(bash "$SCRIPT" "$TMP/sample.pdf" 1)" || bad "T1 exited non-zero"
echo "$out" | grep -q 'class="apx-fig"'            && ok "T1 apx-fig wrapper"      || bad "T1 no apx-fig wrapper"
echo "$out" | grep -q 'src="data:image/png;base64,' && ok "T1 inline data URI"      || bad "T1 no data URI"
# no <img src=...> pointing at a file: every src must start with data:
if echo "$out" | grep -oE 'src="[^"]*"' | grep -vq '^src="data:'; then
  bad "T1 a non-data src leaked (breaks single-file rule)"; else ok "T1 all src are data:"; fi
b64len=$(echo "$out" | grep -oE 'base64,[A-Za-z0-9+/=]+' | head -1 | wc -c)
[ "$b64len" -gt 500 ] && ok "T1 payload non-trivial ($b64len chars)" || bad "T1 payload too small ($b64len)"

# --- T2: crop + --out + --id + --caption ---
out2="$(bash "$SCRIPT" "$TMP/sample.pdf" 1 --crop 0,0,0.5,0.5 --out "$TMP/crop.png" --id s7-fig --caption "结果对比")" \
  || bad "T2 exited non-zero"
echo "$out2" | grep -q 'data-ref="s7-fig"' && ok "T2 honours --id"      || bad "T2 --id ignored"
echo "$out2" | grep -q '结果对比'           && ok "T2 honours --caption" || bad "T2 --caption ignored"
[ -f "$TMP/crop.png" ] && file "$TMP/crop.png" | grep -qi png && ok "T2 wrote a PNG via --out" || bad "T2 --out png missing/not png"
# full page vs cropped width: crop(0.5) must be clearly narrower than full
full_w=$(bash "$SCRIPT" "$TMP/sample.pdf" 1 --out "$TMP/full.png" >/dev/null; identify -format '%w' "$TMP/full.png")
crop_w=$(identify -format '%w' "$TMP/crop.png")
[ "$crop_w" -lt "$full_w" ] && ok "T2 crop narrower ($crop_w < $full_w)" || bad "T2 crop not narrower ($crop_w vs $full_w)"

# --- T3: bad input fails loudly, non-zero ---
if bash "$SCRIPT" "$TMP/nope.pdf" 1 >/dev/null 2>"$TMP/err"; then
  bad "T3 missing PDF should have failed"; else
  grep -qi 'no such PDF' "$TMP/err" && ok "T3 clear error on missing PDF" || bad "T3 wrong/empty error message"; fi

echo "RESULT: $([ $fail -eq 0 ] && echo PASS || echo ISSUES)"
exit $fail
```

- [ ] **Step 2: 运行测试确认失败**

Run: `chmod +x tests/extract-pdf-figures.test.sh && bash tests/extract-pdf-figures.test.sh; echo "exit=$?"`
Expected: FAIL — 脚本还不存在,T1 就 `exited non-zero`,`RESULT: ISSUES`,`exit=1`。

- [ ] **Step 3: 写脚本实现**

创建 `shared/scripts/extract-pdf-figures.sh`:

```bash
#!/usr/bin/env bash
# Extract a figure from a paper PDF as a SELF-CONTAINED inline <img> snippet.
#
# paper-deck's figure strategy is hybrid: the *method* figure gets redrawn as a
# live interaction (that's the deck's soul), but result curves / dense experiment
# plots are lifted FAITHFULLY from the original — redrawing them loses fidelity.
# This script does the lifting: render (and optionally crop) one PDF page to PNG
# with poppler, then base64-inline it so the deck stays a single mailable file
# (verify.sh's "no sibling assets" rule allows a data: URI, forbids <img src=file>).
#
# Usage:
#   extract-pdf-figures.sh <pdf> <page> [--crop Xf,Yf,Wf,Hf] [--dpi N]
#                          [--id DATA_REF] [--caption TEXT] [--out PNG]
#
#   <page>          1-based page number (read the PDF first to find the figure).
#   --crop f,f,f,f  Crop box as FRACTIONS of the page, 0..1: left,top,width,height
#                   (e.g. 0.08,0.60,0.84,0.30 = a wide strip in the lower half).
#                   Fractions are what you can eyeball from reading the page; the
#                   script converts them to pixels. Omit to take the whole page.
#   --dpi N         Render resolution (default 150; bump to 220 for tiny text).
#   --id REF        data-ref for the emitted wrapper (default: fig-p<page>).
#   --caption TXT   <figcaption> text (default: none).
#   --out PNG       Also write the raw PNG here (for eyeballing the crop).
set -euo pipefail
die(){ echo "extract-pdf-figures: $*" >&2; exit 1; }
command -v pdftoppm >/dev/null || die "pdftoppm (poppler-utils) not found — install poppler, or hand-author an inline SVG of the figure instead."
command -v pdfinfo  >/dev/null || die "pdfinfo (poppler-utils) not found."

CROP=""; DPI=150; ID=""; CAPTION=""; OUT=""; POS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --crop) CROP="${2:-}"; shift 2;;
    --dpi) DPI="${2:-}"; shift 2;;
    --id) ID="${2:-}"; shift 2;;
    --caption) CAPTION="${2:-}"; shift 2;;
    --out) OUT="${2:-}"; shift 2;;
    -*) die "unknown option: $1";;
    *) POS+=("$1"); shift;;
  esac
done
PDF="${POS[0]:-}"; PAGE="${POS[1]:-}"
[ -n "$PDF" ] && [ -f "$PDF" ] || die "no such PDF: '${PDF:-}'  (usage: extract-pdf-figures.sh <pdf> <page> [opts])"
[ -n "$PAGE" ] || die "page number required (1-based)"
case "$PAGE" in ''|*[!0-9]*) die "page must be a positive integer, got '$PAGE'";; esac
[ -n "$ID" ] || ID="fig-p$PAGE"

# page size in points (robust to both pdfinfo forms: "Page size:" and "Page  N size:")
line="$(pdfinfo -f "$PAGE" -l "$PAGE" "$PDF" 2>/dev/null | grep -m1 'size:')" || true
[ -n "$line" ] || die "could not read page $PAGE (out of range?)"
ptsW="$(echo "$line" | sed -E 's/.*size:[[:space:]]*([0-9.]+)[[:space:]]*x[[:space:]]*([0-9.]+).*/\1/')"
ptsH="$(echo "$line" | sed -E 's/.*size:[[:space:]]*([0-9.]+)[[:space:]]*x[[:space:]]*([0-9.]+).*/\2/')"
[ -n "$ptsW" ] && [ -n "$ptsH" ] || die "could not parse page size from: $line"
pxW="$(awk -v w="$ptsW" -v d="$DPI" 'BEGIN{printf "%d", w/72*d}')"
pxH="$(awk -v h="$ptsH" -v d="$DPI" 'BEGIN{printf "%d", h/72*d}')"

crop_args=()
if [ -n "$CROP" ]; then
  IFS=, read -r fx fy fw fh <<<"$CROP"
  X="$(awk -v v="${fx:-0}" -v p="$pxW" 'BEGIN{printf "%d", v*p}')"
  Y="$(awk -v v="${fy:-0}" -v p="$pxH" 'BEGIN{printf "%d", v*p}')"
  W="$(awk -v v="${fw:-0}" -v p="$pxW" 'BEGIN{printf "%d", v*p}')"
  H="$(awk -v v="${fh:-0}" -v p="$pxH" 'BEGIN{printf "%d", v*p}')"
  { [ "$W" -gt 0 ] && [ "$H" -gt 0 ]; } || die "crop width/height computed to 0 — check --crop fractions '$CROP'"
  crop_args=(-x "$X" -y "$Y" -W "$W" -H "$H")
fi

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
pdftoppm -png -singlefile -r "$DPI" -f "$PAGE" -l "$PAGE" "${crop_args[@]}" "$PDF" "$tmp/fig" \
  || die "pdftoppm failed to render page $PAGE"
png="$tmp/fig.png"
[ -f "$png" ] || die "pdftoppm produced no PNG"
[ -n "$OUT" ] && cp "$png" "$OUT"

b64="$(base64 -w0 "$png" 2>/dev/null || base64 "$png" | tr -d '\n')"
alt="figure from page $PAGE"; [ -n "$CAPTION" ] && alt="$alt — $CAPTION"
printf '<figure class="apx-fig" data-ref="%s">\n' "$ID"
printf '  <img alt="%s" style="max-width:100%%;height:auto" src="data:image/png;base64,%s"/>\n' "$alt" "$b64"
[ -n "$CAPTION" ] && printf '  <figcaption class="apx-cap">%s</figcaption>\n' "$CAPTION"
printf '</figure>\n'
```

- [ ] **Step 4: 赋可执行位并运行测试确认通过**

Run: `chmod +x shared/scripts/extract-pdf-figures.sh && bash tests/extract-pdf-figures.test.sh; echo "exit=$?"`
Expected: 全部 `OK`,`RESULT: PASS`,`exit=0`。

- [ ] **Step 5: 提交**

```bash
git add shared/scripts/extract-pdf-figures.sh tests/extract-pdf-figures.test.sh
git commit -m "feat(shared): extract-pdf-figures.sh — lift a PDF figure as an inline data-URI apx-fig" -- shared/scripts/extract-pdf-figures.sh tests/extract-pdf-figures.test.sh
```

---

## Task 2: `extract-the-paper-soul.md`(论文的魂 → Paper Brief)

**Files:**
- Create: `skills/paper-deck/references/extract-the-paper-soul.md`

**Interfaces:**
- Consumes: 无(纯文档)。镜像 `skills/showcase-deck/references/extract-the-soul.md` 的结构与深度(约 70 行),换成论文语境。
- Produces: 被 `skills/paper-deck/SKILL.md` 第 1 步引用的"魂"参考;定义 **Paper Brief** 字段名(下游 SKILL 与 paper-narrative 会引用同名字段:RESEARCH QUESTION / GAP / CORE IDEA / METHOD IN 3 STEPS / KEY RESULTS / AUDIENCE / VOCABULARY / HONESTY)。

- [ ] **Step 1: 写文档**

创建 `skills/paper-deck/references/extract-the-paper-soul.md`,必须包含以下小节与**确切内容**:

1. **开篇**:deck 好坏全在这一步;动 HTML 前先产出 **Paper Brief** 并与用户确认。**PDF 用 Claude 的 Read 工具直接读**(原生支持文字 + 图),不引入解析栈。
2. **阅读顺序(信号从高到低)**:① 摘要 + 引言(问题、缺口、贡献声称——论文自己的框定);② 方法 / 途径章节(核心 idea 与机制——这将成为**交互**);③ 结果 / 实验(真正被展示 vs 被声称的,表与图);④ 相关工作(读者已接受的基线 + 新在哪);⑤ 局限 / 有效性威胁 / 结论(诚实边界);⑥ 图与图注(常是通往方法与结果的最快路径)。若用户点名某节,先读它并让它定锚。
3. **The Paper Brief(每个字段都要有证据,标注来自哪节/图/表)**,用代码块列出字段:
   ```
   RESEARCH QUESTION (1 句):这篇论文要回答的问题,用论文自己的话。
   GAP:现有做法在哪失败——张力所在(相关工作/引言的"however…")。
   CORE IDEA / CONTRIBUTION (1 句能复述):听众只记住一句时,是这句。
   METHOD IN 3 STEPS:机制怎么 work 的三步——交互的候选(→ 见 paper-narrative 的 show-then-name)。
   KEY RESULTS:支撑主张的 1–3 个数字/图——这些是要"抽原图"的结果图(→ extract-pdf-figures.sh)。
   AUDIENCE:讲给谁(领域内同行 / 跨领域 / 领导)——定语域。
   VOCABULARY:论文自己的 5–12 个核心术语,逐字照抄 + 一句白话注解。这是全 deck 唯一可用词表。
   HONESTY(分级,带证据):论文声称 / 已复现 / 存疑 各列条目 + 依据。
   ```
   每个字段都喂一个具体产物:RESEARCH QUESTION→封面与开场;METHOD IN 3 STEPS→第一个交互;KEY RESULTS→结果图(抽原图);VOCABULARY→每页词表白名单;HONESTY→现状/局限页。喂不到任何东西的字段就别加。
4. **说论文自己的语言(不可谈判)**:只用论文的术语,逐字照抄(方法名、模块名、指标名、数据集名);对外行不透明的真术语要**注解而非替换**;不生造大词/伞形词把它包装得比论文更宏大;casing/中英混用照论文。VOCABULARY 字段就是白名单——要放上页的词若无法回溯到论文,删。
5. **诚实分级(论文语境,不可谈判)**——一张表:

   | 标签 | 含义 | 证据门槛 |
   |------|------|----------|
   | **论文声称 / claimed** | 论文断言但未独立核验 | 正文陈述即可,但要标"这是声称" |
   | **已复现 / reproduced** | 论文自己的实验里被展示 | 有表/图/消融支撑,指得出具体图表号 |
   | **存疑 / open** | 有告诫、有效性威胁、或未被证 | 局限节 / 小样本 / 窄设定 |

   规则:别把"论文声称"当"已复现";别夸大数字(SOTA、百分点、加速比);每条主张都指得出图/表/节;声称密集的页放一句诚实脚注(如"越往右越是声称而非已验证")。
6. **常见失败**:复述摘要当讲解;过度声称 SOTA / 忽略局限;编造论文没给的数字;用生造大词代替论文自己的术语;把"方法能 work"和"实验证明有效"混为一谈。

- [ ] **Step 2: 自检**

Run: `wc -l skills/paper-deck/references/extract-the-paper-soul.md && grep -c '论文声称\|已复现\|存疑' skills/paper-deck/references/extract-the-paper-soul.md && grep -q 'RESEARCH QUESTION' skills/paper-deck/references/extract-the-paper-soul.md && grep -q 'METHOD IN 3 STEPS' skills/paper-deck/references/extract-the-paper-soul.md && echo OK`
Expected: 行数 ≈ 60–90;诚实三档词至少出现 3 次;字段名命中;打印 `OK`。人工再通读一遍:每节都在讲论文(不是代码仓),术语忠实与诚实分级规则完整。

- [ ] **Step 3: 提交**

```bash
git add skills/paper-deck/references/extract-the-paper-soul.md
git commit -m "docs(paper-deck): extract-the-paper-soul reference — Paper Brief + paper-context honesty grading" -- skills/paper-deck/references/extract-the-paper-soul.md
```

---

## Task 3: `paper-narrative.md`(论文叙事骨架)

**Files:**
- Create: `skills/paper-deck/references/paper-narrative.md`

**Interfaces:**
- Consumes: Task 2 的 Paper Brief 字段名。镜像 `skills/showcase-deck/references/narrative-spine.md`(约 60 行)。
- Produces: paper 版 spine 定义,SKILL 第 2 步引用;明确 spine = **动机 → 缺口 → idea → 方法 → 结果 → takeaway/局限**,压成 4–6 个 nav 词写进模板 `MAINLINE`。

- [ ] **Step 1: 写文档**

创建 `skills/paper-deck/references/paper-narrative.md`,必须包含:

1. **推导主线,别照单点菜**:主线是**推导出来的输出**,不是菜单项。论文的 spine 是 SCQA 的论文对应物:**动机(为何做)→ 缺口(现有为何不够)→ idea(一句话核心贡献)→ 方法(怎么 work)→ 结果(证据)→ takeaway/局限(诚实边界)**。像 SCQA 一样**结论先行**:把 CORE IDEA / CONTRIBUTION 摆在前面,再回头挣它。
2. **压成 nav**:把 spine 压成 **4–6 个读起来成一句话的 nav 词**,写进模板脚本顶部的 `MAINLINE` 数组(一处改、全 deck 跟随;每页用 `data-sec` 声明所属段、高亮自动)。给一个示例词组:`问题 · 缺口 · 我们的做法 · 看它跑 · 结果 · 局限`——并说明**这是某篇论文的答案、不是格式**,你要写你 SCQA 实际推出来的那组。
3. **测试**:一遍听下来,听众能否复述"贡献是什么 + 为何是新的"?不能就简化。
4. **Show, then name**:把**方法交互**放在前面(紧接缺口之后)——人先看见机制一步步动、才接受形式化记号。这是论文 deck 的高光顺序。
5. **推导示例表**(识别形状、别照抄):

   | 推出的 spine | 产生它的情境 |
   |-------------|-------------|
   | `问题 · 缺口 · idea · 方法 · 结果 · 局限` | 标准实证论文,张力在缺口,证据在结果 |
   | `idea · 为何新 · 怎么 work · 证据` | 领域已知问题,贡献本身就是钩子,直接亮 idea |
   | `动机 · 方法 · 消融 · 何时失效` | 方法论文,卖点是机制与边界条件 |

   三个都不合就写你实际推出来的那个。
6. **只用 nav 指路,别加转场**(踩过的坑,与 narrative-spine 同款反clutter铁律):不插转场句、不做 agenda 页;真需要一句框定就折进那页 lede,别新增元素。主线靠"顺序 + nav 高亮"被**感觉到**,不靠插入文字被**念出来**。
7. **方法图 vs 结果图的分工**(交叉引用图表处理):**方法/框架图 → 主线上的交互**(要听众**理解**机制);**结果曲线/密集实验图 → 抽原图**(要听众**信任**证据),放结果/附录。判据:想让人**懂**的重画成交互,想让人**信**的忠实抽原图。
8. **故事 vs 附录**:主线用白话(混合听众);形式化证明、完整实验表、超参、复杂符号推到清晰隔开的技术附录(自带 nav 词,如 `技术细节`)。

- [ ] **Step 2: 自检**

Run: `wc -l skills/paper-deck/references/paper-narrative.md && grep -q '动机' skills/paper-deck/references/paper-narrative.md && grep -q 'MAINLINE' skills/paper-deck/references/paper-narrative.md && grep -q 'Show, then name\|show-then-name\|show, then name' skills/paper-deck/references/paper-narrative.md && echo OK`
Expected: 行数 ≈ 50–80;spine 词、`MAINLINE`、show-then-name 命中;`OK`。人工通读:反clutter铁律与方法/结果分工都在。

- [ ] **Step 3: 提交**

```bash
git add skills/paper-deck/references/paper-narrative.md
git commit -m "docs(paper-deck): paper-narrative reference — motivation→gap→idea→method→results→limits spine" -- skills/paper-deck/references/paper-narrative.md
```

---

## Task 4: `paper-deck/SKILL.md`(技能入口)

**Files:**
- Create: `skills/paper-deck/SKILL.md`

**Interfaces:**
- Consumes: Task 2/3 的两份 reference(装好后平铺为 `references/extract-the-paper-soul.md`、`references/paper-narrative.md`);shared 底座平铺后的 `references/{visual-system,content-logic,deck-mechanics}.md`、`assets/{deck-template.html,interaction-patterns.html}`、`scripts/{verify.sh,serve.sh,extract-pdf-figures.sh}`。
- Produces: `name: paper-deck` 的 SKILL,被 check-paper-deck.sh(Task 5)断言。

- [ ] **Step 1: 写 SKILL.md**

创建 `skills/paper-deck/SKILL.md`。以 `skills/showcase-deck/SKILL.md` 为骨架,逐节改写成论文语境,必须包含:

- **frontmatter**:
  ```
  ---
  name: paper-deck
  description: Use when someone wants to explain or present a research paper / PDF (their own or one they are reading) to an audience as a polished single-file HTML slide deck — motivation → gap → idea → method → results → limitations, with the method figure redrawn as a live interaction and result figures lifted faithfully from the PDF. Not a repo showcase (use showcase-deck), not a literal reproduction of the paper.
  ---
  ```
- **Overview / 核心原则**:把论文 PDF 讲成单文件 HTML deck。质量来自 (1) 论文的**魂**(问题、缺口、能复述的贡献、诚实的局限),(2) 听众能复述的**主线**,(3) 论文语境的**诚实分级**。视觉形态由 shared 模板一次性解决,不重推。**你不是把论文逐段搬成幻灯片,而是讲一个研究故事。**
- **When to use**:"讲讲这篇论文 / 做个论文讲解 / present this paper / 组会讲 paper / 我要介绍我这篇工作";**Not for**:代码仓介绍(用 showcase-deck)、论文逐字复现、单张图(用 drawio skill)。
- **The non-negotiables(DNA)**——镜像 showcase 的 9 条,换论文语境:① 魂先于页(先填 Paper Brief,Read 读 PDF)→`references/extract-the-paper-soul.md`;② 用论文自己的词(VOCABULARY 白名单)→ 同上;③ 推导唯一主线(动机→缺口→idea→方法→结果→局限,写进 `MAINLINE`)→`references/paper-narrative.md`;④ 只靠 nav 指路,不插转场/agenda;⑤ 断言-证据式标题 + Rule of One(标题是完整结论句,正文是它的视觉证据)→`references/content-logic.md`;⑥ 论文语境的激进诚实(**论文声称/已复现/存疑** 作可见标签,不编数字);⑦ 故事白话、形式化细节进附录;⑧ Show-then-name(方法交互放在形式化记号之前);⑨ 无 AI 味(沿用模板编辑系统)→`references/visual-system.md`。
- **The delivery floors(`scripts/verify.sh` 会挡)**——与 showcase 同一套 floors,措辞换论文:
  - 模板发的是洞不是设计(`PLACEHOLDER-REDRAW` 标记),逐个重画到这篇论文的真东西再删标记;任何残留 = FAIL。
  - **封面图**:一张 THIS paper 的静态肖像——核心 idea 的一图、或论文的 teaser 图。换成别的论文名还成立就是填充。
  - **≥2 个交互**(争取 3),形式各异:**方法图重画成分步交互**是天然的第一个,直接满足一个交互位。
  - **方法/架构被画出来**:drawio 工具链能用就用,不能用就手画 inline SVG;跳过才是失败。
  - **单文件**:无外部请求、无同级资源;抽出的结果图是 `data:` 内联,不是 `<img src=文件>`。
  - floors 不为凑数辩护:空洞 demo 比一张扎实静态页更糟;第二个真交互出不来就**把论文读得更透**(方法节、实验设定),别造假。
- **图表处理(方案 C)——论文 deck 的专属核心**(单独成节,显著):
  - **方法 / pipeline / 框架图 → 重画成交互**:讲论文的高光是"方法怎么 work",用 shared 交互库的六台机器做成一步步演。天然满足交互底线。
  - **结果曲线 / 密集实验图 / 定性样例 → 抽原图**:重画不划算且失真,用 `scripts/extract-pdf-figures.sh <pdf> <page> --crop L,T,W,H --id sN-fig --caption "..."`(分数裁剪,详见脚本头注),它直接吐一段 `data:` 内联的 `apx-fig` 片段,粘进模板附录/结果槽。忠实 > 重画。
  - **判据**:想让听众**理解**的(机制)→重画成交互;想让听众**信任**的(证据)→忠实抽原图。
- **PDF 摄入**:Claude 用 **Read 工具直接读 PDF**(原生文字+图),按"摘要/引言 → 方法 → 结果 → 局限"的优先级读;不引入任何 PDF 解析栈。
- **Workflow(7 步,镜像 showcase 但改论文)**:1 读 PDF 抽魂→写 Paper Brief(`references/extract-the-paper-soul.md`);2 推导 spine→压成 nav 词写进 `MAINLINE`(`references/paper-narrative.md` + `references/content-logic.md`);3 复制 `assets/deck-template.html` 到**项目根 `paper_deck/index.html`**(建目录),填内容、画封面图、每页断言式标题+单一视觉证据、**每个语义单元打 data-ref**(`sN`/`sN-title`/`sN-{slug}`/`sN-fig`,见 `references/deck-mechanics.md`);4 **把方法图做成 live 交互**(六台机器,`assets/interaction-patterns.html`)+ 第二个不同形式的交互;5 **抽结果图**:对每张要忠实呈现的结果图跑 `scripts/extract-pdf-figures.sh`,把吐出的 `apx-fig` 片段粘进 deck(data-ref 用 `sN-fig`);6 **自检+起服务**:`scripts/verify.sh paper_deck/index.html`(注意传路径),再**始终** `scripts/serve.sh paper_deck/index.html`(后台、绑 0.0.0.0)给用户内网 URL;7 **用 `deck-editing` 技能迭代**:注入的 picker 让用户点选任意元素、粘引用块回聊天,别为微调重建。
- **Quick reference 表**:魂/诚实/术语→extract-the-paper-soul;主线/nav→paper-narrative;每页逻辑→content-logic;视觉→visual-system;单文件/组件/主题/data-ref→deck-mechanics;可复制骨架→deck-template.html;交互画廊→interaction-patterns.html;**结果图抽原图→`scripts/extract-pdf-figures.sh`**;存哪+怎么预览→构建到 `paper_deck/index.html`,`verify.sh`/`serve.sh` 传该路径。
- **Reliability rules**:输出固定 `paper_deck/index.html`;已存在就**原地改不重写**;Write 工具建 HTML、每次改后验;bulk 前备份;真渲染页两主题验;**verify/serve 必须传 `paper_deck/index.html` 路径**(默认是 showcase 的路径)。
- **Common mistakes(红旗)**:复述摘要/逐段搬 → 回到抽魂;重写成熟 deck;把框架名(SCQA/动机-缺口…)显示在页上而非隐形塑形;topic-noun 标题+项目符号墙;一次性糊上整张密集实验图(该抽原图/分层);插转场/agenda;把"论文声称"当"已复现";形式化记号早于方法交互;生造大词代替论文术语;`<img src=文件>` 放 deck 旁(要 `data:` 内联);跳过方法图。

- [ ] **Step 2: 结构自检**

Run:
```bash
grep -q '^name: paper-deck$' skills/paper-deck/SKILL.md \
 && grep -q 'paper_deck/index.html' skills/paper-deck/SKILL.md \
 && grep -q 'extract-pdf-figures.sh' skills/paper-deck/SKILL.md \
 && grep -q '论文声称' skills/paper-deck/SKILL.md \
 && grep -q 'extract-the-paper-soul.md' skills/paper-deck/SKILL.md \
 && grep -q 'paper-narrative.md' skills/paper-deck/SKILL.md \
 && grep -q 'deck-editing' skills/paper-deck/SKILL.md \
 && echo "OK structural"
```
Expected: `OK structural`。人工通读:9 条 DNA、floors、方案 C、7 步 workflow 都在,且都在讲论文而非代码仓。

- [ ] **Step 3: 提交**

```bash
git add skills/paper-deck/SKILL.md
git commit -m "feat(paper-deck): SKILL.md — paper→deck skill (method figure as interaction, results lifted via extract-pdf-figures)" -- skills/paper-deck/SKILL.md
```

---

## Task 5: 安装/自洽校验 `check-paper-deck.sh`

**Files:**
- Create: `tests/check-paper-deck.sh`

**Interfaces:**
- Consumes: `install.sh`(泛化,已存在)、Task 1–4 的产物。用隔离 `HOME` 跑安装,不污染真实 `~/.claude/skills`。
- Produces: 一次运行断言 paper-deck 扇平自洽 + showcase-deck 回归,`RESULT: PASS` / 退出码。

- [ ] **Step 1: 写测试**

创建 `tests/check-paper-deck.sh`:

```bash
#!/usr/bin/env bash
# Fan-out install check for paper-deck (P2), plus a regression check that
# showcase-deck still installs correctly. Runs install.sh under an isolated HOME
# so the real ~/.claude/skills is never touched.
set -uo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMPH="$(mktemp -d)"; trap 'rm -rf "$TMPH"' EXIT
fail=0
ok(){ echo "  OK  $1"; }
bad(){ echo " FAIL $1"; fail=1; }

HOME="$TMPH" FORCE_CLAUDE=1 bash "$REPO/install.sh" >/dev/null 2>&1 || { echo "install.sh failed"; exit 2; }
BASE="$TMPH/.claude/skills"

check_skill(){  # $1 skill dir name; $2.. expected reference basenames (without .md)
  local name="$1"; shift
  local d="$BASE/$name"
  [ -f "$d/SKILL.md" ] && grep -q "^name: $name\$" "$d/SKILL.md" && ok "$name: SKILL.md name" || bad "$name: SKILL.md name != $name"
  [ ! -e "$d/shared" ] && ok "$name: no shared/ subdir (flat)" || bad "$name: shared/ leaked"
  for r in "$@"; do
    [ -f "$d/references/$r.md" ] && ok "$name: references/$r.md" || bad "$name: missing references/$r.md"
  done
  local n; n=$(ls "$d"/references/*.md 2>/dev/null | wc -l)
  [ "$n" -eq 5 ] && ok "$name: exactly 5 references" || bad "$name: $n references (want 5)"
  for s in verify.sh serve.sh extract-pdf-figures.sh; do
    [ -x "$d/scripts/$s" ] && ok "$name: scripts/$s +x" || bad "$name: scripts/$s missing or not +x"
  done
  for a in deck-template.html interaction-patterns.html picker.js; do
    [ -f "$d/assets/$a" ] && ok "$name: assets/$a" || bad "$name: missing assets/$a"
  done
}

echo "-- paper-deck (new in P2) --"
check_skill paper-deck extract-the-paper-soul paper-narrative visual-system content-logic deck-mechanics
# paper-deck must NOT carry showcase's soul refs
[ ! -e "$BASE/paper-deck/references/extract-the-soul.md" ] && ok "paper-deck: no showcase soul ref" || bad "paper-deck: leaked showcase ref"

echo "-- showcase-deck (regression) --"
check_skill showcase-deck extract-the-soul narrative-spine visual-system content-logic deck-mechanics

echo "RESULT: $([ $fail -eq 0 ] && echo PASS || echo ISSUES)"
exit $fail
```

- [ ] **Step 2: 运行确认通过**

Run: `chmod +x tests/check-paper-deck.sh && bash tests/check-paper-deck.sh; echo "exit=$?"`
Expected: 全 `OK`,`RESULT: PASS`,`exit=0`。(若 paper-deck 的 5 references 断言失败,通常是 Task 2/3 文件名或 SKILL name 不对——回查。)

- [ ] **Step 3: 提交**

```bash
git add tests/check-paper-deck.sh
git commit -m "test(paper-deck): fan-out install check + showcase-deck regression under isolated HOME" -- tests/check-paper-deck.sh
```

---

## Task 6:(验收,编排者手动执行——非盲跑 subagent)真实论文端到端

> 这是 spec 的 P2 验收铁律,需要读一篇真论文的判断力,由编排者在本会话交互完成,不交给盲跑 subagent。放在 Task 1–5 全绿之后。

**Files:**
- 临时:`/tmp/claude-1000/.../scratchpad/paper-e2e/paper_deck/index.html`(验收产物,不进仓)

- [ ] **Step 1: 装最新技能**

Run: `bash /home/fdse/ytest/deck-toolkit/install.sh`（装到真实 `~/.claude/skills`;新会话才加载,验收里直接照 SKILL 流程手动走即可)。

- [ ] **Step 2: 选一篇真论文,读 PDF 抽魂**

用真实论文,如 `/home/fdse/ytest/daxiu/ISSTA26__Design_Aware_Issue_Resolution (4).pdf` 或 `/home/fdse/ytest/daxiu/FSE26-PtrTrans-majorRevision.pdf`。用 Read 工具读摘要/引言/方法/结果/局限,填 Paper Brief。

- [ ] **Step 3: 按 paper-deck workflow 构建到 `paper_deck/index.html`**

在 scratchpad 建 `paper-e2e/`;复制 `~/.claude/skills/paper-deck/assets/deck-template.html` 到 `paper-e2e/paper_deck/index.html`;推 spine 写 `MAINLINE`;填页;**把方法图做成一个 live 交互** + 第二个不同形式交互;每个语义单元打 data-ref。

- [ ] **Step 4: 抽一张结果图内联**

Run: `~/.claude/skills/paper-deck/scripts/extract-pdf-figures.sh "<那篇PDF>" <结果图页码> --crop <L,T,W,H> --id s6-fig --caption "<图注>" --out /tmp/.../paper-e2e/_crop.png`
把 stdout 的 `apx-fig` 片段粘进 deck 的结果/附录槽;`--out` 的 PNG 用来眼校裁剪对不对(不进 deck)。

- [ ] **Step 5: verify + serve,眼校**

Run:
```bash
cd /tmp/.../paper-e2e && ~/.claude/skills/paper-deck/scripts/verify.sh paper_deck/index.html
~/.claude/skills/paper-deck/scripts/serve.sh paper_deck/index.html 8771   # 后台
```
**验收标准(全部满足)**:`verify.sh` 除 by-design 的 `PLACEHOLDER-REDRAW` 外全 PASS(占位必须都已重画删标记);**≥2 个交互**且其一是方法图重画成的分步交互;**≥1 张结果图**以 `data:` 内联(`grep -c 'data:image/png;base64' paper_deck/index.html` ≥1,且无 `<img src=` 指向文件);诚实标签(论文声称/已复现/存疑)出现;`curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:8771/index.html` = 200;两主题渲染正常;点选 picker 能取到 data-ref 引用块。

- [ ] **Step 6: 记录验收结论**

把验收结果(通过/发现的问题)回报用户;发现的缺陷回流成对 Task 1–5 的修复。此步无提交(验收产物是临时的)。

---

## Self-Review(对照 spec §5.3 / §5.1 / §7 / §9)

- **spec §5.3 paper-deck 两份 reference**:Task 2(extract-the-paper-soul)+ Task 3(paper-narrative)覆盖。✅
- **spec §5.3 PDF 摄入 = Read 原生读**:Task 4 SKILL "PDF 摄入"节 + Task 2 开篇。✅
- **spec §5.3 图表处理方案 C(方法图→交互 / 结果图→抽原图)**:Task 4 "图表处理(方案 C)"节 + Task 1 脚本 + Task 3 分工节。✅
- **spec §5.1 底座唯一事实源 / 脚本置于 shared/scripts**:`extract-pdf-figures.sh` 建在 `shared/scripts/`,install.sh 自动扇入所有技能(Task 5 断言每个技能都拿到它)。✅
- **spec §5.1 单文件铁律 = data: 内联**:Task 1 脚本吐 `data:` URI,测试 T1 断言无非-data src;验收 Step 5 复核。✅
- **spec §7 验收:一篇真论文跑通生成 + 方法图交互 + 结果图抽原图**:Task 6。✅
- **spec §7 依赖:P2 依赖 P0(底座就位)、独立于 P1**:只加内容源专属件 + 共享脚本,不改 P1 的 picker/serve/verify 逻辑。✅
- **spec §9 铁律:真跑用户路径(真论文完整链路)**:Task 6 是完整链路(生成→点选→抽图→verify→serve),非只跑脚本。✅
- **Placeholder 扫描**:所有 code step 均给出完整脚本/测试全文;doc task 给出逐节确切内容要求与固定表格。无 TBD/TODO。✅
- **类型/命名一致性**:Paper Brief 字段名(RESEARCH QUESTION / METHOD IN 3 STEPS / KEY RESULTS 等)在 Task 2 定义、Task 3/4 引用一致;脚本 flag(`--crop/--dpi/--id/--caption/--out`)与 data-ref `sN-fig` 在 Task 1/4/6 一致;5-references 断言在 Task 5 与 Task 2/3 的两份新 ref 对齐。✅

---

## Execution Handoff

计划已保存到 `docs/superpowers/plans/2026-07-20-deck-toolkit-p2-paper-deck.md`。两种执行方式:

1. **Subagent-Driven(推荐)** — 每个 Task 派新 subagent,Task 间双阶段审查;Task 1/5 是可测脚本、Task 2/3/4 是文档(自检 + 通读),Task 6 由编排者手动验收。
2. **Inline Execution** — 本会话内按 executing-plans 批量执行 + 检查点。
