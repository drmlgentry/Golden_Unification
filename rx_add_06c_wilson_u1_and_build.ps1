# ============================================================
# rx_add_06c_wilson_u1_and_build.ps1
# Writes 06c_wilson_loop_u1.tex, inserts into CORE_MASTER/MASTER,
# then builds both. ASCII-safe.
# ============================================================

$ErrorActionPreference = "Stop"

$root   = "C:\Users\Your Name Here\Desktop\Golden_Unification"
$papers = Join-Path $root "papers"
$secs   = Join-Path $papers "sections"

function Ensure-Dir([string]$p) {
  if (-not (Test-Path -LiteralPath $p)) {
    New-Item -ItemType Directory -Path $p | Out-Null
    Write-Host ("Created dir: " + $p) -ForegroundColor Green
  } else {
    Write-Host ("Directory exists: " + $p) -ForegroundColor DarkGray
  }
}

function Write-UTF8([string]$path, [string]$content) {
  $content | Set-Content -Path $path -Encoding UTF8
  Write-Host ("Wrote file: " + $path) -ForegroundColor Green
}

function Insert-InputLine([string]$texPath, [string]$needle, [string]$insertLine) {
  if (-not (Test-Path -LiteralPath $texPath)) {
    throw ("Missing TeX file: " + $texPath)
  }
  $txt = Get-Content -LiteralPath $texPath -Raw -Encoding UTF8

  if ($txt -match [regex]::Escape($insertLine)) {
    Write-Host ("Already present in: " + $texPath) -ForegroundColor DarkGray
    return
  }

  if (-not ($txt -match [regex]::Escape($needle))) {
    throw ("Needle not found in " + $texPath + ": " + $needle)
  }

  $new = $txt -replace [regex]::Escape($needle), ($needle + "`r`n" + $insertLine)
  $new | Set-Content -LiteralPath $texPath -Encoding UTF8
  Write-Host ("Inserted into: " + $texPath) -ForegroundColor Cyan
  Write-Host ("  + " + $insertLine) -ForegroundColor Cyan
}

function Build-Tex([string]$texName) {
  $texPath = Join-Path $papers $texName
  if (-not (Test-Path -LiteralPath $texPath)) { throw ("Missing: " + $texPath) }

  Write-Host ""
  Write-Host ("Compiling " + $texName + "...") -ForegroundColor Cyan

  Push-Location $papers
  try {
    & pdflatex -interaction=nonstopmode $texName | Out-Null
    & pdflatex -interaction=nonstopmode $texName | Out-Null
  } finally {
    Pop-Location
  }

  $pdfPath = [System.IO.Path]::ChangeExtension($texPath, ".pdf")
  if (Test-Path -LiteralPath $pdfPath) {
    Write-Host ("Build OK: " + $pdfPath) -ForegroundColor Green
  } else {
    throw ("Build failed; pdf not found for " + $texName)
  }
}

# --- main ---
Ensure-Dir $secs

$secFile = Join-Path $secs "06c_wilson_loop_u1.tex"

$secText = @'
% ============================================================
% Paper VIc section: U(1) Wilson loop toy model for inversion
% File: papers/sections/06c_wilson_loop_u1.tex
% ============================================================

\section{Toy model: a U(1) Wilson loop for the pop-through inversion}
\label{sec:wilson_u1_toy}

\subsection{Motivation and scope}
The ``push-the-central-vertex inward'' pop-through (with cyclic order preserved) can be viewed as a
\emph{closed path in configuration space} of the folded 5-triangle cap.
A Wilson loop is the natural gauge-invariant observable associated with such a closed path:
it measures a holonomy (a phase) accumulated around a loop, even if the start and end shapes
appear congruent in ordinary Euclidean space.

This section is explicitly a \emph{toy model}. Its purpose is to provide a mathematically clean template
for ``phase from geometry'' that can later be refined or replaced by a more realistic construction.

\subsection{Discrete U(1) connection on the boundary 5-cycle}
Consider the boundary cycle of the cap,
\begin{equation}
\gamma:\quad v_1 \to v_2 \to v_3 \to v_4 \to v_5 \to v_1,
\end{equation}
with vertices labeled in cyclic order.

