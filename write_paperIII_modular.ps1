
param(
  [string]$RepoRoot = "C:\Users\Your Name Here\Desktop\Golden_Unification",
  [switch]$Compile
)

function Ensure-Dir {
  param([Parameter(Mandatory=$true)][string]$Path)
  if (-not (Test-Path -LiteralPath $Path)) {
    New-Item -ItemType Directory -Path $Path | Out-Null
    Write-Host "Created directory: $Path" -ForegroundColor Green
  } else {
    Write-Host "Directory exists:  $Path" -ForegroundColor DarkGray
  }
}

function Write-UTF8 {
  param(
    [Parameter(Mandatory=$true)][string]$Path,
    [Parameter(Mandatory=$true)][string]$Content
  )
  $parent = Split-Path -Parent $Path
  if ($parent -and -not (Test-Path -LiteralPath $parent)) {
    New-Item -ItemType Directory -Path $parent | Out-Null
  }
  Set-Content -LiteralPath $Path -Value $Content -Encoding UTF8
  Write-Host "Wrote file:         $Path" -ForegroundColor Green
}

if (-not (Test-Path -LiteralPath $RepoRoot)) {
  throw "RepoRoot not found: $RepoRoot"
}

$papersDir   = Join-Path $RepoRoot "papers"
$sectionsDir = Join-Path $papersDir "sections"

Ensure-Dir $papersDir
Ensure-Dir $sectionsDir

$master = @'
\documentclass[11pt]{article}

\usepackage{amsmath,amssymb}
\usepackage{graphicx}
\usepackage{hyperref}

% Shared macros (loaded exactly once)
\input{../shared/macros.tex}

\begin{document}

\input{sections/01_log_structure.tex}
\input{sections/02_lattice.tex}
\input{sections/03_results.tex}

\end{document}
'@

Write-UTF8 (Join-Path $papersDir "MASTER.tex") $master

$sec01 = @'
\section{Logarithmic structure in mass hierarchies}
\label{sec:log_structure}

The Standard Model accommodates fermion masses spanning more than twelve orders of magnitude, from sub-eV neutrino scales to the top quark mass near the electroweak scale. When expressed on a linear scale, this hierarchy appears highly irregular. However, when masses are represented logarithmically, pronounced regularities emerge.

This observation is not new: renormalization group flow, dimensional transmutation, and hierarchical symmetry breaking all naturally generate exponential relations among physical scales. What is less commonly emphasized is that, when logarithmic masses are compared directly across particle species, the observed spectrum exhibits non-random clustering suggestive of an underlying discrete organization.

In this work, we therefore adopt logarithmic mass coordinates as the natural arena in which to examine structural regularities. Specifically, we define a dimensionless logarithmic mass coordinate
\begin{equation}
\ell \equiv \log_{\varphi}\!\left(\frac{m}{m_e}\right),
\end{equation}
where $\varphi = (1+\sqrt{5})/2$ is the golden ratio and $m_e$ is the electron mass.

Importantly, this definition does not assume a mass-generation mechanism. It merely provides a coordinate system in which patterns—if present—are rendered visible.
'@

Write-UTF8 (Join-Path $sectionsDir "01_log_structure.tex") $sec01

$sec02 = @'
\section{Discrete lattice formulation}
\label{sec:lattice}

We now introduce the discrete lattice structure used throughout the analysis. We define an integer-valued triple $(a,b,c) \in \mathbb{Z}^3$ and associate to each triple a scalar quantity
\begin{equation}
q(a,b,c) = 8a + 15b + 24c.
\label{eq:q_def}
\end{equation}

Masses are modeled as
\begin{equation}
\frac{m}{m_e} = \varphi^{q/4}.
\label{eq:mass_law}
\end{equation}

To remove the trivial continuous scaling freedom, we impose an anchoring condition by assigning the electron a reference triple $(a_e,b_e,c_e)$ satisfying
\begin{equation}
q(a_e,b_e,c_e) = 0.
\end{equation}

All other particle masses are fit relative to this anchor by scanning bounded integer regions of $(a,b,c)$ and minimizing the relative logarithmic error
\begin{equation}
\epsilon = \left| \log_{\varphi}\!\left(\frac{m_{\text{fit}}}{m_{\text{exp}}}\right) \right|.
\end{equation}

No uniqueness assumption is imposed; all lattice points satisfying the tolerance criteria are retained.
'@

Write-UTF8 (Join-Path $sectionsDir "02_lattice.tex") $sec02

$sec03 = @'
\section{Empirical results}
\label{sec:results}

Applying the lattice construction to charged leptons, electroweak gauge bosons, and the top quark yields a clear alignment between experimental masses and discrete lattice planes.

Across all examined species, relative logarithmic errors are typically at the few-percent level or better, despite the absence of continuous fitting parameters. Several particles exhibit unique lattice assignments once solutions are deduplicated by $q$-value, while others show limited controlled degeneracy.

Multiplicity scans over extended lattice domains demonstrate that the lattice is neither excessively fine-grained nor trivially overcomplete. Instead, it imposes nontrivial constraints that significantly reduce the space of admissible mass values.

These results are phenomenological. No claim is made that the lattice replaces established dynamical mechanisms. Rather, it is an empirical organizing structure that motivates deeper theoretical investigation.

% Optional: include auto-generated result blocks here:
% \input{../shared/paperIII_results.tex}
% \input{../shared/paperV_mixing_results.tex}
'@

Write-UTF8 (Join-Path $sectionsDir "03_results.tex") $sec03

Write-Host ""
Write-Host "Done. Files written under:" -ForegroundColor Cyan
Write-Host ("  " + $papersDir) -ForegroundColor Cyan
Write-Host ""

if ($Compile) {
  Write-Host "Compiling MASTER.tex..." -ForegroundColor Cyan
  Push-Location $papersDir
  pdflatex -halt-on-error -interaction=nonstopmode MASTER.tex
  Pop-Location
  Write-Host "Compile attempt complete. See papers\MASTER.pdf if successful." -ForegroundColor Cyan
}