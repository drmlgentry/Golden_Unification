[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)]
  [ValidateSet('I','II','III','IV','V','VI','VII','VIII','IX')]
  [string]$Paper,

  [Parameter(Mandatory=$true)]
  [ValidateSet('epjc','jhep','arxiv','other')]
  [string]$Target,

  [string]$Prefix = 'paper',

  [switch]$Checkout
)

<#[
.SYNOPSIS
  Create a consistently named git branch for a specific paper and venue target.

.DESCRIPTION
  Branch name convention:
    <Prefix>-<roman>-<target>

  Examples:
    paper-I-jhep
    paper-II-epjc

  The script prints the branch name, creates it via git (if available), and
  optionally checks it out.

.NOTES
  This is a convenience wrapper; it does not commit or modify files.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$roman = $Paper.ToUpperInvariant()
$target = $Target.ToLowerInvariant()
$branch = "$Prefix-$roman-$target"

Write-Host $branch

# If git is not installed or repo not initialized, just print the suggested name.
$git = Get-Command git -ErrorAction SilentlyContinue
if (-not $git) {
  Write-Warning "git not found. Branch name printed only."
  return
}

# Verify we are inside a repo
$inside = & git rev-parse --is-inside-work-tree 2>$null
if ($LASTEXITCODE -ne 0 -or $inside -ne 'true') {
  Write-Warning "Not inside a git work tree. Branch name printed only."
  return
}

# Create if missing
$exists = & git show-ref --verify --quiet "refs/heads/$branch"
if ($LASTEXITCODE -ne 0) {
  & git branch $branch | Out-Null
}

if ($Checkout) {
  & git checkout $branch | Out-Null
}
