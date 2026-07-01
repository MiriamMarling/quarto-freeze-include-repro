# quarto-freeze-include-repro

Minimal, self-contained reproduction for a Quarto `freeze: auto` correctness bug.

## Status by Quarto version

Each version runs on every push and every Monday. A **red badge means the bug
still reproduces** on that version; green means it no longer does, and when a
version first turns green an issue is opened here as a heads-up.

| Quarto version | Repro |
|---|---|
| `release` (current stable) | [![Quarto release](https://img.shields.io/github/actions/workflow/status/MiriamMarling/quarto-freeze-include-repro/release.yml?branch=main&label=Quarto%20release)](https://github.com/MiriamMarling/quarto-freeze-include-repro/actions/workflows/release.yml) |
| `pre-release` (development build) | [![Quarto pre-release](https://img.shields.io/github/actions/workflow/status/MiriamMarling/quarto-freeze-include-repro/pre-release.yml?branch=main&label=Quarto%20pre-release)](https://github.com/MiriamMarling/quarto-freeze-include-repro/actions/workflows/pre-release.yml) |
| `1.9.37` (originally reported) | [![Quarto 1.9.37](https://img.shields.io/github/actions/workflow/status/MiriamMarling/quarto-freeze-include-repro/pinned.yml?branch=main&label=Quarto%201.9.37)](https://github.com/MiriamMarling/quarto-freeze-include-repro/actions/workflows/pinned.yml) |

**Summary.** In a `type: manuscript` project whose article `{{< include >}}`s
another `.qmd`, `execute.freeze: auto` does **not** invalidate the article's
frozen output when the *included* file changes. The render keeps showing the old
content, including plain Markdown changes (figure paths, written content), not just code
output. No error is raised, so the build "succeeds" while the rendered article
disagrees with the source on disk. The **same include pattern in a `type: default`
project re-renders correctly**, which localizes the defect to the manuscript
project type.

Likely a manuscript-specific variant of
[quarto-dev/quarto-cli#6793](https://github.com/quarto-dev/quarto-cli/issues/6793).

## What's here

| File | Role |
|---|---|
| `repro-manuscript.sh` | **Bug case**: exits **1** while the bug is present, 0 once fixed |
| `repro-default.sh` | **Control**: `type: default` re-renders correctly, exits **0** |
| `expected-output.txt` | What a correct Quarto should produce |
| `actual-output.txt` | What Quarto 1.9.37 actually produces |
| `.github/workflows/repro.yml` | Reusable job: runs the control and bug scripts for one Quarto version |
| `.github/workflows/release.yml`, `pre-release.yml`, `pinned.yml` | Call the reusable job on `release`, `pre-release`, and `1.9.37` |

Each script writes its own tiny project to a temp dir, renders twice, and greps a
marker. Nothing else in this repo is touched.

## Reading the CI

Three workflows run the same reproduction, one per Quarto version (`release`,
`pre-release`, and the originally reported `1.9.37`), on every push and every
Monday at 12:00 UTC. Each runs the **control** (expected green) and the **bug**
case (expected **red while the bug exists**), so a **red badge means the bug is
still present on that version**; the day Quarto fixes it, that version's badge
turns green and an issue is opened here (assigned to the repo owner) as a
notification.

Testing `pre-release` shows whether a fix has already landed on Quarto's
development branch. As of 2026-07-01 all three fail, so the bug is present on the
current release and the development build, not only on `1.9.37`.

A failing run looks like this (the script's own markers; the verbose render
output is omitted):

```
render 1: MARKER-ALPHA present (ok)
...
FAIL (bug present): still MARKER-ALPHA after editing the include
freeze: auto did not invalidate on the included-file change.
```

Live runs:
<https://github.com/MiriamMarling/quarto-freeze-include-repro/actions>

## Run locally

From a fresh clone to the failing exit code in three lines:

```bash
git clone https://github.com/MiriamMarling/quarto-freeze-include-repro
cd quarto-freeze-include-repro
bash repro-manuscript.sh   # exits 1 while the bug is present
```

Both scripts, run directly:

```bash
bash repro-default.sh     # control: prints PASS, exit 0
bash repro-manuscript.sh  # bug: prints FAIL (bug present), exit 1
```

Requires `quarto` on `PATH` and the knitr (R) engine (`knitr`, `rmarkdown`).

## The bug, in four steps (manuscript project)

1. Render a manuscript project whose article does `{{< include _body.qmd >}}`.
2. Change **only** `_body.qmd`: `MARKER-ALPHA` → `MARKER-BETA`.
3. Re-render with `execute.freeze: auto`.
4. Output still shows `MARKER-ALPHA`. Only `rm -rf _freeze` recovers `MARKER-BETA`
   (`touch index.qmd` does **not**; the freeze key appears to depend on the
   article file's own content, not its transitive includes).

## Tested on

Locally: Quarto **1.9.37**, Pandoc **3.8.3**, R **4.6.0** / knitr **1.51**, macOS
Tahoe **26.5.1** arm64. In CI on `ubuntu-latest`: Quarto **release**,
**pre-release**, and **1.9.37**, on every push and weekly (see the badges above).

## License

Released into the public domain under [The Unlicense](LICENSE); copy the scripts
into a test suite freely, no attribution required.

## Author and review

Miriam Marling, miriam@bonquery.ca

I prepared this reproduction with the help of an AI assistant. I reviewed, ran,
and verified the test case and results myself before posting it to
[quarto-dev/quarto-cli#6793](https://github.com/quarto-dev/quarto-cli/issues/6793).
