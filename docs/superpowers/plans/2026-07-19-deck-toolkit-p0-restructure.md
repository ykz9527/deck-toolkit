# deck-toolkit P0:多 skill 重构 + 扇出安装(零回归)实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把单 skill 仓 `project-showcase-deck` 重构成 `deck-toolkit` 多 skill 源码仓(`shared/` 底座 + `skills/showcase-deck/`),并把 `install.sh` 改成从本地检出扇出安装,使装好的 `showcase-deck` 与今天**逐字节零回归**。

**Architecture:** 源码仓移到 `/home/fdse/ytest/deck-toolkit`,内部拆成"与内容源无关的底座 `shared/`"和"代码仓专属的 `skills/showcase-deck/`"。`install.sh` 把 `shared/*` 与 `skills/<名>/*` **合并平铺**复制进每个目标 skill 目录(`~/.claude/skills/<名>/` 和 `~/.agents/skills/<名>/`),因此装好的 skill 目录布局与今天完全一致——SKILL.md 里的相对路径无需改动。

**Tech Stack:** bash(install + 校验脚本)、git(`git mv` 保历史)、现有 `python3` 版 `verify.sh`。无新依赖。

## Global Constraints

- **零回归判据**:装好的 `~/.claude/skills/showcase-deck/` 中,SKILL 行为相关文件(`SKILL.md`、`references/*.md`、`assets/**`、`scripts/*.sh`)必须与重构前逐字节一致。以 git tag `p0-baseline` 为对照基线。
- **平铺安装模型**:install 后每个 skill 目录**自包含、无 `shared/` 子目录**——`shared/references/*` 与 `skills/<名>/references/*` 合并进 `<skill>/references/`,`shared/assets`→`<skill>/assets`,`shared/scripts`→`<skill>/scripts`。这是 SKILL.md 路径不用改的前提。
- **双平台**:`~/.claude/skills`(Claude Code)与 `~/.agents/skills`(Codex),沿用现有探测逻辑。
- **本轮只产出 `showcase-deck` 一个 skill**;`paper-deck`/`deck-editing` 留给 P1/P2,`skills/` 下暂只有 `showcase-deck/`。
- **语言**:文档中文,代码与 commit message 英文。
- **源码仓新家**:`/home/fdse/ytest/deck-toolkit`;远程 `origin` 不变(`github.com/ykz9527/project-showcase-deck`,仓名后续可另议,P0 不改远程)。

---

### Task 1: 提交现有打磨 WIP,打基线 tag

把仓里那套连贯但未提交的技能打磨(`SKILL.md`/`assets/deck-template.html`/`verify.sh`/`references/*`/`README.md` + 新增 `assets/interaction-patterns.html`)作为**独立一次提交**落地,并打 tag `p0-baseline` 作为零回归对照。**在仓的当前位置 `~/.claude/skills/project-showcase-deck` 执行**(尚未移动)。

**Files:**
- Modify(提交现有改动): `SKILL.md`, `README.md`, `assets/deck-template.html`, `references/{content-logic,deck-mechanics,extract-the-soul,narrative-spine,visual-system}.md`, `scripts/verify.sh`
- Add(提交新增): `assets/interaction-patterns.html`

- [ ] **Step 1: 确认只提交这批技能文件(不含本计划/spec 之外的意外文件)**

```bash
cd ~/.claude/skills/project-showcase-deck
git status -s
```
Expected: 列出上面 9 个 `M` + `assets/interaction-patterns.html` 为 `??`。`docs/superpowers/` 下的 spec/plan 若已单独提交则不出现在这里;若出现,**本任务不碰它们**。

- [ ] **Step 2: 显式暂存这批技能文件**

```bash
cd ~/.claude/skills/project-showcase-deck
git add SKILL.md README.md scripts/verify.sh \
  assets/deck-template.html assets/interaction-patterns.html \
  references/content-logic.md references/deck-mechanics.md \
  references/extract-the-soul.md references/narrative-spine.md references/visual-system.md
git diff --cached --stat
```
Expected: `--cached` 恰好列出这 10 个文件,无其它。

- [ ] **Step 3: 提交**

```bash
cd ~/.claude/skills/project-showcase-deck
git commit -m "feat(skill): mature polish — DNA + delivery floors, richer template & verify, interaction gallery"
```
Expected: 一次提交,10 files changed。

- [ ] **Step 4: 打零回归基线 tag**

