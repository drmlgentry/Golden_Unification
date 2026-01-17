# ============================================================
# rx_run_null_v3.ps1
# Run v3 null tests and write LaTeX output (SAFE ASCII VERSION)
# ============================================================

$ErrorActionPreference = "Stop"

$root   = "C:\Users\Your Name Here\Desktop\Golden_Unification"
$python = "python"

$script = Join-Path $root "code\null_tests_v3.py"
$outTex = Join-Path $root "shared\paperIX_null_v3.tex"

if (-not (Test-Path -LiteralPath $script)) {
    Write-Error ("Missing Python script: " + $script)
}

Write-Host "Running v3 null tests..." -ForegroundColor Cyan

# Capture stdout as an array of lines (PowerShell behavior)
$rawLines = & $python $script

if ($LASTEXITCODE -ne 0) {
    Write-Error "Python script failed."
}

# Build LaTeX verbatim block, all ASCII only
$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("% ================================================")
$lines.Add("% Null Tests v3 - automated output")
$lines.Add("% Generated: " + (Get-Date -Format "yyyy-MM-dd HH:mm"))
$lines.Add("% ================================================")
$lines.Add("\begin{verbatim}")

# Ensure we write line-by-line even if Python returned a single string
if ($null -ne $rawLines) {
    foreach ($ln in $rawLines) { $lines.Add([string]$ln) }
}

$lines.Add("\end{verbatim}")

$lines | Set-Content -Path $outTex -Encoding UTF8

Write-Host "Wrote LaTeX output to:" -ForegroundColor Green
Write-Host ("  " + $outTex) -ForegroundColor Green
