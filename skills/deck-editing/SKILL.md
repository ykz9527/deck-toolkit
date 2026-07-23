---
name: deck-editing
description: Use when iterating on an ALREADY-GENERATED deck (built by showcase-deck / paper-deck) — the user pasted a picker "引用块" (a 📍/🔑/📄 reference), or asks to change a specific slide/element or restructure the deck. Not for building a deck from scratch.
---

# Deck Editing (iterate on a built deck)

打磨一份**已经生成**的 HTML deck。后端就是当前这个对话——没有独立工具。两类改动:

## 区域级改(用户粘来一个"引用块")

picker(serve 时注入,见 `shared/scripts/serve.sh`)让用户点选元素、把引用块拷到剪贴板粘回这里。引用块长这样:

```
📍 第 3 页 · [为何好] · 「…」
🔑 data-ref="s3-source-of-truth"   ← grep 唯一命中
📄 片段:<div ... data-ref="s3-source-of-truth"> … </div>
✏️ 我的指令:把左右对比换成上下
```

步骤见 `references/edit-loop.md`。核心:**grep `data-ref` 唯一定位 → 只改那一处 → verify → 靠热更新回显**。

## 结构级改(加/删/重排页、换主线)

- 主线在模板的 `MAINLINE` 数组一处改。
- 重排/增删页:操作对应的 `<section class="slide" data-ref="sN">`;改动后**重编 data-ref 的页序号**(见 `edit-loop.md`)。

## 铁律

- **改动碰到事实断言,先回源核对再落笔。** 编辑不是搬字——只要你要改的那句话包含一个可查的断言(字段名、数量、归属关系、某段代码/流程的行为、报错原文),先回仓库的代码/数据里核一遍,以核到的为准。**核不到就问用户或直接删掉,绝不顺手补一个"听起来合理"的说法。** 这是打磨阶段最容易出、也最伤信任的错:润色时顺手加一句没依据的话,比不改更糟。同一个项目里有两套名字相近的系统时(两份 schema、两层配置),尤其别把 A 系统的字段安到 B 系统头上——先确认这句讲的是哪一套。
- **台上每个数字要么有出处,要么有参照物。** 一个突然冒出来的数字("六种改动""18 条校验")读者没有落点。要么它能指回代码/数据(为写"18"我去数了源码里的 `_error()` 调用),要么同页有参照("上一页那样的校验")。两者都没有——删掉或改成不带数的说法。
- 改之前 `cp index.html index.html.bak`;verify FAIL 就回滚,别把坏页留给用户。
- 用户在 serve,改完文件即热更新——**不要**自己重启服务器。
- 遇到没有 data-ref 的元素:定位后**顺手补一个** `data-ref="sN-slug"`(约定见 `shared/references/deck-mechanics.md`)。
- 用户说"页面还是旧的"→ **先查 localStorage 覆盖,别先怪浏览器/代理缓存**(见 `references/edit-loop.md` → 排障)。
