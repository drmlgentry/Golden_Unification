# Golden Unification (reproducible paper + code)

This repository contains a reproducible LaTeX paper build and the deterministic code used to generate the numerical blocks included in the manuscript.

The paper does not hand-type computed tables. Instead, scripts write LaTeX blocks into `shared/`, and the manuscript includes those blocks verbatim via `\\input{...}`.

## What you can build

There are two build targets:

- `papers/MASTER.tex`: the full manuscript build.
- `papers/CORE_MASTER.tex`: a reduced/"core" build used for faster iteration.

## Papers and venue targets

The working plan is:

- **Paper I**: the foundational manuscript (program, lattice definition, core results) intended for **JHEP**.
- **Paper II**: the follow-on manuscript (expanded verification, controls/nulls, and referee-facing tightening) intended for **EPJ C**.

This repo keeps a single source tree; you differentiate paper/venue work with branches and paper-specific bundles.

## Recommended branch naming

Use a single, explicit convention so that `git log --all --decorate` remains self-explanatory:

- `paper-I-jhep`
- `paper-II-epjc`
- etc.

You can create these consistently via:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\rx_new_paper_branch.ps1 -Paper II -Target epjc -Checkout
```

## Requirements

- TeX Live 2025 (or newer) with `latexmk` available.
- Python 3.10+ for the deterministic generators/verification scripts.
- Windows PowerShell 5.1+ (the provided scripts are PowerShell-first).

## Directory structure

- `papers/` — LaTeX sources and section files.
  - `papers/sections/` — modular section files included by the master documents.
- `shared/` — machine-generated LaTeX blocks (tables/results) that are included verbatim.
- `code/` — deterministic generators/verification scripts that emit results into `shared/`.
- `scripts/` — PowerShell build/maintenance scripts (clean, build, bundle).

## Build instructions

From the repository root:

```powershell
# One-time sanity check + directory normalization
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\rx_setup_repo.ps1

# Full manuscript
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\rx_build_master.ps1

# Core build
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\rx_build_core.ps1
```

Alternatively, a single wrapper can build both targets:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\rx_build_papers.ps1 -Targets MASTER,CORE_MASTER
```

Outputs are written into `papers/` (the scripts use `latexmk` with an explicit `-outdir`).

## Reproducibility contract

1. Scripts in `code/` are the source of truth for computed numerical blocks.
2. Those scripts write LaTeX fragments into `shared/`.
3. The manuscript includes those fragments via `\\input{../shared/<file>.tex}`.
4. If a value appears in the PDF, it must be traceable to a script run that wrote the corresponding `shared/` file.

This is deliberate: it prevents the most common failure mode in quantitative manuscripts—silent copy/paste drift.

## Repository segregation strategy

As the project expands, the most stable way to "segregate" the repository is to keep a single source tree, but produce paper-specific release bundles for submission and archival.

This avoids the risk of breaking relative LaTeX paths (especially across `papers/`, `shared/`, and `code/`).

Use the bundling script:

```powershell
# Create a minimal source bundle for submission (no build artifacts)
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\rx_bundle_submission.ps1 -Target MASTER
```

The bundle is created under `dist/`.

## Git status / tracking

Only a subset of files may currently be committed. Before submission, we recommend:

- Add a repository-level `.gitignore` (provided in this repo).
- Commit the manuscript sources (`papers/`, `shared/`, `code/`, `scripts/`) and exclude build artifacts (`*.aux`, `*.log`, `*.fls`, `*.fdb_latexmk`, `*.synctex.gz`, PDFs).

## License and citation

- See `LICENSE` for terms.
- See `CITATION.cff` for citation metadata.
