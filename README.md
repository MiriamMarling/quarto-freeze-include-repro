# quarto-freeze-include-repro

Minimal, self-contained reproduction for a Quarto `freeze: auto` correctness bug.

**Summary.** In a `type: manuscript` project whose article `{{< include >}}`s
another `.qmd`, `execute.freeze: auto` does **not** invalidate the article's
frozen output when the *included* file changes. The render keeps showing the old
content — including plain Markdown changes (figure paths, prose), not just code
output. No error is raised, so the build "succeeds" while the rendered article
disagrees with the source on disk. The **same include pattern in a `type: default`
project re-renders correctly**, which localizes the defect to the manuscript
project type.

Likely a manuscript-specific variant of
[quarto-dev/quarto-cli#6793](https://github.com/quarto-dev/quarto-cli/issues/6793).

## What's here

| File | Role |
|---|---|
| `repro-manuscript.sh` | **Bug case** — exits **1** while the bug is present, 0 once fixed |
| `repro-default.sh` | **Control** — `type: default` re-renders correctly, exits **0** |
| `expected-output.txt` | What a correct Quarto should produce |
| `actual-output.txt` | What Quarto 1.9.37 actually produces |
| `.github/workflows/repro.yml` | Runs both on `ubuntu-latest` |

Each script writes its own tiny project to a temp dir, renders twice, and greps a
marker — nothing else in this repo is touched.

## Reading the CI

The workflow runs the **control** (expected green) and the **bug** case (expected
**red while the bug exists**). So a **red badge means the bug is still present**;
when Quarto fixes it, the bug job turns green. It doubles as a regression test.

## Run locally

```bash
bash repro-default.sh     # control: prints PASS, exit 0
bash repro-manuscript.sh  # bug:     prints FAIL (bug present), exit 1
```

Requires `quarto` on `PATH` and the knitr (R) engine (`knitr`, `rmarkdown`).

## The bug, in four steps (manuscript project)

1. Render a manuscript project whose article does `{{< include _body.qmd >}}`.
2. Change **only** `_body.qmd`: `MARKER-ALPHA` → `MARKER-BETA`.
3. Re-render with `execute.freeze: auto`.
4. Output still shows `MARKER-ALPHA`. Only `rm -rf _freeze` recovers `MARKER-BETA`
   (`touch index.qmd` does **not** — the freeze key appears to depend on the
   article file's own content, not its transitive includes).

## Tested on

Quarto **1.9.37**, Pandoc **3.8.3**, R **4.6.0** / knitr **1.51**, macOS arm64;
also runs in CI on `ubuntu-latest` (see the workflow).

## Author

Miriam Marling · miriam@bonquery.ca

Repro developed with Claude Opus 4.8 (Anthropic Claude Code).
