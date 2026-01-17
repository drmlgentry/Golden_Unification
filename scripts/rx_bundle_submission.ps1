<
.SYNOPSIS
  Create a clean submission bundle under dist/ without build artifacts.

.DESCRIPTION
  Copies the minimal set of sources required to compile MASTER/CORE_MASTER into dist/.
  Does NOT modify your working tree.

.PARAMETER OutDir
  Output directory (default: .\dist\EPJC_submission)

.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\rx_bundle_submission.ps1

.NOTES
  - Conservative by design: copies files rather than moving.
  - If your figures are external, ensure they exist and are included by the TeX sources.
>

param(
  [string]$OutDir = ".\dist\EPJC_submission"
)

$ErrorActionPreference = "Stop"

function Copy-IfExists($path, $dest) {
  if (Test-Path -LiteralPath $path) {
    $null = New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dest)
    Copy-Item -LiteralPath $path -Destination $dest -Force
  }
}

Write-Host "Bundling to $OutDir" -ForegroundColor Cyan

# Fresh bundle
if (Test-Path -LiteralPath $OutDir) { Remove-Item -Recurse -Force -LiteralPath $OutDir }
$null = New-Item -ItemType Directory -Force -Path $OutDir

# Core directories
$null = New-Item -ItemType Directory -Force -Path (Join-Path $OutDir "papers")
$null = New-Item -ItemType Directory -Force -Path (Join-Path $OutDir "papers\sections")
$null = New-Item -ItemType Directory -Force -Path (Join-Path $OutDir "shared")
$null = New-Item -ItemType Directory -Force -Path (Join-Path $OutDir "code")

# Papers
Copy-IfExists ".\papers\MASTER.tex" (Join-Path $OutDir "papers\MASTER.tex")
Copy-IfExists ".\papers\CORE_MASTER.tex" (Join-Path $OutDir "papers\CORE_MASTER.tex")

# Sections
Get-ChildItem -LiteralPath ".\papers\sections" -Filter "*.tex" | ForEach-Object {
  Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $OutDir ("papers\sections\" + $_.Name)) -Force
}

# Shared generated blocks
if (Test-Path -LiteralPath ".\shared") {
  Get-ChildItem -LiteralPath ".\shared" -Filter "*.tex" | ForEach-Object {
    Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $OutDir ("shared\" + $_.Name)) -Force
  }
}

# Macros / bibliography (if present)
Copy-IfExists ".\shared\macros.tex" (Join-Path $OutDir "shared\macros.tex")
Copy-IfExists ".\papers\refs.bib" (Join-Path $OutDir "papers\refs.bib")
Copy-IfExists ".\papers\bibliography.bib" (Join-Path $OutDir "papers\bibliography.bib")

# Deterministic generators (optional, but useful for reproducibility)
if (Test-Path -LiteralPath ".\code") {
  Copy-Item -Recurse -Force -LiteralPath ".\code\*" -Destination (Join-Path $OutDir "code")
}

# Top-level metadata
Copy-IfExists ".\README.md" (Join-Path $OutDir "README.md")
Copy-IfExists ".\.gitignore" (Join-Path $OutDir ".gitignore")
Copy-IfExists ".\CITATION.cff" (Join-Path $OutDir "CITATION.cff")
Copy-IfExists ".\LICENSE" (Join-Path $OutDir "LICENSE")

Write-Host "Bundle complete." -ForegroundColor Green
Write-Host "Next: compile from dist\\EPJC_submission\\papers" -ForegroundColor Yellow
