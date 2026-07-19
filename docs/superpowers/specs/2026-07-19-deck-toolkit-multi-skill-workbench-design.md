# deck-toolkit:从单一 skill 演进为「生成 + 打磨」的多 skill 项目

**日期**:2026-07-19
**状态**:设计已对齐,待用户审阅
**演进对象**:`ykz9527/project-showcase-deck` 仓(原地演进,保留历史)

---

## 1. 背景与动机

现有 `project-showcase-deck` 是一个成熟单 skill:输入一个**代码仓**,产出**单文件 HTML deck**。它的魂不在 CSS,而在"抽项目的魂 + 主线 + 诚实分级",并有 `verify.sh` 交付底线。

两个真实痛点推动这次迭代:

1. **一次性生成是"盲盒"。** PPT 本质是**反复调**出来的,模型一把梭很难到位。当前唯一的迭代方式是在聊天框里描述"第 3 页那个图改一下"——模型靠猜定位,低效且易改错地方。
2. **内容源不止代码仓。** 讲解**论文/PDF** 是同样高频的需求,但论文的"魂"(研究问题→缺口→idea→方法→结果→局限)和代码仓完全不同,硬塞进现有 skill 会把它撑坏。

目标:把项目从"**一次性生成**"扩成"**生成 + 持续打磨**",并支持**代码仓**与**论文**两种内容源。

## 2. 非目标(明确不做)

- **HTML → 传统 pptx 转换**:已否决。这个 deck 的灵魂是交互与动画,转静态 pptx 等于丢魂,不值当。
- **多后端适配层(Claude Code / OpenCode / 裸 API 可插)**:本轮不做。先做 **B 形态**(后端就是当前 Claude Code 对话),验证"指哪改哪"效果好之后,后续再扩到 C(薄适配层)。
- **重型 PDF 解析栈**:不引入。PDF 让 Claude 用 Read 工具原生读,配一个轻量导图脚本即可。

## 3. 设计理念(一句话)

> 把"和 AI 反复调 PPT"这件事,从聊天框里的**盲改**,变成"**所见即所选、指哪改哪**"的工作台;并让底座(模板/视觉/交互/校验)一份复用,内容源(代码仓/论文)各写各的魂。

## 4. 总体架构

单仓 `deck-toolkit`,内部三块:一份共用底座 + 三个薄 skill。

```
deck-toolkit/                        ← 由 project-showcase-deck 原地演进
├─ shared/                           ← 唯一事实源:底座(不重复)
│   ├─ assets/
│   │   ├─ deck-template.html        ← 模板(含 data-ref 预埋 + 框选层)
│   │   └─ interaction-patterns.html ← 六台机器交互库
│   ├─ references/
│   │   ├─ visual-system.md
│   │   ├─ deck-mechanics.md
│   │   └─ content-logic.md
│   └─ scripts/
│       ├─ verify.sh
│       ├─ serve.sh                  ← 增加热更新
│       └─ extract-pdf-figures.sh    ← 论文导图(paper-deck 用)
├─ skills/
│   ├─ showcase-deck/                ← 代码仓 → deck(现有,瘦身)
│   │   ├─ SKILL.md
│   │   └─ references/{extract-the-soul, narrative-spine}.md   ← 代码仓专属的"魂"
│   ├─ paper-deck/                   ← 论文 → deck(新)
│   │   ├─ SKILL.md
│   │   └─ references/{extract-the-paper-soul, paper-narrative}.md
│   └─ deck-workbench/               ← 框选→引用→改→热更新(新,跨两种 deck 通用)
│       ├─ SKILL.md
│       └─ references/edit-loop.md
├─ install.sh                        ← 底座扇出 + 双平台安装
└─ README.md
```

**分工原则:** `shared/` 装底座(所有 deck 共用),`skills/*` 各只装自己独有的"魂"和流程。每个 skill 都薄、职责单一。

## 5. 组件详解

### 5.1 `shared/` 底座(唯一事实源)

从现有 skill 抽出与"内容源无关"的部分:模板、视觉系统、交互库、`deck-mechanics.md`、`content-logic.md`、`verify.sh`、`serve.sh`。这些东西讲代码仓和讲论文都一样用。