```bash
cd ~/.claude/skills/project-showcase-deck
git tag p0-baseline
git rev-parse p0-baseline
```
Expected: 打印基线 commit 的 SHA。后续零回归对照都以 `p0-baseline` 为准。

- [ ] **Step 5: 确认工作树对技能文件已干净**

```bash
cd ~/.claude/skills/project-showcase-deck
git status -s -- SKILL.md references assets scripts
```
Expected: 空(这些路径无未提交改动)。`docs/` 下的 spec/plan 若未提交可暂留,不影响。

---

### Task 2: 把源码仓移到开发目录并改名 deck-toolkit

**Files:**
- Move: 整个仓目录 `~/.claude/skills/project-showcase-deck` → `/home/fdse/ytest/deck-toolkit`

**Interfaces:**
- Produces: 所有后续任务的工作目录 = `/home/fdse/ytest/deck-toolkit`(下称 `$REPO`)。

- [ ] **Step 1: 确保目标不存在,再整目录移动(.git 随之一起走)**

```bash
test ! -e /home/fdse/ytest/deck-toolkit || { echo "target exists, abort"; exit 1; }
mv ~/.claude/skills/project-showcase-deck /home/fdse/ytest/deck-toolkit
```
Expected: 无输出(成功);`~/.claude/skills/project-showcase-deck` 不再存在。

- [ ] **Step 2: 确认 git 历史与远程、tag 都完好**

```bash
cd /home/fdse/ytest/deck-toolkit
git status -s && git remote -v && git tag | grep p0-baseline && git log --oneline -3
```
Expected: 工作树基本干净;`origin` 指向 `ykz9527/project-showcase-deck`;`p0-baseline` 在;能看到 Task 1 的提交。

- [ ] **Step 3: 提交说明这是源码仓(占位,便于 mv 后有一次锚点提交)**

无代码改动,跳过提交。移动本身不产生 git 变更(仅路径变,git 不感知外部路径)。

---

### Task 3: 重构目录为 `shared/` + `skills/showcase-deck/`

用 `git mv` 保留历史,把"与内容源无关的底座"移入 `shared/`,把"代码仓专属的魂"移入 `skills/showcase-deck/`。

**Files(全部在 `$REPO=/home/fdse/ytest/deck-toolkit`):**
- Move: `assets/` → `shared/assets/`
- Move: `scripts/` → `shared/scripts/`
- Move: `references/{visual-system,deck-mechanics,content-logic}.md` → `shared/references/`
- Move: `references/{extract-the-soul,narrative-spine}.md` → `skills/showcase-deck/references/`
- Move: `SKILL.md` → `skills/showcase-deck/SKILL.md`
- Keep at root: `install.sh`, `README.md`, `LICENSE`, `docs/`

**Interfaces:**
- Produces 源码树布局:
  ```
  deck-toolkit/
  ├─ shared/{assets/, references/{visual-system,deck-mechanics,content-logic}.md, scripts/}
  ├─ skills/showcase-deck/{SKILL.md, references/{extract-the-soul,narrative-spine}.md}
  ├─ install.sh  README.md  LICENSE  docs/
  ```

- [ ] **Step 1: 建目标目录**

```bash
cd /home/fdse/ytest/deck-toolkit
mkdir -p shared/references skills/showcase-deck/references
```

- [ ] **Step 2: git mv 底座(内容源无关)**

```bash
cd /home/fdse/ytest/deck-toolkit
git mv assets shared/assets
git mv scripts shared/scripts
git mv references/visual-system.md   shared/references/visual-system.md
git mv references/deck-mechanics.md  shared/references/deck-mechanics.md
git mv references/content-logic.md   shared/references/content-logic.md
```

- [ ] **Step 3: git mv 代码仓专属的魂 + SKILL.md**

```bash
cd /home/fdse/ytest/deck-toolkit
git mv references/extract-the-soul.md skills/showcase-deck/references/extract-the-soul.md
git mv references/narrative-spine.md  skills/showcase-deck/references/narrative-spine.md
git mv SKILL.md skills/showcase-deck/SKILL.md
rmdir references 2>/dev/null || true
```

- [ ] **Step 4: 核对布局与"文件无遗漏"**

```bash
cd /home/fdse/ytest/deck-toolkit
find shared skills -type f | sort
```
Expected(至少包含):
```
shared/assets/deck-template.html
shared/assets/interaction-patterns.html
shared/assets/img/sample-deck.svg
shared/assets/img/workflow.svg
shared/references/content-logic.md
shared/references/deck-mechanics.md
shared/references/visual-system.md
shared/scripts/serve.sh
shared/scripts/verify.sh
skills/showcase-deck/SKILL.md
skills/showcase-deck/references/extract-the-soul.md
skills/showcase-deck/references/narrative-spine.md
```

