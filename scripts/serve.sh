#!/usr/bin/env bash
# Serve the deck's directory on 0.0.0.0 so a browser (incl. LAN) can view it.
# Usage: ./serve.sh path/to/deck.html [port]
set -u
F="${1:?usage: serve.sh <deck.html> [port]}"
PORT="${2:-8770}"
DIR="$(cd "$(dirname "$F")" && pwd)"
BASE="$(basename "$F")"
IP="$(hostname -I 2>/dev/null | awk '{print $1}')"; [ -n "${IP:-}" ] || IP="127.0.0.1"
echo "Serving $DIR on 0.0.0.0:$PORT"
echo "Open:  http://$IP:$PORT/$BASE"
cd "$DIR" && exec python3 -m http.server "$PORT" --bind 0.0.0.0
