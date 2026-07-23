#!/usr/bin/env bash
# Serve a deck on 0.0.0.0, injecting the picker + hot-reload before </body>.
# The picker/hot-reload are NEVER written into the deck file — only injected in
# transit, so the on-disk deck stays a clean, mailable single file.
#
# Edit-mode write-through: while served, in-browser text edits POST to /__save
# and are written straight back into the deck file on disk — the file stays the
# single source of truth, so there is nothing trapped in localStorage to
# reconcile later. Writes are bounded to the inner content of existing editable
# regions ([data-edit] / [data-editlist]); they can never change structure,
# attributes, or any other file. (This is a LAN dev-preview convenience: the
# save endpoint is reachable by anyone who can reach the port. Serve on a
# trusted network.)
#
# Usage: ./serve.sh [path/to/deck.html] [port]
set -u
F="${1:-showcase_deck/index.html}"
[ -f "$F" ] || { echo "no deck at: $F  (build it to showcase_deck/index.html first)"; exit 1; }
PORT="${2:-8770}"
DIR="$(cd "$(dirname "$F")" && pwd)"; BASE="$(basename "$F")"
SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PICKER="$SKILL_DIR/assets/picker.js"
IP="$(hostname -I 2>/dev/null | awk '{print $1}')"; [ -n "${IP:-}" ] || IP="127.0.0.1"
echo "Serving $DIR on 0.0.0.0:$PORT  →  http://$IP:$PORT/$BASE   (picker + hot-reload + edit write-through)"
cd "$DIR" && exec python3 - "$PORT" "$BASE" "$PICKER" <<'PY'
import sys, os, re, json, http.server, socketserver, signal
# A preview server must not die because nobody is reading its log. If it is launched
# through a pipe that closes early (`serve.sh … | head`), the first access-log write
# raises SIGPIPE and the whole server goes down — i.e. the page dies the moment it is
# first opened. Ignore SIGPIPE and make logging failure-proof.
try: signal.signal(signal.SIGPIPE, signal.SIG_IGN)
except (AttributeError, ValueError): pass
port = int(sys.argv[1]); deck = sys.argv[2]; picker_path = sys.argv[3]
picker = open(picker_path, encoding="utf-8").read() if os.path.exists(picker_path) else "/* picker.js not found */"

# Hot-reload: poll the deck's Last-Modified (mtime) and reload on change — EXCEPT
# a change this very page just caused by saving its own edits (window.__deckSelfWrite),
# so typing doesn't yank the page out from under the cursor. Someone else's edit,
# or an edit to the file by hand, still reloads.
HOT = ("(function(){var last=null;setInterval(function(){"
       "fetch(location.pathname||'/',{method:'HEAD',cache:'no-store'})"
       ".then(function(r){var m=r.headers.get('Last-Modified');"
       "if(last&&m&&m!==last){"
       "if(window.__deckSelfWrite&&Date.now()<window.__deckSelfWrite){last=m;return;}"
       "location.reload();}last=m;}).catch(function(){});},1000);})();")
INJECT = ("<script>" + picker + "</script>\n<script>" + HOT + "</script>\n</body>").encode("utf-8")

# ---- write-through: apply {t:{idx:html}, l:{name:html}} into the deck file ----
# idx = document-order position of a [data-edit] element NOT inside a [data-editlist]
# (mirrors the template's idxEd); name = a [data-editlist] value. We replace ONLY
# the inner content of the located element — never its tag/attrs/structure.
_ATTR = re.compile(rb'''\s([a-zA-Z:-]+)(?:\s*=\s*("[^"]*"|'[^']*'|[^\s"'>]+))?''')
_VOID = {b'area',b'base',b'br',b'col',b'embed',b'hr',b'img',b'input',b'link',b'meta',b'param',b'source',b'track',b'wbr'}