- [ ] **Step 5: 提交**

```bash
cd /home/fdse/ytest/deck-toolkit
git add -A
git commit -m "refactor: split into shared/ core + skills/showcase-deck/ source layout"
```
Expected: 一次提交,全部以 rename 记录(`git show --stat` 显示 `renamed:`)。

---

### Task 4: 把 install.sh 改写为本地扇出安装

装好的 skill 目录必须与 `p0-baseline` 的仓根**平铺一致**:`SKILL.md` + `references/{5 个 md}` + `assets/**` + `scripts/*`。install 从**脚本自身所在的仓目录**读取源。

**Files:**
- Rewrite: `/home/fdse/ytest/deck-toolkit/install.sh`
- Test: `/home/fdse/ytest/deck-toolkit/tests/check-parity.sh`(Task 5 建)

**Interfaces:**
- Produces: 命令 `bash install.sh` → 在检测到的每个平台目录下,为 `skills/*` 每个 skill 生成一个自包含目录 `<base>/<name>/`。

- [ ] **Step 1: 写失败测试(先手工验证扇出后的目标目录布局)**

先不写脚本文件,用一句命令表达"期望":装完后 `~/.claude/skills/showcase-deck/references/` 应含 5 个 md。此刻它还不存在,预期失败:

```bash
ls ~/.claude/skills/showcase-deck/references/*.md 2>&1 | wc -l
```
Expected NOW: `0`(或报 "No such file")——即尚未实现,符合预期。

- [ ] **Step 2: 用扇出逻辑替换 install.sh**

把 `/home/fdse/ytest/deck-toolkit/install.sh` 全文替换为:

```bash
#!/usr/bin/env bash
# Fan-out installer for the deck-toolkit skills.
#
# Reads the local source layout (shared/ + skills/<name>/) that sits next to
# this script, and materialises each skill as a SELF-CONTAINED, flat directory
# under your agent's personal-skills dir — shared assets are merged in, so the
# installed layout matches a classic single-skill folder (no shared/ subdir).
#
#   Claude Code : ~/.claude/skills/<name>
#   Codex       : ~/.agents/skills/<name>   (same SKILL.md format)
#
# Usage:
#   bash install.sh                 # auto-detect Claude Code and/or Codex
#   FORCE_CLAUDE=1 bash install.sh  # force the Claude Code target
#   FORCE_CODEX=1  bash install.sh  # force the Codex target
#
# Re-run after `git pull` to update installed skills (they are copies, not
# checkouts). Existing installs are replaced wholesale.
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[ -d "$SRC/shared" ] && [ -d "$SRC/skills" ] || {
  echo "install.sh must run from inside a deck-toolkit checkout (shared/ + skills/ next to it)"; exit 1; }

fan_out_one() {
  local base="$1" name="$2"
  local dest="$base/$name"
  rm -rf "$dest"
  mkdir -p "$dest/references" "$dest/assets" "$dest/scripts"
  # 1) skill-specific payload (SKILL.md + any of its own references/assets/scripts)
  cp -a "$SRC/skills/$name/." "$dest/"
  # 2) merge the shared core in FLAT. The trailing /. matters: it merges into
  #    an existing dir instead of nesting (cp -a shared/assets dest/assets would
  #    create dest/assets/assets if the skill already shipped its own assets/).
  [ -d "$SRC/shared/references" ] && cp -a "$SRC/shared/references/." "$dest/references/"
  [ -d "$SRC/shared/assets" ]     && cp -a "$SRC/shared/assets/."     "$dest/assets/"
  [ -d "$SRC/shared/scripts" ]    && cp -a "$SRC/shared/scripts/."    "$dest/scripts/"
}

install_to() {
  local base="$1" label="$2"
  mkdir -p "$base"
  local name
  for name in $(cd "$SRC/skills" && ls -1); do
    [ -f "$SRC/skills/$name/SKILL.md" ] || continue
    echo "↓ installing $label skill → $base/$name"
    fan_out_one "$base" "$name"
  done
}

installed=0
if [ -d "$HOME/.claude" ] || [ "${FORCE_CLAUDE:-}" = "1" ]; then
  install_to "$HOME/.claude/skills" "Claude Code"; installed=1
fi
if [ -d "$HOME/.codex" ] || [ -d "$HOME/.agents" ] || [ "${FORCE_CODEX:-}" = "1" ]; then
  install_to "$HOME/.agents/skills" "Codex"; installed=1
fi
if [ "$installed" = "0" ]; then
  echo "No ~/.claude or ~/.agents found — defaulting to Claude Code."
  install_to "$HOME/.claude/skills" "Claude Code"
fi

echo "✓ done. Start a new agent session to pick up the skill(s)."
```

