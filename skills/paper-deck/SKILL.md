---
name: paper-deck
description: Use when someone wants to explain or present a research paper / PDF (their own or one they are reading) to an audience as a polished single-file HTML slide deck. A paper already carries its own narrative structure, so the deck follows the paper's own section arc and adds only two things — a one-sentence summary of what each section establishes, and live interactions that make the method understandable — plus result figures lifted faithfully from the PDF. Not a repo showcase (use showcase-deck), not a literal reproduction of the paper.
---

# Paper Deck

## Overview

把一篇论文 PDF 讲成一份单文件、自包含的 HTML 幻灯片 deck,讲给一群人听——同行、跨领域听众、或组会。

**核心原则——质量到底从哪来:** 一份好的 paper deck 不是靠视觉。**论文自带叙述结构**,作者已经把它组织成一条论证链——所以 deck 相对论文只加两样东西:(1) **总结性文字**,把每节压成一句"这节确立了什么";(2) **动态交互**,把静态图讲不动的机制一步步演出来。再加上 (3) 论文语境下的**诚实分级**——每条主张都能回溯到论文里的具体图/表/节。视觉形态由 shared 模板一次性解决,不要重新发明。差的 paper deck 都败在"替论文重新叙事",从来不是败在 CSS。

**两个方向的失败都要避开:** 一头是**逐段搬运**(把论文每一段抄成幻灯片,那不如直接读 PDF);另一头是**重新叙事**(自己造一条主线、重排顺序、把结论改写成更有冲击力的钩子,那是在把听众带离论文)。正确的位置在中间:**顺序沿用论文,内容压成结论,机制做成交互。**

## When to use

- "讲讲这篇论文 / 做个论文讲解 / present this paper / 组会讲 paper / 我要介绍我这篇工作"
- 把一篇 PDF 讲给同行、跨领域听众或组会;任何交付物是"一篇论文的讲解 deck"、单文件可分享的场合。

**Not for:** 代码仓介绍(用 `showcase-deck`)、论文的逐字复现、单张图的绘制(用 `drawio` skill)。

## The non-negotiables (the DNA — 动 HTML 之前先读这些)

1. **魂先于页。** 先填一份 Paper Brief(研究问题、缺口、一句话能复述的核心 idea、方法三步、关键结果、听众、诚实分级)。**用 Claude 的 Read 工具直接读 PDF**,按"摘要/引言 → 方法 → 结果 → 局限"的信号强度顺序读。绝不编造。→ `references/extract-the-paper-soul.md`
2. **用论文自己的词。** 页面上出现的每个术语,都必须是论文实际用过的(方法名、模块名、指标名、数据集名、章节标题、公式符号),逐字照抄。真术语对外行不透明就旁边加一句白话注解,绝不换成更顺口的近义词或自造一个论文没提过的伞形大词。先建 Brief 的 VOCABULARY 白名单;一个词回溯不到论文原文,就删掉。→ `references/extract-the-paper-soul.md`
3. **沿用论文自己的结构,别重写它。** 论文与代码仓最大的区别是**它自带叙述结构**——作者已经把它组织成一条论证链,每节的位置都有理由。你的活是**压缩和点亮**,不是重新叙事:nav 词直接取自论文的章节骨架(问题 / 方法 / 怎么建的 / 实验 / 局限),只做**合并、省略、按 RQ 切**这类压缩,不做重排、不制造悬念、不发明论文里没有的段落。nav 词只存在于**一处**——模板脚本顶部的 `MAINLINE` 数组。测试:把 nav 词和论文目录并排,能一眼看出对应关系。→ `references/paper-narrative.md`
4. **只靠 NAV 指路,别的都别加。** 顶部 nav 的词本身就是路线图,当前所在段自动高亮。不要插入转场句或"agenda/大纲"页——这是被明确否决过的做法。一组读起来成一句话的 nav 词,胜过任何衔接性文字。
5. **标题是总结,不是钩子。** 每页标题是一句完整的结论句——**这一节确立了什么**(既不是"方法"/"实验结果"这种 topic-noun,也不是"你对这个数的直觉大概会高出一倍"这种悬念式营销腔)。用论文自己的术语和数字把结论说完,正文是它的**视觉证据**,不是项目符号墙。一页一个想法,视觉元素 ≤ 约 7 个,文字 ≤ 约 50 词。判据:这句标题,论文作者会点头说"对,这节就是这个意思"吗?→ `references/paper-narrative.md`(反面例子对照表)+ `references/content-logic.md`
6. **论文语境的激进诚实。** 三档标签——**论文声称 / 已复现 / 存疑**——始终在页面上可见。每条主张都要回溯到论文里具体的图/表/节。绝不编造数字,绝不把"论文声称"偷换成"已复现"。
7. **故事讲白话,形式化细节进附录。** 主线面向混合听众(同行+跨领域+领导都可能在场),VOCABULARY 里的术语要注解、不堆公式符号。把证明、完整实验表、超参、复杂符号推导都推进独立隔开的技术附录。
8. **Show, then name。** 把方法的交互演示放在形式化记号**之前**——先让听众相信"这样能 work",他们才会愿意接受它的名字和符号。
9. **无 AI 味。** 沿用模板已经做好的编辑设计系统(近黑/暖纸双主题、大地色语义强调、衬线标题+等宽标签),不加柔渐变、彩色徽章、圆角一切、emoji 当图标。→ `references/visual-system.md`

