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