Assign a U(1) parallel-transport element to each oriented boundary edge,
\begin{equation}
U_{i,i+1}(t) \in U(1), \qquad U_{i,i+1}(t) = e^{i\alpha_{i}(t)},
\end{equation}
where $t\in[0,1]$ parametrizes the deformation (the pop-through) and $v_6 \equiv v_1$.

Under a local gauge transformation $g_i(t)=e^{i\lambda_i(t)}$, the edge variables transform as
\begin{equation}
U_{ij}(t) \mapsto g_i(t)\,U_{ij}(t)\,g_j(t)^{-1},
\end{equation}
so any observable must be gauge-invariant.

\subsection{Wilson loop and holonomy angle}
Define the Wilson loop around $\gamma$ by the product
\begin{equation}
W_\gamma(t) \;\equiv\; \prod_{i=1}^{5} U_{i,i+1}(t)
\;=\; \exp\!\left(i\sum_{i=1}^{5}\alpha_i(t)\right).
\label{eq:wilson_u1}
\end{equation}
Because the gauge factors telescope around a closed loop, $W_\gamma(t)$ is gauge-invariant.

We define the associated holonomy angle by
\begin{equation}
\theta_\star(t) \;\equiv\; \arg W_\gamma(t)
\;=\; \sum_{i=1}^{5}\alpha_i(t)\quad (\mathrm{mod}\ 2\pi).
\label{eq:theta_star_def}
\end{equation}

\subsection{Minimal defect model for the pop-through}
A minimal phenomenological model is to treat the pop-through as creating an effective ``flux'' through the cap
localized near the central vertex. In the U(1) setting, the Wilson loop measures this enclosed flux:
\begin{equation}
W_\gamma(t) = e^{i\Omega(t)}, \qquad \theta_\star(t) = \Omega(t)\ (\mathrm{mod}\ 2\pi),
\end{equation}
where $\Omega(t)$ is an effective integrated curvature (a defect strength) associated with the deformation.

A convenient toy reduction is the uniform-edge ansatz
\begin{equation}
\alpha_i(t) \equiv \alpha(t)\quad \forall i,
\qquad \Rightarrow \qquad
W_\gamma(t) = e^{i5\alpha(t)},\quad \theta_\star(t)=5\alpha(t)\ (\mathrm{mod}\ 2\pi).
\label{eq:uniform_edge}
\end{equation}

\subsection{Connection to the mixing-phase audit (conceptual bridge)}
The verification pipeline in Section~\ref{sec:holonomy_mixing} treats $\theta_\star$ as a predicted holonomy angle
and determines a Dirac phase $\delta$ by a pre-registered matching rule. This toy model provides a concrete
interpretation of what ``predicted holonomy angle'' can mean: it is the gauge-invariant phase extracted from
a Wilson loop around a physically meaningful cycle associated with the discrete geometry.

We emphasize that this does \emph{not} by itself derive CKM/PMNS structure. Rather, it supplies the correct
mathematical language for a mechanism in which phases are associated with loops (holonomies) rather than with
coordinate assignments. Any future refinement must specify (i) which loop(s) are physically relevant, (ii) how the
effective connection arises from the underlying discrete geometry, and (iii) which quantities are predicted
before data inspection.

\subsection{Falsifiability within the toy model}
Even at the toy level, the construction is falsifiable in the following limited sense:
if a proposed geometric mechanism predicts a specific $\theta_\star$ for a given sector, then the audit rule
fixes a definite $\delta$ and $J$ (via the scan code) that can be compared to global fits.
If the mapping fails systematically under updated inputs or under a fixed pre-registration protocol, the mechanism
class is disfavored.
'@

Write-UTF8 $secFile $secText

$line   = '\input{sections/06c_wilson_loop_u1.tex}'
$needle = '\input{sections/06_holonomy_mixing.tex}'

$core  = Join-Path $papers "CORE_MASTER.tex"
$master= Join-Path $papers "MASTER.tex"

Insert-InputLine $core   $needle $line
Insert-InputLine $master $needle $line

Build-Tex "CORE_MASTER.tex"
Build-Tex "MASTER.tex"

Write-Host "DONE." -ForegroundColor Cyan