- [ ] **Step 3: 跑安装**

```bash
cd /home/fdse/ytest/deck-toolkit
bash install.sh
```
Expected: 打印 `↓ installing Claude Code skill → …/showcase-deck`(有 Codex 目录则再来一行)。

- [ ] **Step 4: 验证目标目录已平铺自包含**

```bash
ls ~/.claude/skills/showcase-deck/references/*.md | wc -l
ls ~/.claude/skills/showcase-deck/{SKILL.md,scripts/verify.sh,assets/deck-template.html}
test ! -e ~/.claude/skills/showcase-deck/shared
```
Expected: 第一行 `5`;第二行三个文件都在;第三行无输出(确认没有 `shared/` 子目录残留)。

- [ ] **Step 5: 提交**

```bash
cd /home/fdse/ytest/deck-toolkit
git add install.sh
git commit -m "feat(install): local fan-out — flatten shared core into each self-contained skill"
```

---

### Task 5: 零回归校验脚本 + 全量验证

写一个校验脚本,把装好的 `showcase-deck` 与 `p0-baseline` 基线**逐字节比对**,并跑一次 `verify.sh` 冒烟。

**Files:**
- Create: `/home/fdse/ytest/deck-toolkit/tests/check-parity.sh`

**Interfaces:**
- Consumes: git tag `p0-baseline`(Task 1);已安装目录 `~/.claude/skills/showcase-deck`(Task 4)。
- Produces: 命令 `bash tests/check-parity.sh` → 退出码 0 表示零回归。

- [ ] **Step 1: 写校验脚本**

创建 `/home/fdse/ytest/deck-toolkit/tests/check-parity.sh`:

```bash
#!/usr/bin/env bash
# Zero-regression check: the installed showcase-deck skill must be byte-identical
# (for SKILL-behavior files) to the pre-refactor baseline tagged p0-baseline.
set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALLED="${1:-$HOME/.claude/skills/showcase-deck}"
BASE="$(mktemp -d)"; trap 'rm -rf "$BASE"' EXIT

# materialise the baseline tree (root == the old single-skill folder)
git -C "$REPO" archive p0-baseline | tar -x -C "$BASE"

fail=0
cmp_path() {  # $1 = relative path under both trees
  if ! diff -r "$BASE/$1" "$INSTALLED/$1" >/dev/null 2>&1; then
    echo " FAIL parity: $1 differs from p0-baseline"; diff -r "$BASE/$1" "$INSTALLED/$1" | head || true; fail=1
  else
    echo "  OK  $1"
  fi
}
cmp_path SKILL.md
cmp_path references
cmp_path assets
cmp_path scripts

echo "RESULT: $([ $fail -eq 0 ] && echo 'PASS — zero regression' || echo 'REGRESSION')"
exit $fail
```

- [ ] **Step 2: 跑校验,期望 PASS**

```bash
cd /home/fdse/ytest/deck-toolkit
bash tests/check-parity.sh
```
Expected: 四行 `OK`(SKILL.md / references / assets / scripts),末行 `RESULT: PASS — zero regression`,退出码 0。若某项 `FAIL`,说明扇出漏了/多了文件或改了内容——回 Task 3/4 修到 PASS。

- [ ] **Step 3: verify.sh 冒烟(确认脚本随扇出可用)**

```bash
cd /tmp && rm -rf p0smoke && mkdir p0smoke && cd p0smoke
mkdir -p showcase_deck && cp ~/.claude/skills/showcase-deck/assets/deck-template.html showcase_deck/index.html
bash ~/.claude/skills/showcase-deck/scripts/verify.sh showcase_deck/index.html || true
```
Expected: 打印 verify 的结构/单文件/交付底线检查;模板**本就应在 `PLACEHOLDER-REDRAW` 那项 FAIL**(设计如此),其余结构项应 OK——证明 `verify.sh` 在扇出后的路径下能正常运行。

- [ ] **Step 4: 提交**

