# ============================================================
# rx_make_core_long_and_build.ps1
# Creates a single-file consolidated TeX from sections/
# and compiles it -> Paper_CORE_LONG.pdf
# SAFE ASCII, no smart quotes, no hanging heredocs.
# ============================================================

$ErrorActionPreference = "Stop"

$root   = "C:\Users\Your Name Here\Desktop\Golden_Unification"
$papers = Join-Path $root "papers"
$secs   = Join-Path $papers "sections"

$texOut = Join-Path $papers "Paper_CORE_LONG.tex"

if (-not (Test-Path -LiteralPath $papers)) { throw "Missing: $papers" }
if (-not (Test-Path -LiteralPath $secs))   { throw "Missing: $secs" }

# Order of sections to stitch (edit if you want a different order)
$sectionFiles = @(
  "01_log_structure.tex",
  "02_lattice.tex",
  "03_results.tex",
  "04_discussion.tex",
  "05_methods.tex",
  "06_holonomy_mixing.tex",
  "07_predictions.tex",
  "08_falsifiability.tex",
  "09_null_hypotheses.tex"
)

# Verify section files exist
foreach ($sf in $sectionFiles) {
  $p = Join-Path $secs $sf
  if (-not (Test-Path -LiteralPath $p)) {
    throw ("Missing section file: " + $p)
  }
}

# Write header
$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("% ============================================================")
$lines.Add("% Paper_CORE_LONG.tex (AUTO-GENERATED)")
$lines.Add("% Single-file consolidated core paper")
$lines.Add("% ============================================================")
$lines.Add("")
$lines.Add("\documentclass[11pt]{article}")
$lines.Add("")
$lines.Add("\usepackage{amsmath,amssymb}")
$lines.Add("\usepackage{graphicx}")
$lines.Add("\usepackage{hyperref}")
$lines.Add("\usepackage{booktabs}")
$lines.Add("")
$lines.Add("% Shared macros (loaded exactly once)")
$lines.Add("\input{../shared/macros.tex}")
$lines.Add("")
$lines.Add("\begin{document}")
$lines.Add("")

# Append each section with clear boundaries
foreach ($sf in $sectionFiles) {
  $p = Join-Path $secs $sf
  $lines.Add("% ------------------------------------------------------------")
  $lines.Add("% BEGIN SECTION: " + $sf)
  $lines.Add("% ------------------------------------------------------------")
  $lines.Add("")
  $content = Get-Content -LiteralPath $p
  foreach ($ln in $content) { $lines.Add($ln) }
  $lines.Add("")
  $lines.Add("% ------------------------------------------------------------")
  $lines.Add("% END SECTION: " + $sf)
  $lines.Add("% ------------------------------------------------------------")
  $lines.Add("")
}

$lines.Add("\end{document}")
$lines.Add("")

# Write TeX output
$lines | Set-Content -LiteralPath $texOut -Encoding UTF8
Write-Host ("Wrote: " + $texOut) -ForegroundColor Green

# Compile from papers/ to keep relative paths stable
Push-Location $papers
Write-Host "Compiling Paper_CORE_LONG.tex..." -ForegroundColor Cyan

pdflatex -interaction=nonstopmode Paper_CORE_LONG.tex | Out-Host

$pdf = Join-Path $papers "Paper_CORE_LONG.pdf"
if (Test-Path -LiteralPath $pdf) {
  Write-Host ("Build OK: " + $pdf) -ForegroundColor Green
} else {
  throw "Build failed: Paper_CORE_LONG.pdf not found."
}

Pop-Location