## The delivery floors (`scripts/verify.sh` 会挡)

这些不是愿景,是会被脚本检查的,模板本身已经把线路接好——你要做的不是"搭建"它们,而是让它们对**这篇论文**成立。

- **模板发的是洞,不是设计。** 封面图、两段交互、架构/方法图都带着 `PLACEHOLDER-REDRAW` 标记出厂。逐个重画成这篇论文的真东西,再删掉标记。**任何标记残留 = FAIL**(模板本身故意挂在自己的检查上)。
- **封面图。** 一张安静、静态的 THIS paper 肖像——核心 idea 的一图,或论文自己的 teaser 图,源自 Brief。检验标准:把论文名换成另一篇,这张图还成立,就说明它是填充物。
- **≥ 2 个交互**(争取 3 个),形式各不相同。**把方法图重画成分步交互**是天然的第一个,直接满足一个交互位。
- **方法/框架被画出来。** drawio 工具链能用就用,不能用就手画 inline SVG。跳过图才是失败,手画是正确的兜底方案。
- **单文件。** 无外部请求、无同级资源——抽出的结果图必须是 `data:` 内联,绝不是 `<img src=文件>`。deck 要经得起被单独发一封邮件。

**floors 不为凑数辩护。** 一个空洞的 demo 比一张扎实的静态页更糟。如果第二个真交互出不来,正确的做法是**把论文读得更透**(方法节、实验设定、消融),而不是造一个假的。

## 图表处理(方案 C)——paper deck 的专属核心

论文里的图分两类,处理方式完全不同:

- **方法 / pipeline / 框架图 → 重画成交互。** 讲这篇论文的高光是"方法怎么 work",用 shared 交互库的**六台机器**把机制拆开、一步步演出来(`assets/interaction-patterns.html`)。原图往往太密、太静态,承担不了"让人理解机制"这件事。这天然满足交互底线的第一位。
- **结果曲线 / 密集实验图 / 定性样例 → 抽原图,忠实还原。** 重画不划算而且会失真——数字和曲线一旦被"重新设计",反而更不可信。用:
  ```bash
  scripts/extract-pdf-figures.sh <pdf> <page> --crop L,T,W,H --id sN-fig --caption "..."
  ```
  (`--crop` 是页面的分数裁剪 left,top,width,height,取值 0..1;详见脚本头注)。它直接吐一段 `data:` 内联的 `<div class="apx-fig" data-ref="sN-fig">` 片段,粘进 deck 的结果段或技术附录即可。忠实 > 重画。**分数不是靠肉眼盯着 PDF 猜出来的,是迭代量出来的:** 先不裁(或给个宽松的框)+ `--out draft.png` 出图,用 Read 工具看这张 PNG,量出图形实际占页面的比例,换算成 `--crop` 的分数再裁一次,再 Read 裁出来的 PNG 核对,不对就微调分数、重复,直到图被干净框住。文字太小看不清就加 `--dpi`(默认 150)提高渲染分辨率,比如 `--dpi 220`。

