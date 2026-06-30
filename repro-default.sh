#!/usr/bin/env bash
# CONTROL: identical include + freeze: auto in a `type: default` project.
# This re-renders correctly, so it should PASS (exit 0) — proving the defect is
# specific to the manuscript project type.
set -euo pipefail
work="$(mktemp -d)"; trap 'rm -rf "$work"' EXIT; cd "$work"

cat > _quarto.yml <<'YML'
project:
  type: default
execute:
  freeze: auto
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

out=index.html
quarto render index.qmd --to html
grep -q MARKER-ALPHA "$out" || { echo "setup error: ALPHA missing in first render"; exit 2; }
echo "render 1: MARKER-ALPHA present (ok)"

perl -pi -e 's/MARKER-ALPHA/MARKER-BETA/' _body.qmd
quarto render index.qmd --to html

if grep -q MARKER-BETA "$out"; then
  echo "PASS: include change picked up (MARKER-BETA) in default project."
  exit 0
else
  echo "UNEXPECTED: default project also stale."
  exit 1
fi
