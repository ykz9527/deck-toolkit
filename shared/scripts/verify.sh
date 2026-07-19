#!/usr/bin/env bash
# Single-file deck integrity + delivery-floor check. Usage: ./verify.sh path/to/deck.html
# Default target is the project's conventional output: showcase_deck/index.html
set -u
F="${1:-showcase_deck/index.html}"
[ -f "$F" ] || { echo "no deck at: $F  (build it to showcase_deck/index.html first)"; exit 1; }
python3 - "$F" <<'PY'
import sys, io, re
f=sys.argv[1]; raw=io.open(f,encoding="utf-8").read()
# analyse the real markup only: guidance comments legitimately mention tags and
# attributes, and counting those gives phantom failures / phantom passes.
s=re.sub(r'<!--.*?-->', '', raw, flags=re.S)
ok=True
def check(name, cond, extra=""):
    global ok
    print(("  OK  " if cond else " FAIL ")+name+("" if cond else "  → "+extra))
    ok = ok and cond

print("-- structure --")
sec_o,sec_c=s.count("<section"),s.count("</section>")
check("section tags balanced", sec_o==sec_c, f"{sec_o} open / {sec_c} close")
check("style tags balanced", s.count("<style")==s.count("</style>"))
check("script tags balanced", s.count("<script")==s.count("</script>"))
if "<style>" in s and "</style>" in s:
    css=s[s.index("<style>"):s.index("</style>")]
    check("CSS braces balanced", css.count("{")==css.count("}"), f"{css.count('{')}/{css.count('}')}")
check("slides present", s.count('class="slide')>=3)
check("nav signpost present", 'class="nav-links"' in s)
# duplicate ids silently break a duplicated interaction — the classic copy-paste bug.
# The lookbehind matters: \bid= also matches the tail of data-cell-id=, xml:id= etc,
# and an inlined drawio export is full of those — it reported 49 phantom duplicates.
ids=re.findall(r'(?<![\w:-])id\s*=\s*["\']([^"\']+)', s)
dup=sorted({i for i in ids if ids.count(i)>1})
check("no duplicate element ids", not dup, f"duplicated: {', '.join(dup)}")

print("-- single file (it must survive being emailed alone) --")
# Only flag what the page FETCHES. A plain <a href="https://…"> hyperlink is not an
# asset — it costs nothing until clicked and does not break offline rendering.
ext=(re.findall(r'\bsrc\s*=\s*["\']https?://[^"\']+', s)
     + re.findall(r'<link[^>]+href\s*=\s*["\']https?://[^"\']+', s, re.I)
     + re.findall(r'url\(\s*["\']?https?://', s))
check("no external http(s) assets", len(ext)==0, f"{len(ext)} found — inline them")
loc=[m for m in re.findall(r'\bsrc\s*=\s*["\']([^"\']+)', s) if not m.startswith("data:")]
check("no sibling asset files", not loc,
      f"{', '.join(sorted(set(loc))[:4])} — inline the markup (a drawio export goes IN the html, not beside it)")
check("no external stylesheet", not re.search(r'<link[^>]+stylesheet', s, re.I), "inline the CSS")

print("-- delivery floors (what the skill promises) --")
check("theme toggle wired", "toggleTheme" in s and 'data-theme="warm"' in s)
check("edit mode wired", "toggleEdit" in s and "data-edit" in s)
check("add/remove lists wired", "data-editlist" in s, "repeatable regions should be editable")
# an interaction root: the two shipped forms, plus data-interaction= for a bespoke one
roots=set(re.findall(r'data-(?:anim|cmp|interaction)\s*=\s*["\']([^"\']+)', s))
roots={r for r in roots if r}
n=len(roots)
check(f"at least 2 interactions (found {n}: {', '.join(sorted(roots)) or 'none'})", n>=2,
      "the floor is 2, aim 3, each a DIFFERENT form. If a real 2nd one won't come, "
      "read the repo deeper (workflow code, specs, data model) — do NOT pad with a hollow demo. "
      "Tag a bespoke interaction's root with data-interaction=\"name\" so it counts.")
# heuristic: a play/next pair under whatever prefix this deck named them (anPlay, x3Play…)
check("animation controls present",
      bool(re.search(r'\w*[Pp]lay\s*\(', s)) and bool(re.search(r'\w*[Nn]ext\s*\(', s)),
      "an interaction needs discrete stepping: play / next / reset")
figs=re.findall(r'class="apx-fig"(.{0,8000}?)</div>', s, re.S)
check("architecture diagram present", any(("<svg" in g or "<img" in g) for g in figs),
      "a deck with the architecture unillustrated is incomplete — use the drawio skill, "
      "or hand-author an inline SVG in the palette if its toolchain is absent. Never skip it.")
cov=re.search(r'class="slide cover"(.{0,20000}?)</section>', s, re.S)
# A portrait needn't be SVG — a strip of the project's REAL artifacts built in HTML is
# just as much a portrait. Mark it data-cover-fig so this check can see it.
check("cover carries a project-specific figure",
      bool(cov and ("<svg" in cov.group(1) or "<img" in cov.group(1) or "data-cover-fig" in cov.group(1))),
      "the cover is the first read — draw a portrait of THIS project (what it makes / its "
      "shape / its real screen); if it isn't an <svg>/<img>, mark it data-cover-fig. "
      "Test: swap in another project's name; if the figure still fits, it's filler.")
# the template's shapes are prompts, not answers — each carries a marker you delete
# once you've redrawn it. This is the one check the TEMPLATE itself fails, by design.
left=re.findall(r'PLACEHOLDER-REDRAW', raw)
check(f"no un-redrawn placeholders ({len(left)} left)", not left,
      "the template ships holes, not designs: the cover figure, both interaction stages "
      "and the architecture figure must be redrawn to this repo's real thing. Delete each "
      "PLACEHOLDER-REDRAW marker only after its shape is actually real.")

print("-- data-ref anchors (P1: picker/edit locating) --")
slide_tags = re.findall(r'<section[^>]*class="[^"]*slide[^"]*"[^>]*>', s)
slides_missing = [t for t in slide_tags if 'data-ref=' not in t]
check(f"every slide section has data-ref ({len(slide_tags)} slides)", not slides_missing,
      f"{len(slides_missing)} slide(s) missing data-ref — the picker locates by it")
iroots = re.findall(r'<[^>]*\bdata-(?:anim|cmp)="[^"]*"[^>]*>', s)
iroots_missing = [t for t in iroots if 'data-ref=' not in t]
check(f"every interaction root has data-ref ({len(iroots)} roots)", not iroots_missing,
      f"{len(iroots_missing)} interaction root(s) missing data-ref")

print()
print("RESULT:", "PASS" if ok else "ISSUES — fix the FAIL lines above")
sys.exit(0 if ok else 2)
PY
