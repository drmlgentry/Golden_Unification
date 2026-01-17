[CmdletBinding()]
param(
  [ValidateSet('MASTER','CORE_MASTER')][string[]]$Targets = @('MASTER','CORE_MASTER'),
  [switch]$Clean,
  [switch]$UseLatexmk
)

<#[
.SYNOPSIS
  Build the LaTeX PDFs in papers/ using either pdflatex or latexmk.

.DESCRIPTION
  Runs from repo root and builds one or both of:
    - papers/MASTER.tex
    - papers/CORE_MASTER.tex

  If -UseLatexmk is provided, latexmk is used with nonstopmode. Otherwise we call
  pdflatex twice per target to resolve references.

  If -Clean is provided, common auxiliary files in papers/ are removed first.

.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\rx_build_papers.ps1

.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\rx_build_papers.ps1 -Targets CORE_MASTER -UseLatexmk
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path '.').Path
$papersDir = Join-Path $repoRoot 'papers'
if (-not (Test-Path -LiteralPath $papersDir)) {
  throw "Expected papers/ directory at: $papersDir"
}

if ($Clean) {
  Write-Host 'Cleaning auxiliary files in papers/ ...'
  $patterns = @('*.aux','*.bbl','*.blg','*.fls','*.fdb_latexmk','*.log','*.out','*.toc','*.synctex.gz')
  foreach ($p in $patterns) {
    Get-ChildItem -LiteralPath $papersDir -Filter $p -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
  }
}

function Invoke-PdflatexTwice {
  param([Parameter(Mandatory=$true)][string]$BaseName)

  $tex = Join-Path $papersDir ($BaseName + '.tex')
  if (-not (Test-Path -LiteralPath $tex)) { throw "Missing TeX target: $tex" }

  Write-Host "pdflatex: $BaseName (pass 1)"
  & pdflatex -interaction=nonstopmode -recorder -output-directory=$papersDir $tex | Out-Host
  if ($LASTEXITCODE -ne 0) { throw "pdflatex failed for $BaseName (pass 1)" }

  Write-Host "pdflatex: $BaseName (pass 2)"
  & pdflatex -interaction=nonstopmode -recorder -output-directory=$papersDir $tex | Out-Host
  if ($LASTEXITCODE -ne 0) { throw "pdflatex failed for $BaseName (pass 2)" }
}

function Invoke-Latexmk {
  param([Parameter(Mandatory=$true)][string]$BaseName)

  $tex = Join-Path $papersDir ($BaseName + '.tex')
  if (-not (Test-Path -LiteralPath $tex)) { throw "Missing TeX target: $tex" }

  Write-Host "latexmk: $BaseName"
  & latexmk -pdf -interaction=nonstopmode -file-line-error -outdir=$papersDir $tex | Out-Host
  if ($LASTEXITCODE -ne 0) { throw "latexmk failed for $BaseName" }
}

foreach ($t in $Targets) {
  if ($UseLatexmk) {
    Invoke-Latexmk -BaseName $t
  } else {
    Invoke-PdflatexTwice -BaseName $t
  }
  $pdf = Join-Path $papersDir ($t + '.pdf')
  if (Test-Path -LiteralPath $pdf) {
    $len = (Get-Item -LiteralPath $pdf).Length
    Write-Host "Built: $pdf ($len bytes)"
  }
}

Write-Host 'DONE'
