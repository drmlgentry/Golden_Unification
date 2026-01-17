[CmdletBinding()]
param(
  [switch]$SkipSegregate
)

<#
rx_setup_repo.ps1

Purpose:
  - Sanity-check expected repo layout
  - Run scripts\rx_repo_segregate.ps1 (optional)
  - Ensure .gitignore exists
  - Ensure CITATION.cff exists (minimal stub if missing)
  - Create results/ and dist/ directories

Notes:
  - PowerShell line continuation is the backtick (`), not the caret (^).
  - Idempotent: does not overwrite existing artifacts unless explicitly told.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Ensure-Dir {
  param([Parameter(Mandatory=$true)][string]$Path)
  if (-not (Test-Path -LiteralPath $Path)) {
    New-Item -ItemType Directory -Path $Path | Out-Null
    Write-Host "Created: $Path"
  }
}

function Ensure-File {
  param(
    [Parameter(Mandatory=$true)][string]$Path,
    [Parameter(Mandatory=$true)][string]$Content
  )
  if (-not (Test-Path -LiteralPath $Path)) {
    $parent = Split-Path -Parent $Path
    if ($parent) { Ensure-Dir $parent }
    Set-Content -LiteralPath $Path -Value $Content -Encoding UTF8
    Write-Host "Created: $Path"
  }
}

$RepoRoot = (Resolve-Path ".").Path
Write-Host "Repo root: $RepoRoot"

# Basic expected directories
Ensure-Dir ".\papers"
Ensure-Dir ".\papers\sections"
Ensure-Dir ".\shared"
Ensure-Dir ".\code"
Ensure-Dir ".\scripts"

# Optional segregation step
if (-not $SkipSegregate) {
  $seg = ".\scripts\rx_repo_segregate.ps1"
  if (Test-Path -LiteralPath $seg) {
    Write-Host "Running: scripts\rx_repo_segregate.ps1"
    powershell -NoProfile -ExecutionPolicy Bypass -File $seg
  } else {
    Write-Host "NOTE: scripts\rx_repo_segregate.ps1 not found; skipping segregation."
  }
} else {
  Write-Host "SkipSegregate enabled; not running rx_repo_segregate.ps1"
}

# Ensure standard output dirs
Ensure-Dir ".\results"
Ensure-Dir ".\dist"

# .gitignore
$gitignore = @"
# TeX build outputs
*.aux
*.bbl
*.blg
*.fdb_latexmk
*.fls
*.log
*.out
*.synctex.gz
*.toc
*.lof
*.lot

# Local build dirs
/dist/
/results/

# OS/editor cruft
.DS_Store
Thumbs.db
.vscode/
"@
Ensure-File ".\.gitignore" $gitignore

# CITATION.cff minimal stub (edit later)
$cff = @"
cff-version: 1.2.0
message: "If you use this repository, please cite it using the metadata in this file."
title: "Golden Unification"
type: software
authors:
  - family-names: "Gentry"
    given-names: "Marvin"
"@
Ensure-File ".\CITATION.cff" $cff

Write-Host "Repo structure OK."
Write-Host "Setup complete."
Write-Host "Next:"
Write-Host "  git init"
Write-Host "  git add ."
Write-Host "  git commit -m `"Initialize segregated repo`""