**判据很简单:** 想让听众**理解**的(机制)→ 重画成交互;想让听众**信任**的(证据)→ 忠实抽原图。

## PDF 摄入

Claude 用 **Read 工具直接读 PDF**——它原生支持文字与图。不要为此引入任何 PDF 解析栈(不装 pdfplumber / PyMuPDF 之类)。按"摘要/引言 → 方法 → 结果 → 局限"的信号强度顺序读;用户点名某一节或某张图,先读它,让它给整个叙事定锚。

## Workflow

1. **读 PDF 抽魂 → 写 Paper Brief。** `references/extract-the-paper-soul.md`。用 Read 工具从摘要/引言读起(问题、缺口、贡献声称的权威来源),再方法(交互的候选)、结果(区分"真被展示"与"只是被声称")、相关工作(贡献相对谁而新)、局限(诚实边界)。RESEARCH QUESTION、GAP、CORE IDEA、METHOD IN 3 STEPS、KEY RESULTS、AUDIENCE、VOCABULARY、HONESTY 都要具体且有证据,才能继续下一步。
2. **取论文的结构当主线。** 列出论文的章节骨架,把学术章节名换成听众秒懂的白话,压成 4–6 个 nav 词写进模板的 `MAINLINE` 数组——改一处,全 deck 跟着走。只允许**合并**(Related Work 并进"问题")、**省略**(工程细节推附录)、**按 RQ 切**(实证论文直接用 RQ1–RQn 分段);不重排、不制造悬念、不发明论文没有的段落。写完把 nav 词和论文目录并排比一遍,对不上就是在重写。`references/paper-narrative.md`。
3. **复制模板,填内容——一页一个断言。** 复制 `assets/deck-template.html` 到**项目根 `paper_deck/index.html`**(建目录)。替换内容,nav 词设为主线;**画封面图**——一张安静的静态肖像,源自 Brief 的核心 idea 或论文自己的 teaser 图;每页标题写成完整的结论句 + 一份视觉证据(不是 topic-noun + 项目符号),一个想法、≤~7 元素、≤~50 词。**每个语义单元都要打 `data-ref`**(约定 `sN` / `sN-title` / `sN-{slug}` / `sN-fig`,见 `references/deck-mechanics.md`)——这是之后用户点选编辑的锚点,`verify.sh` 会挡没打的 slide/interaction。`references/deck-mechanics.md` + `references/content-logic.md`。
4. **把方法图做成 live 交互(floor: 2,争取 3),挑一个不同形式的第二个。** 沿主线走一遍,挑出"看它动"能教会静态图教不会的那个点。**方法/pipeline 图** 是第一个天然候选——用六台机器(`assets/interaction-patterns.html`)之一,把 METHOD IN 3 STEPS 拆成分步演示。第二个交互换一种形式(两个雷同的分步演示只算一个想法)。留在模板里的通用占位形状不算交互。
5. **抽结果图。** 对每张要忠实呈现的结果图(曲线、消融表、benchmark 对比),跑 `scripts/extract-pdf-figures.sh <pdf> <page> --crop L,T,W,H --id sN-fig --caption "..."`,把吐出的 `apx-fig` 片段粘进结果段或技术附录,`data-ref` 用 `sN-fig`。`--crop` 分数别靠肉眼盯 PDF 猜——先宽裁/不裁 + `--out` 出图、Read 出来看,量出比例再精裁,反复几轮(详见"图表处理"一节);文字太小就加 `--dpi` 提分辨率。
6. **自检 + 起服务。** 运行 `scripts/verify.sh paper_deck/index.html`(**必须传路径**——脚本默认指向 showcase 的路径,不传就会去检查一个不存在的文件)。再**始终**启动预览:`scripts/serve.sh paper_deck/index.html`(后台运行,绑 `0.0.0.0`),把内网 URL 给用户。交付物是验证过的、渲染出来的页面——在页面上迭代(两个主题都看),不是在描述上迭代。
7. **用 `deck-editing` 技能迭代。** deck 起服务后,注入的 picker 让用户点选任意元素、把引用块粘回聊天;用 **`deck-editing`** 技能把每条引用变成一次可验证的精确修改。不要为了微调就从头重建。

## Quick reference