**模板改动(相对现有):**
- **预埋 `data-ref`**:每个"可被框选/编辑的语义单元"(幻灯片 section、标题、正文块、交互根、图)在生成时打上稳定的 `data-ref="s3-demo"` 这类 id。这是框选精确定位的地基(见 §6)。
- **框选层**:模板内置一个轻量 JS overlay(类似现有 edit mode,一个 toggle 开关):hover 高亮 DOM 节点、点选(shift 多选)、把选中项打包成"引用块"复制到剪贴板。纯前端、只读,不写文件。

### 5.2 `showcase-deck`(代码仓 → deck,瘦身)

保留现有 skill 的全部质量哲学,但**只留代码仓专属的两份 reference**:`extract-the-soul.md`(定位/差异化/诚实分级/用仓库自己的词)、`narrative-spine.md`(SCQA 主线)。底座相关的 reference 从 SKILL.md 改为引用 `shared/`。行为对用户不变。

### 5.3 `paper-deck`(论文 → deck,新)

新 skill,独有两份 reference:

- **`extract-the-paper-soul.md`**:讲论文的"魂"——研究问题、现有做法的缺口、核心贡献/idea(一句话能复述)、关键结果、诚实的局限。诚实分级换成论文语境(**论文声称 / 已复现 / 存疑**)。用**论文自己的术语**,不臆造。
- **`paper-narrative.md`**:论文讲解叙事骨架:**动机 → 缺口 → idea → 方法 → 结果 → takeaway/局限**。这是和代码仓 SCQA 并列的另一套 spine。

**PDF 摄入:** Claude 用 Read 工具直接读 PDF(原生支持文字+图)。

**图表处理(方案 C — 该动的动、该忠实的忠实):**
- **核心方法图/流程图 → 重画成交互**:讲论文的高光就是"方法怎么 work",用底座的六台机器做成一步步演的交互。天然满足交互底线(≥2)。
- **结果曲线/复杂实验图 → 抽原图**:重画不划算也易失真,用 `shared/scripts/extract-pdf-figures.sh` 把论文原图导成 png 内联进 deck,最忠实。

### 5.4 `deck-workbench`(框选编辑回路,新 — 本轮核心)

一份 reference `edit-loop.md`,教 Claude 如何消费"引用块"做外科手术式编辑。这是 B 形态的落地:**没有后端适配层,后端就是当前 Claude Code 对话**。

**支持两类操作:**
- **区域级改**:消费框选生成的引用块(见 §6),grep `data-ref` 唯一定位,只改那一处,verify + 热更新。
- **结构级改**:加页/删页/重排/换主线。提供一个"结构地图"能力(`serve` 或一个小脚本 dump 出 `幻灯片序号 → data-ref → nav 标签 → 标题` 的清单),让人和 Claude 有共同的地图去指"把第 5 页移到第 2 页后面"。主线仍是模板里 `MAINLINE` 数组一处改。

## 6. 关键机制:框选 → 引用 → 改 → 热更新(B 的数据流)

这是本轮技术核心。因为 B 没有后端写文件,**浏览器只读、Claude 才写**,所以框选层必须吐出足够精确的引用,让 Claude 光靠读 `index.html` 就能唯一定位。

**粒度:点选元素(A)。** hover 高亮 DOM 节点,点一下选中(shift 多选)。每个选中项 = 一个确定的 DOM 节点,而非模糊矩形。

**定位:预埋 `data-ref`(路2)。** 生成阶段就给每个可选语义单元打稳定 id,框选直接读它 → 100% 唯一命中。不靠"文本 grep 靠猜"。

**数据流:**

