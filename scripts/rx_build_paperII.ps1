[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'

$root = (Resolve-Path ".").Path
$tex  = Join-Path $root "papers\paper_II\Paper_II_EPJC.tex"
$out  = Join-Path $root "dist\paper_II"
if (-not (Test-Path -LiteralPath $out)) { New-Item -ItemType Directory -Path $out | Out-Null }

Write-Host "Building Paper II:"
Write-Host "  Source: $tex"
Write-Host "  OutDir: $out"

# latexmk is preferred if available; else fall back to pdflatex
$latexmk = Get-Command latexmk -ErrorAction SilentlyContinue
if ($latexmk) {
  latexmk -pdf -interaction=nonstopmode -file-line-error -outdir="$out" "$tex"
} else {
  Push-Location (Split-Path -Parent $tex)
  pdflatex -interaction=nonstopmode -file-line-error "$tex"
  Pop-Location
}

Write-Host "Done."
