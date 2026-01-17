# ============================================================
# RX: Add results blocks + derivation prose to CORE paper
# Safe insertion, no restructuring.
# ============================================================

$Root   = "C:\Users\Your Name Here\Desktop\Golden_Unification"
$Papers = Join-Path $Root "papers"
$Secs   = Join-Path $Papers "sections"
$Shared = Join-Path $Root "shared"

function Require-File($p) {
  if (-not (Test-Path $p)) { throw "Missing required file: $p" }
}

Require-File (Join-Path $Shared "paperV_mixing_results.tex")
Require-File (Join-Path $Shared "paperIII_results.tex")
Require-File (Join-Path $Secs   "06_holonomy_mixing.tex")
Require-File (Join-Path $Secs   "03_results.tex")

# ---------- Append CKM/PMNS numerical block ----------
$mixingResults = @"
\subsection{Numerical results: CKM and PMNS scans}
\label{subsec:mixing_results}

The numerical outputs reported below are generated deterministically from the scan protocol described above.
All inputs are taken from current global-fit values, and no continuous parameters are adjusted.

\input{../shared/paperV_mixing_results.tex}
"@

Add-Content -Path (Join-Path $Secs "06_holonomy_mixing.tex") -Value $mixingResults
Write-Host "Inserted CKM/PMNS results block." -ForegroundColor Green

# ---------- Append mass-lattice results block ----------
$massResults = @"
\subsection{Numerical mass-lattice fits}
\label{subsec:mass_results}

The following table summarizes the best-fit lattice assignments obtained under the anchored model.
Multiplicity counts are reported explicitly to distinguish unique solutions from controlled degeneracies.

\input{../shared/paperIII_results.tex}
"@

Add-Content -Path (Join-Path $Secs "03_results.tex") -Value $massResults
Write-Host "Inserted mass-lattice results block." -ForegroundColor Green

# ---------- Build CORE_MASTER ----------
Push-Location $Papers
Write-Host "`nCompiling CORE_MASTER.tex..." -ForegroundColor Cyan
pdflatex -interaction=nonstopmode CORE_MASTER.tex | Out-Null
Write-Host "Build OK:" -ForegroundColor Cyan
Write-Host ("  PDF: " + (Join-Path $Papers "CORE_MASTER.pdf")) -ForegroundColor Cyan
Pop-Location

Write-Host "`nDone." -ForegroundColor Green
