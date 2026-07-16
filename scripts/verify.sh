#!/usr/bin/env bash
# Single-file deck integrity check. Usage: ./verify.sh path/to/deck.html
set -u
F="${1:?usage: verify.sh <deck.html>}"
[ -f "$F" ] || { echo "no such file: $F"; exit 1; }
python3 - "$F" <<'PY'
import sys, io, re
f=sys.argv[1]; s=io.open(f,encoding="utf-8").read()
ok=True
def check(name, cond, extra=""):
    global ok
    print(("  OK  " if cond else " FAIL ")+name+("" if cond else "  "+extra))
    ok = ok and cond
sec_o,sec_c=s.count("<section"),s.count("</section>")
check("section tags balanced", sec_o==sec_c, f"{sec_o}/{sec_c}")
check("style tags balanced", s.count("<style")==s.count("</style>"))
check("script tags balanced", s.count("<script")==s.count("</script>"))
if "<style>" in s and "</style>" in s:
    css=s[s.index("<style>"):s.index("</style>")]
    check("CSS braces balanced", css.count("{")==css.count("}"), f"{css.count('{')}/{css.count('}')}")
# external requests: flag src/href/url() pointing at http(s) (data: and relative are fine)
ext=re.findall(r'(?:src|href)\s*=\s*["\']https?://[^"\']+', s) + re.findall(r'url\(\s*["\']?https?://', s)
check("no external http(s) assets", len(ext)==0, f"{len(ext)} found (inline them for a shippable single file)")
check("has editable text (data-edit)", "data-edit" in s)
check("theme toggle wired", "toggleTheme" in s and 'data-theme="warm"' in s)
check("edit mode wired", "toggleEdit" in s)
check("slides present", s.count('class="slide')>=3)
# nav signpost present
check("nav signpost present", 'class="nav-links"' in s)
print()
print("RESULT:", "PASS" if ok else "ISSUES — fix the FAIL lines above")
sys.exit(0 if ok else 2)
PY
