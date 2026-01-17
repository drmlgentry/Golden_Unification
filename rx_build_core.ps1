# ============================================================
# RX: Build consolidated CORE paper (III–VI)
# Safe: no embedded LaTeX blocks
# ============================================================

$Root = "C:\Users\Your Name Here\Desktop\Golden_Unification"
$Papers = Join-Path $Root "papers"

$CoreMaster = @"
\documentclass[11pt]{article}

\usepackage{amsmath,amssymb}
\usepackage{graphicx}
\usepackage{hyperref}

\input{../shared/macros.tex}

\begin{document}

\input{sections/01_log_structure.tex}
\input{sections/02_lattice.tex}
\input{sections/05_methods.tex}

\input{sections/03_results.tex}
\input{../shared/paperIII_results.tex}

\input{sections/04_discussion.tex}

\input{sections/04_ckm.tex}
\input{sections/05_pmns.tex}
\input{sections/06_holonomy_mixing.tex}
\input{../shared/paperV_mixing_results.tex}

\input{sections/07_predictions.tex}
\input{sections/08_falsifiability.tex}

\end{document}
"@

$OutFile = Join-Path $Papers "CORE_MASTER.tex"
$CoreMaster | Set-Content -Path $OutFile -Encoding UTF8
Write-Host "Wrote: $OutFile" -ForegroundColor Green

Push-Location $Papers
pdflatex -interaction=nonstopmode CORE_MASTER.tex
Pop-Location

Write-Host "Build finished. Check CORE_MASTER.pdf" -ForegroundColor Cyan
