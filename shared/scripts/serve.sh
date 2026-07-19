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
