$ErrorActionPreference = 'Stop'

Push-Location (Join-Path $PSScriptRoot '..\papers')
try {
  latexmk -pdf -interaction=nonstopmode -file-line-error CORE_MASTER.tex
}
finally {
  Pop-Location
}
