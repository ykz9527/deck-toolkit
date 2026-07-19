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

- 改之前 `cp index.html index.html.bak`;verify FAIL 就回滚,别把坏页留给用户。
- 用户在 serve,改完文件即热更新——**不要**自己重启服务器。
- 遇到没有 data-ref 的元素:定位后**顺手补一个** `data-ref="sN-slug"`(约定见 `shared/references/deck-mechanics.md`)。