```
①用户在浏览器开 workbench 模式(toggle)
      ↓
②hover 高亮 → 点选一个/多个 DOM 节点(每个都有 data-ref)
      ↓
③框选层打包成"引用块" → 复制到剪贴板:
      📍 第 3 页 · [为何好] · 「单一事实源省掉了手工同步」
      🎯 选中:一个 compare 切换交互
      🔑 data-ref="s3-source-of-truth"        ← Claude 用这个 grep,唯一命中
      📄 当前片段(outerHTML):<div class="interaction" data-ref="s3-source-of-truth">…</div>
      ✏️ 我的指令:______(用户补一句)
      ↓
④用户粘回 Claude Code 聊天框,补上指令
      ↓
⑤Claude 按 deck-workbench/edit-loop.md:
      grep data-ref="s3-source-of-truth" → 唯一定位 → 外科手术式改 → verify.sh
      ↓
⑥serve 热更新 → 浏览器自动刷新,看到结果 → 不满意回 ②
```

**热更新:** `serve.sh` 注入一段轻量脚本,轮询 `index.html` 的 mtime(或 HEAD Last-Modified),变了就 `location.reload()`。简单可靠,不上 websocket。

## 7. 打包与安装(方案 A — 底座扇出复制)

现实约束:每个 skill 运行时是独立目录(`~/.claude/skills/<名>/`),Claude 只能稳定读到 skill 自己目录内的文件。

**开发时 DRY,安装时扇出:**
- 仓库里 `shared/` 只有一份(你维护的唯一事实源)。
- `install.sh` 把 `shared/` 的 assets/references/scripts **复制(或软链)进每个目标 skill 目录**,使每个装好的 skill **自包含**,运行时零跨目录依赖。
- 延续现有双平台:Claude Code 装 `~/.claude/skills/`,Codex 装 `~/.agents/skills/`。

## 8. 错误处理与边界

- **框选到没有 data-ref 的元素**(比如手工加的老内容):框选层回退到"页码 + outerHTML + 最近的祖先 data-ref",引用块标注"⚠️ 无稳定 id,Claude 需读上下文确认";并建议 Claude 顺手补一个 data-ref。
- **多选跨页**:引用块按页分组,每页一段,避免 Claude 混淆。
- **verify 失败**:编辑回路必须在改完后跑 `verify.sh`,FAIL 则回滚(编辑前 `cp` 备份),不把坏页热更新给用户。
- **热更新轮询**:仅在 workbench/serve 模式注入,产出的最终单文件 deck **不含**轮询脚本和框选层(保持"单文件、可邮寄"的交付底线)——即区分"工作态"与"交付态"。

## 9. 交付态 vs 工作态(重要)

- **工作态**:带 data-ref、框选层、热更新脚本,供打磨。
- **交付态**:`verify.sh` 仍要求单文件、无外部请求。**data-ref 可以保留**(无害,且未来 C 形态要用);**框选层 JS 和热更新轮询必须能一键剥离**(一个 `build-deliverable` 小脚本或模板里以注释包裹的可移除块),保证交付的 deck 干净、能邮寄。

## 10. 测试与验证

- `verify.sh` 扩展:新增 "data-ref 覆盖率" 检查(关键语义单元是否都有 id);"交付态无框选/热更新残留" 检查。
- **真跑用户路径**(项目铁律):装好后,分别用一个真实代码仓、一篇真实论文 PDF 各跑一遍完整链路(生成 → 框选 → 粘引用 → Claude 改 → 热更新看到变化),而不是只跑脚本。
- 两个主题(暗/暖)都要肉眼验。

## 11. 分期与依赖

建议实现顺序(每期可独立验收):

1. **P0 — 仓库重构 + 底座抽取 + install 扇出。** 把现有 skill 拆成 `shared/` + `showcase-deck/`,`install.sh` 改扇出。验收:装好后 `showcase-deck` 行为与现在完全一致(零回归)。
2. **P1 — 模板加 data-ref + 框选层 + serve 热更新 + deck-workbench skill。** 验收:能框选、拿到引用块、Claude 据此改、页面自动刷新。
3. **P2 — paper-deck skill + 导图脚本。** 验收:一篇真实论文跑通生成 + 方法图交互 + 结果图抽原图。
4. **P3(本轮不做,留接口)** — C 形态:后端适配层(OpenCode / 裸 API)。

依赖:P1 依赖 P0(底座就位);P2 依赖 P0(共用底座)但独立于 P1;P1 的 data-ref 为未来 P3 复用。
