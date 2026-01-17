# ============================================================
# rx_add_06b_results_summary_and_build.ps1
# Create Section 06b (results/interpretation bridge) and build.
# SAFE: avoids PowerShell $(...) interpolation issues.
# ============================================================

$ErrorActionPreference = "Stop"

$root        = "C:\Users\Your Name Here\Desktop\Golden_Unification"
$papersDir   = Join-Path $root "papers"
$sectionsDir = Join-Path $papersDir "sections"

$coreMaster  = Join-Path $papersDir "CORE_MASTER.tex"
$master      = Join-Path $papersDir "MASTER.tex"

$secFile     = Join-Path $sectionsDir "06b_results_summary.tex"
$includeLine = "\input{sections/06b_results_summary.tex}"

function Ensure-Dir([string]$p) {
  if (-not (Test-Path -LiteralPath $p)) {
    New-Item -ItemType Directory -Path $p | Out-Null
    Write-Host "Created directory: $p" -ForegroundColor Green
  } else {
    Write-Host "Directory exists: $p" -ForegroundColor DarkGray
  }
}

function Write-Lines([string]$path, [string[]]$lines) {
  Set-Content -LiteralPath $path -Value $lines -Encoding UTF8
  Write-Host ("Wrote file: " + $path) -ForegroundColor Green
}

function Insert-Include-IfMissing([string]$texPath, [string]$lineToInsert, [string]$afterPattern) {
  if (-not (Test-Path -LiteralPath $texPath)) {
    throw "Missing TeX file: $texPath"
  }

  $lines = Get-Content -LiteralPath $texPath

  if ($lines -contains $lineToInsert) {
    Write-Host ("Already present in: " + $texPath) -ForegroundColor DarkGray
    Write-Host ("  = " + $lineToInsert) -ForegroundColor DarkGray
    return
  }

  $idx = -1
  for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match $afterPattern) { $idx = $i; break }
  }

  if ($idx -lt 0) {
    throw ("Could not find insertion anchor pattern in " + $texPath + ": " + $afterPattern)
  }

  $newLines = @()
  $newLines += $lines[0..$idx]
  $newLines += $lineToInsert
  if ($idx -lt ($lines.Count - 1)) {
    $newLines += $lines[($idx+1)..($lines.Count-1)]
  }

  Set-Content -LiteralPath $texPath -Value $newLines -Encoding UTF8
  Write-Host ("Inserted into: " + $texPath) -ForegroundColor Cyan
  Write-Host ("  + " + $lineToInsert) -ForegroundColor Cyan
}

function Build-Tex([string]$texName) {
  $texPath = Join-Path $papersDir $texName
  if (-not (Test-Path -LiteralPath $texPath)) { throw "Missing: $texPath" }

  Write-Host ""
  Write-Host ("Compiling " + $texName + "...") -ForegroundColor Cyan

  Push-Location $papersDir
  try {
    & pdflatex -interaction=nonstopmode $texName | Out-Null
    & pdflatex -interaction=nonstopmode $texName | Out-Null
  } finally {
    Pop-Location
  }

  $pdf = Join-Path $papersDir ($texName -replace "\.tex$", ".pdf")
  if (Test-Path -LiteralPath $pdf) {
    Write-Host ("Build OK: " + $pdf) -ForegroundColor Green
  } else {
    throw ("Build failed; PDF not found: " + $pdf)
  }
}

Ensure-Dir $sectionsDir

# IMPORTANT:
# Use single-quoted PowerShell strings whenever LaTeX contains $(...) or $...$.
# Also avoid apostrophes in text to keep single-quoted strings safe.

$sec = @(
'% ============================================================',
'% Paper VI.B section: results/interpretation bridge',
'% File: papers/sections/06b_results_summary.tex',
'% ============================================================',
'',
'\section{Numerical mixing results and interpretation}',
'\label{sec:mixing_results_summary}',
'',
'This section is a results-oriented bridge between the holonomy hypothesis and the formal verification narrative.',
'The numerical outputs themselves are externalized as a versioned artifact and are included verbatim in Section~\ref{sec:holonomy_mixing}.',
'Here we state only what is being tested and what constitutes success or failure.',
'',
'\subsection{What is fixed, what is scanned}',
'Given fixed global-fit inputs $s_{12}, s_{23}, s_{13}$ for CKM or PMNS, we scan a Dirac CP phase',
'$\delta \in [0^\circ,360^\circ]$ on a dense grid and select the best match to a model-supplied holonomy angle $\theta_{\star}$',
'using a pre-registered matching rule (degree-space or sine-space). The Jarlskog invariant $J$ is then computed as a consistency check.',
'',
'\subsection{What is reported and why it is verification-grade}',
'The repository script \texttt{code/verify\_mixing.py} prints all inputs and returns a deterministic best-fit phase $\delta$',
'along with the match score and $J$. It also writes a LaTeX-ready block to \texttt{shared/paperV\_mixing\_results.tex}, which is treated',
'as an externalized, versioned artifact. Under this workflow, the paper never depends on manual copy-paste of numeric results.',
'',
'\subsection{Interpretation}',
'This verification step establishes that the scan-and-match protocol is implemented correctly and that a chosen $\theta_{\star}$ produces',
'a definite phase assignment and $J$ once the input sines are fixed. The substantive physics claim is that $\theta_{\star}$ is fixed by an',
'independent geometric mechanism and remains stable under updated global fits, scheme choices, and pre-registered matching rules.',
'',
'\subsection{Falsifiability triggers}',
'The holonomy-phase program fails if (i) modest updates of global-fit inputs destabilize the inferred phase beyond stated tolerances,',
'(ii) the matching rule must be changed after inspecting outcomes, or (iii) the quark and lepton sectors cannot be made simultaneously consistent',
'with a single geometric prescription for $\theta_{\star}$ once that prescription is stated explicitly.'
)

Write-Lines $secFile $sec

# Insert after 06_holonomy_mixing include
$anchorPattern = "sections/06_holonomy_mixing\.tex"
Insert-Include-IfMissing $coreMaster $includeLine $anchorPattern
Insert-Include-IfMissing $master     $includeLine $anchorPattern

Build-Tex "CORE_MASTER.tex"
Build-Tex "MASTER.tex"

Write-Host ""
Write-Host "DONE." -ForegroundColor Cyan
