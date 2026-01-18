# Discrete Logarithmic Structure in Fermion Mass Data

This repository contains the complete LaTeX sources, figures, and reproducible analysis
for two related research papers investigating empirical structure in the Standard Model
fermion mass spectrum.

## Overview

**Paper I** documents an unexpected clustering of fermion masses when expressed in
logarithmic coordinates under fixed conventions. The analysis is strictly empirical and
does not assume an underlying flavor symmetry or dynamical mechanism.

**Paper II** is a technical companion paper that validates the numerical robustness of
the empirical findings. It addresses reproducibility, stability under perturbations, and
explicit falsifiability criteria using a deterministic analysis pipeline.

Together, the two papers form a coherent empirical study supported by a transparent and
auditable computational framework.

## Contents

- `papers/CORE_MASTER.tex`  
  Primary manuscript (Paper I), submission-ready.

- `papers/paper_II/`  
  Companion validation manuscript (Paper II).

- `papers/sections/`  
  Sectioned LaTeX sources and figure files.

- `shared/`  
  Shared macros and bibliography.

- `scripts/`  
  Build and maintenance scripts for reproducible compilation.

## Build Instructions

A standard LaTeX toolchain with `latexmk` and `biber` is required.

From the `papers/` directory:

```bash
latexmk -pdf CORE_MASTER.tex
