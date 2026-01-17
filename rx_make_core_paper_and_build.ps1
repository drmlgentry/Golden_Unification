Set-Location "C:\Users\Your Name Here\Desktop\Golden_Unification"

@'
# ============================================================
# RX: Build a consolidated "core" paper (Papers III–VI merged)
# Writes:
#   papers\Paper_Core.tex
#   papers\CORE_MASTER.tex
# Then compiles CORE_MASTER.tex -> CORE_MASTER.pdf
# ============================================================

$Root = (Resolve-Path ".").Path
$PapersDir = Join-Path $Root "papers"

function Ensure-Dir {
  param([Parameter(Mandatory=$true)][string]$Path)
  if (-not (Test-Path -LiteralPath $Path)) {
    New-Item -ItemType Directory -Path $Path | Out-Null
    Write-Host "Created directory: $Path" -ForegroundColor Green
  } else {
    Write-Host "Directory exists:  $Path" -ForegroundColor DarkGray
  }
}

function Write-UTF8 {
  param(
    [Parameter(Mandatory=$true)][string]$Path,
    [Parameter(Mandatory=$true)][string]$Content
  )
  $Content | Set-Content -Path $Path -Encoding UTF8
  Write-Host "Wrote file:         $Path" -ForegroundColor Green
}

Ensure-Dir $PapersDir

# ------------------------------------------------------------
# Paper_Core.tex (the consolidated long paper)
# Re-orders sections into a clean narrative:
#   log structure -> lattice -> methods -> results -> discussion
#   -> CKM -> PMNS -> holonomy audit -> predictions -> falsifiability
# And injects external results blocks from shared/
# ------------------------------------------------------------
$PaperCore = @'
\documentclass[11pt]{article}

\usepackage{amsmath,amssymb}
\usepackage{graphicx}
\usepackage{hyperref}

% Shared macros (loaded exactly once)
\input{../shared/macros.tex}

\title{Golden Unification Core: Discrete Logarithmic Mass Lattices and Holonomy Matching of CKM/PMNS Phases}
\author{}
\date{\today}

\begin{document}
\maketitle

% ---------- Core narrative (consolidated) ----------
\input{sections/01_log_structure.tex}
\input{sections/02_lattice.tex}

% Methods BEFORE results (keeps reviewers calm)
\input{sections/05_methods.tex}

% Mass results + anchored tables (externalized)
\input{sections/03_results.tex}
\input{../shared/paperIII_results.tex}

% Interpretation limits / positioning
\input{sections/04_discussion.tex}

% ---------- Mixing + CP phase verification ----------
\input{sections/04_ckm.tex}
\input{sections/05_pmns.tex}

% Holonomy audit protocol + match rules
\input{sections/06_holonomy_mixing.tex}

% Externalized CKM/PMNS scan output block
\input{../shared/paperV_mixing_results.tex}

% ---------- Forward-looking but falsifiable ----------
\input{sections/07_predictions.tex}
\input{sections/08_falsifiability.tex}

\end{document}
'@

# ------------------------------------------------------------
# CORE_MASTER.tex (build target)
# ------------------------------------------------------------
$CoreMaster = @'
\documentclass[11pt]{article}
\begin{document}
\input{Paper_Core.tex}
\end{document}
'@

Write-UTF8 (Join-Path $PapersDir "Paper_Core.tex") $PaperCore
Write-UTF8 (Join-Path $PapersDir "CORE_MASTER.tex") $CoreMaster

# ------------------------------------------------------------
# Compile
# ------------------------------------------------------------
Write-Host ""
Write-Host "Compiling CORE_MASTER.tex..." -ForegroundColor Cyan

Push-Location $PapersDir
pdflatex -interaction=nonstopmode .\CORE_MASTER.tex | Out-Null
Pop-Location

$Pdf = Join-Path $PapersDir "CORE_MASTER.pdf"
$Log = Join-Path $PapersDir "CORE_MASTER.log"

Write-Host ""
if (Test-Path -LiteralPath $Pdf) {
  Write-Host "Build OK:" -ForegroundColor Green
  Write-Host ("  PDF: " + $Pdf) -ForegroundColor Green
  Write-Host ("  LOG: " + $Log) -ForegroundColor Green
} else {
  Write-Host "Build FAILED. Check:" -ForegroundColor Red
  Write-Host ("  LOG: " + $Log) -ForegroundColor Red
}
'@ | Set-Content -Path ".\rx_make_core_paper_and_build.ps1" -Encoding UTF8

Write-Host "Wrote script: .\rx_make_core_paper_and_build.ps1" -ForegroundColor Green