| Need | Go to |
|------|-------|
| 从论文里挖什么 + 诚实分级 + 术语忠实度 | `references/extract-the-paper-soul.md` |
| 沿用论文结构定 nav + 标题写成总结(附反面例子对照表) | `references/paper-narrative.md` |
| 每页内容逻辑(断言-证据、Rule of One) | `references/content-logic.md` |
| 视觉语言、反 AI 味、配色/字体 | `references/visual-system.md` |
| 单文件结构、组件、主题、edit 模式、data-ref | `references/deck-mechanics.md` |
| 可复制的骨架 | `assets/deck-template.html` |
| 交互画廊——六台机器,很多种玩法 | `assets/interaction-patterns.html` |
| **结果图抽原图** | `scripts/extract-pdf-figures.sh` |
| 存哪 + 怎么预览 | 构建到 `paper_deck/index.html`;`scripts/verify.sh paper_deck/index.html`、`scripts/serve.sh paper_deck/index.html`(注意都要传路径) |

## Reliability rules (hard-won)

- **输出位置固定:项目根的 `paper_deck/index.html`。** 建 `paper_deck/` 目录。如果这篇论文已经有 deck,它就存在这里——动手之前先找它,而不是无脑重建。
- **已存在就原地改,不重写。** 一份成熟的 deck 里有很难复现的打磨(真实封面、手做的动画、调过的排版),从模板重写会悄悄丢掉这些、造成倒退。先读现有 deck,把它当底稿,做外科手术式的修改(每次改前备份、改后验证)。
- **用 Write 工具建 HTML,每次改动后都验证**(`wc -c`、grep 结构、serve → 200)。大文件的脚本拼接不可靠,可能被静默重放。
- **bulk/脚本编辑前先备份**(`cp`),事后 diff 未改动的区域。
- **在真实渲染出来的页面上验证,两个主题都看**——颜色/主题的改动不看渲染结果就不能信。
- **`verify.sh` / `serve.sh` 必须显式传 `paper_deck/index.html` 路径**——它们默认指向 `showcase_deck/index.html`,不传路径会检查/预览错文件(或报"文件不存在")。

## Common mistakes (red flags — stop)

- **替论文重新叙事(本 skill 最常见、也最伤的失手)。** 症状:自己造了一条论文里不存在的主线、按"哪个卖点强"重排章节、或把结论改写成更有冲击力的说法。论文的顺序是作者论证的一部分,你的活是压缩不是重编。→ DNA #3
- **标题写成悬念钩子而不是总结。** "你对这个数的直觉大概会高出一倍"、"它交出的方案正是十年前被推翻的那个"——这是路演腔。听众来听论文,不是来听 pitch。改成"这节确立了什么"的一句话,用论文自己的数字和术语。→ `references/paper-narrative.md` 的对照表
- **复述摘要当讲解。** 摘要是论文自己的浓缩推销,不是讲给听众的解释——回到抽魂那一步。
- **重写一份已经成熟的 deck。** 倒退伪装成进步。原地改进,只有在真没有现存 deck 时才从模板开始。
- **把内容逻辑框架显示在页面上,而不是隐形地应用它**——比如一页真的标着"动机/缺口/idea/方法",而不是让这条逻辑自己在顺序和标题里体现。
- **topic-noun 标题 + 项目符号墙**("方法"/"实验结果" 配 6 条 bullet)→ 改写成断言(完整结论句) + 一份视觉证据。
- **一次性糊上整张密集实验图。** 该抽原图、或按结果段/附录分层,而不是原样贴一大张图糊弄过去。
- **插入转场句 / agenda 页。** 只靠 nav 指路。
- **把"论文声称"当"已复现"。** 声称是论文说的话,复现要有图表撑住——分开标注,答得出"这句是哪来的"。
- **形式化记号出现在方法交互之前。** 先让听众信,再教记号——顺序反了会把人挡在门外。
- **生造大词代替论文自己的术语。** 论文没起过统一名字,就别自己造一个"XX 引擎"式的伞形词。
- **`<img src=文件>` 放在 deck 旁边。** 抽出的结果图必须是 `data:` 内联,不能是同级文件。
- **跳过方法图。** drawio 能用就用,不能用就手画 inline SVG——跳过才是失败。