```bash
cd /home/fdse/ytest/deck-toolkit
git add tests/check-parity.sh
git commit -m "test: zero-regression parity check for fan-out install vs p0-baseline"
```

---

### Task 6: 更新 README 与仓身份,反映新布局

**Files:**
- Modify: `/home/fdse/ytest/deck-toolkit/README.md`(顶部标题/一句话定位、安装说明、目录布局)

**Interfaces:**
- Consumes: 新 `install.sh` 用法(Task 4)。

- [ ] **Step 1: 更新 README 的项目名、布局图、安装说明**

把 README 顶部从"单 skill project-showcase-deck"改为"deck-toolkit:生成 + 打磨 讲解型 HTML deck 的多 skill 项目"。加入源码布局(`shared/` + `skills/`)与安装说明:

```markdown
# deck-toolkit

从**代码仓**或**论文 PDF** 生成单文件 HTML 讲解 deck,并支持在生成后与 AI 持续迭代打磨。

## 源码布局
- `shared/` — 底座:模板 / 视觉系统 / 交互库 / verify+serve 脚本(所有 skill 共用,唯一事实源)
- `skills/showcase-deck/` — 代码仓 → deck(抽项目的魂 + SCQA 主线)
- (P1/P2 将加入 `skills/paper-deck/`、`skills/deck-editing/`)

## 安装
```bash
git clone https://github.com/ykz9527/project-showcase-deck.git deck-toolkit
cd deck-toolkit && bash install.sh   # 扇出安装到 ~/.claude/skills 和/或 ~/.agents/skills
```
装好后每个 skill 目录自包含;`git pull` 后重跑 `install.sh` 即更新。
```

(保留 README 中仍然准确的"deck 是什么/质量哲学"段落;只改布局与安装相关部分。)

- [ ] **Step 2: 确认 README 无残留旧路径说明**

```bash
cd /home/fdse/ytest/deck-toolkit
grep -n "~/.claude/skills/project-showcase-deck\|single-file skill" README.md || echo "no stale path refs"
```
Expected: `no stale path refs`(或仅在"历史/远程仓名"语境出现,可接受)。

- [ ] **Step 3: 提交**

```bash
cd /home/fdse/ytest/deck-toolkit
git add README.md
git commit -m "docs: README for deck-toolkit multi-skill layout + fan-out install"
```

---

## 验收(P0 Definition of Done)

- `bash tests/check-parity.sh` → `PASS — zero regression`(装好的 `showcase-deck` 与 `p0-baseline` 逐字节一致)。
- 源码仓在 `/home/fdse/ytest/deck-toolkit`,布局为 `shared/` + `skills/showcase-deck/`,git 历史以 rename 保留。
- `install.sh` 从本地扇出,装出自包含、平铺的 skill 目录(无 `shared/` 子目录)。
- 新开一个 agent 会话能识别 `showcase-deck` 并按其 SKILL.md 正常产出 deck(与今天体验一致)。

## 不在本计划内(留 P1/P2)

- 模板加 `data-ref` + 点选拷贝助手 + serve 热更新 + `deck-editing` skill(P1)。
- `paper-deck` skill + 论文导图脚本(P2)。
- 远程仓改名、curl 一键安装脚本的适配(可作为 P0 之后的小跟进)。

## 终审修订(实施后,以仓为准)

终审(整分支)后按用户决定做的三处修订,repo 是最终事实源、以下片段仅记录变更意图:

1. **skill 改名收口**:`skills/showcase-deck/SKILL.md` 的 frontmatter `name:` 由 `project-showcase-deck` 改为 `showcase-deck`,与目录名一致(避免 Codex 等按 `name:` 取值的工具分叉)。因此"零回归判据"精确化为:装好的 SKILL.md **除 frontmatter `name:` 这一行外**与 `p0-baseline` 逐字节一致,且 `name:` 必须正好是 `showcase-deck`——`check-parity.sh` 已据此改写(SKILL.md 走 `grep -v '^name:'` 比对 + 正面断言新名)。
2. **权限位纳入判据**:`check-parity.sh` 增加 `scripts/` 的 mode(`find -printf '%m'`)比对——`verify.sh`/`serve.sh` 是直接执行(`./serve.sh`),`+x` 吃重,`diff -r` 不管 mode 需单独守。
3. **老名安装残留**:`install.sh` 末尾探测 `<base>/project-showcase-deck` 遗留目录并**告警**(不自动删用户目录);README 增加升级者手动 `rm -rf` 老目录的说明。
