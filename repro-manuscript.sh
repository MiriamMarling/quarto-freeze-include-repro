#!/usr/bin/env bash
# BUG case: in a `type: manuscript` project, `execute.freeze: auto` does NOT
# invalidate the article's frozen output when an *included* .qmd changes.
# Exits 1 while the bug is present (CI stays RED), 0 once Quarto fixes it.
set -euo pipefail
work="$(mktemp -d)"; trap 'rm -rf "$work"' EXIT; cd "$work"

cat > _quarto.yml <<'YML'
project:
  type: manuscript
manuscript:
  article: index.qmd
execute:
  freeze: auto
format:
  html: default
YML
cat > index.qmd <<'QMD'
---
title: Repro
---
{{< include _body.qmd >}}
QMD
cat > _body.qmd <<'QMD'
MARKER-ALPHA

```{r}
#| echo: false
1 + 1
```
QMD

out=_manuscript/index.html
quarto render
grep -q MARKER-ALPHA "$out" || { echo "setup error: ALPHA missing in first render"; exit 2; }
echo "render 1: MARKER-ALPHA present (ok)"

perl -pi -e 's/MARKER-ALPHA/MARKER-BETA/' _body.qmd   # edit ONLY the include
quarto render

if grep -q MARKER-BETA "$out"; then
  echo "PASS: include change picked up (MARKER-BETA). Bug appears fixed."
  exit 0
else
  echo "FAIL (bug present): still $(grep -o 'MARKER-[A-Z]*' "$out" | head -1) after editing the include"
  echo "freeze: auto did not invalidate on the included-file change."
  exit 1
fi
