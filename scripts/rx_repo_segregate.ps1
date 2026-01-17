<#
.SYNOPSIS
  Normalize repository structure for paper builds and reproducible artifacts.

.DESCRIPTION
  Ensures standard directories exist (papers/, papers/sections/, shared/, code/, scripts/, results/, dist/)
  and writes a default .gitignore if missing.

  This script is intentionally conservative: it avoids moving user-authored TeX sources.

.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\rx_repo_segregate.ps1
#>

$ErrorActionPreference = "Stop"

$dirs = @(
  ".\papers",
  ".\papers\sections",
  ".\shared",
  ".\code",
  ".\scripts",
  ".\results",
  ".\dist"
)

foreach ($d in $dirs) {
  if (-not (Test-Path -LiteralPath $d)) {
    $null = New-Item -ItemType Directory -Force -Path $d
    Write-Host "Created: $d" -ForegroundColor Cyan
  }
}

if (-not (Test-Path -LiteralPath ".\.gitignore")) {
  Write-Host "Writing default .gitignore" -ForegroundColor Cyan
  @'
# --- LaTeX build artifacts ---
*.aux
*.bbl
*.bcf
*.blg
*.fdb_latexmk
*.fls
*.log
*.out
*.run.xml
*.synctex.gz
*.toc
*.lof
*.lot
*.nav
*.snm
*.vrb
*.xdv

# --- OS / editor ---
.DS_Store
Thumbs.db
.vscode/

# --- Python ---
__pycache__/
*.pyc
.venv/
venv/

# --- Local outputs ---
results/
dist/
'@ | Set-Content -LiteralPath ".\.gitignore" -Encoding UTF8
}

Write-Host "Repo structure OK." -ForegroundColor Green