def _scan(html):
    i, n = 0, len(html)
    while i < n:
        lt = html.find(b'<', i)
        if lt < 0: return
        if html[lt:lt+4] == b'<!--':
            i = html.find(b'-->', lt); i = n if i < 0 else i + 3; continue
        if not (lt+1 < n and (html[lt+1:lt+2].isalpha() or html[lt+1:lt+2] == b'/')):
            i = lt + 1; continue
        j, q = lt + 1, None
        while j < n:
            c = html[j:j+1]
            if q:
                if c == q: q = None
            elif c in (b'"', b"'"): q = c
            elif c == b'>': break
            j += 1
        if j >= n: return
        raw = html[lt:j+1]
        if raw[1:2] == b'/':
            yield ('close', raw[2:-1].strip().lower(), lt, j+1, {})
        else:
            m = re.match(rb'<\s*([a-zA-Z][a-zA-Z0-9:-]*)', raw)
            name = m.group(1).lower() if m else b''
            attrs = {}
            for am in _ATTR.finditer(raw[m.end():-1] if m else b''):
                v = am.group(2)
                if v and v[0:1] in (b'"', b"'"): v = v[1:-1]
                attrs[am.group(1).lower()] = v if v is not None else b''
            kind = 'void' if (name in _VOID or raw[-2:-1] == b'/') else 'open'
            yield (kind, name, lt, j+1, attrs)
        if name in (b'script', b'style') and raw[1:2] != b'/':
            close = html.find(b'</' + name, j); i = (html.find(b'>', close) + 1) if close >= 0 else n
        else:
            i = j + 1

def _inner(html, open_end, name):
    depth = 1
    for kind, nm, s, e, _ in _scan(html[open_end:]):
        if nm != name: continue
        if kind == 'open': depth += 1
        elif kind == 'close':
            depth -= 1
            if depth == 0: return (open_end, open_end + s)
    return (open_end, len(html))

def _targets(html):
    idx, lists, stack, inl = [], {}, [], 0
    for kind, name, s, e, attrs in _scan(html):
        if kind == 'open':
            is_el = b'data-editlist' in attrs
            if is_el: lists[attrs[b'data-editlist'].decode('utf-8', 'replace')] = (name, e)
            if b'data-edit' in attrs and inl == 0: idx.append((name, e))
            stack.append((name, is_el))
            if is_el: inl += 1
        elif kind == 'close':
            for k in range(len(stack) - 1, -1, -1):
                if stack[k][0] == name:
                    if stack[k][1]: inl -= 1
                    del stack[k:]; break
    return idx, lists

def apply_edits(html, t, l):
    idx, lists = _targets(html)
    patches = []
    for k, v in (t or {}).items():
        try: i = int(k)
        except (TypeError, ValueError): continue
        if 0 <= i < len(idx):
            name, oe = idx[i]; a, b = _inner(html, oe, name)
            patches.append((a, b, v.encode('utf-8')))
    for name_key, v in (l or {}).items():
        if name_key in lists:
            tag, oe = lists[name_key]; a, b = _inner(html, oe, tag)
            patches.append((a, b, v.encode('utf-8')))
    for a, b, nb in sorted(patches, key=lambda p: p[0], reverse=True):
        html = html[:a] + nb + html[b:]
    return html

class H(http.server.SimpleHTTPRequestHandler):
    def log_message(self, fmt, *args):
        try: super().log_message(fmt, *args)
        except Exception: pass          # a broken stdout must never kill the server
    def _is_deck(self):
        p = self.path.split("?")[0].lstrip("/")
        return p == "" or p == deck
    def do_POST(self):
        if self.path.split("?")[0] != "/__save":
            self.send_error(404); return
        try:
            n = int(self.headers.get("Content-Length", 0))
            body = json.loads(self.rfile.read(n).decode("utf-8"))
            with open(deck, "rb") as f: html = f.read()
            out = apply_edits(html, body.get("t") or {}, body.get("l") or {})
            if out != html:
                tmp = deck + ".tmp"
                with open(tmp, "wb") as f: f.write(out)
                os.replace(tmp, deck)          # atomic; hot-reload sees the new mtime
            self.send_response(200); self.send_header("Content-Length", "2")
            self.send_header("Cache-Control", "no-store"); self.end_headers(); self.wfile.write(b"ok")
        except Exception as exc:
            self.send_response(500); self.send_header("Content-Length", "0")
            self.end_headers()
            try: sys.stderr.write("save failed: %r\n" % (exc,))
            except Exception: pass
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
