@'
# ============================================================
# rx_lock_sections_and_place_figures.ps1
# - Adds TikZ preamble once (MASTER + CORE_MASTER)
# - Writes polished, locked-in section tex files:
#     papers/sections/02_lattice.tex   (includes lattice figure)
#     papers/sections/06d_origami_inversion_holonomy.tex (includes origami figure)
# - Ensures \input for 06d exists in both masters
# - Builds CORE_MASTER.pdf and MASTER.pdf
# ============================================================

$ErrorActionPreference = "Stop"

$root   = "C:\Users\Your Name Here\Desktop\Golden_Unification"
$papers = Join-Path $root "papers"
$secs   = Join-Path $papers "sections"

$master = Join-Path $papers "MASTER.tex"
$core   = Join-Path $papers "CORE_MASTER.tex"

function Ensure-Dir($p) {
  if (-not (Test-Path -LiteralPath $p)) {
    New-Item -ItemType Directory -Path $p | Out-Null
  }
}

function Read-Text($path) {
  return Get-Content -LiteralPath $path -Raw -Encoding UTF8
}

function Write-Text($path, $content) {
  Set-Content -LiteralPath $path -Value $content -Encoding UTF8
  Write-Host ("Wrote file: " + $path) -ForegroundColor Green
}

function Ensure-TikZ-Preamble($texPath) {
  $txt = Read-Text $texPath

  # If TikZ already present, do nothing.
  if ($txt -match '\\usepackage\{tikz\}') {
    Write-Host ("TikZ already present: " + $texPath) -ForegroundColor DarkGray
    return
  }

  # Insert TikZ lines after hyperref if possible, else before \begin{document}.
  $tikzBlock = @"
\usepackage{tikz}
\usetikzlibrary{arrows.meta,calc,decorations.pathreplacing}

"@

  if ($txt -match '\\usepackage\{hyperref\}') {
    $txt = $txt -replace '(\\usepackage\{hyperref\}\s*)', "`$1`r`n$tikzBlock"
    Write-Text $texPath $txt
    Write-Host ("Inserted TikZ preamble after hyperref in: " + $texPath) -ForegroundColor Cyan
    return
  }

  if ($txt -match '\\begin\{document\}') {
    $txt = $txt -replace '(\\begin\{document\}\s*)', "$tikzBlock`r`n`$1"
    Write-Text $texPath $txt
    Write-Host ("Inserted TikZ preamble before begin{document} in: " + $texPath) -ForegroundColor Cyan
    return
  }

  throw ("Could not find insertion point in: " + $texPath)
}

function Ensure-Input-Line($texPath, $needleInputLine, $afterPattern) {
  $lines = Get-Content -LiteralPath $texPath -Encoding UTF8
  $has = $false
  foreach ($ln in $lines) {
    if ($ln.Trim() -eq $needleInputLine.Trim()) { $has = $true; break }
  }
  if ($has) {
    Write-Host ("Already present in: " + $texPath + "  = " + $needleInputLine) -ForegroundColor DarkGray
    return
  }

  # Insert after the first line matching afterPattern; if none, insert before \end{document}.
  $out = New-Object System.Collections.Generic.List[string]
  $inserted = $false
  foreach ($ln in $lines) {
    $out.Add($ln)
    if (-not $inserted -and $ln -match $afterPattern) {
      $out.Add($needleInputLine)
      $inserted = $true
    }
  }
  if (-not $inserted) {
    $out2 = New-Object System.Collections.Generic.List[string]
    foreach ($ln in $out) {
      if (-not $inserted -and $ln -match '\\end\{document\}') {
        $out2.Add($needleInputLine)
        $inserted = $true
      }
      $out2.Add($ln)
    }
    $out = $out2
  }

  Set-Content -LiteralPath $texPath -Value $out -Encoding UTF8
  Write-Host ("Inserted into: " + $texPath + "  + " + $needleInputLine) -ForegroundColor Cyan
}

function Build-Tex($texName) {
  $texPath = Join-Path $papers $texName
  if (-not (Test-Path -LiteralPath $texPath)) { throw ("Missing: " + $texPath) }

  Push-Location $papers
  try {
    Write-Host ("Compiling " + $texName + "...") -ForegroundColor Yellow
    & pdflatex -interaction=nonstopmode $texName | Out-Host
    if ($LASTEXITCODE -ne 0) {
      # If PDF exists, keep going but warn.
      $pdf = [System.IO.Path]::ChangeExtension($texPath, ".pdf")
      if (Test-Path -LiteralPath $pdf) {
        Write-Host ("WARNING: pdflatex exit code " + $LASTEXITCODE + " but PDF exists: " + $pdf) -ForegroundColor DarkYellow
      } else {
        throw ("pdflatex failed for " + $texName)
      }
    }
  } finally {
    Pop-Location
  }
}

# -------------------------
# Ensure directories
# -------------------------
Ensure-Dir $papers
Ensure-Dir $secs

# -------------------------
# Ensure TikZ preamble
# -------------------------
Ensure-TikZ-Preamble $master
Ensure-TikZ-Preamble $core

# -------------------------
# Write locked-in section: 02_lattice.tex (Figure A)
# -------------------------
$sec02 = @'
% =========================
% sections/02_lattice.tex
% Locked-in (polished) version with schematic lattice figure.
% =========================
\section{Discrete lattice model and anchoring}
\label{sec:lattice}

We model logarithmic mass ratios using a minimal discrete structure on an integer lattice.
Let $(a,b,c)\in\mathbb{Z}^{3}$ and define the linear functional
\begin{equation}
q(a,b,c)=8a+15b+24c,
\label{eq:q_def}
\end{equation}
together with the mass hypothesis
\begin{equation}
\frac{m(a,b,c)}{m_{e}}=\varphi^{q(a,b,c)/4}.
\label{eq:mass_law}
\end{equation}
The coefficients $\{8,15,24\}$ are fixed \emph{a priori}. No continuous fitting parameters appear in
Eqs.~\eqref{eq:q_def}--\eqref{eq:mass_law}; the only freedom is the choice of discrete lattice point(s).

\paragraph{Anchoring and the global shift.}
Equation~\eqref{eq:mass_law} is invariant under a global shift $q\mapsto q+\Delta q$, which corresponds to a common rescaling of all masses.
To remove this trivial freedom we impose an anchor by selecting a reference triple $(a_{e},b_{e},c_{e})$ such that
\begin{equation}
q(a_{e},b_{e},c_{e})=0.
\label{eq:anchor}
\end{equation}
Only differences in $q$ are physically relevant for relative mass ratios.

\paragraph{Discrete fitting protocol.}
Given an experimental mass $m_{\mathrm{exp}}$, we scan over bounded integer domains
\begin{equation}
(a,b,c)\in [a_{\min},a_{\max}]\times[b_{\min},b_{\max}]\times[c_{\min},c_{\max}],
\end{equation}
compute $m(a,b,c)$ via \eqref{eq:mass_law}, and evaluate the log-base-$\varphi$ error
\begin{equation}
\epsilon(a,b,c)\equiv
\left|\log_{\varphi}\!\left(\frac{m(a,b,c)}{m_{\mathrm{exp}}}\right)\right|.
\label{eq:epsilon}
\end{equation}
We retain all lattice points satisfying a stated tolerance $\epsilon\le\epsilon_{\star}$ and separately report multiplicities after deduplicating by $q$ (since multiple $(a,b,c)$ can yield the same $q$).

\begin{figure}[t]
\centering
\begin{tikzpicture}[scale=0.95, >=Latex]

% Axes (schematic)
\draw[->] (-0.2,0) -- (8.4,0) node[below] {$a$};
\draw[->] (0,-0.2) -- (0,6.2) node[left] {$b$};

% Integer lattice points (coarse)
\foreach \x in {0,...,8}{
  \foreach \y in {0,...,6}{
    \fill (\x,\y) circle (1.1pt);
  }
}

% Level sets for q(a,b,c)=8a+15b+24c at fixed c (projected to (a,b))
% Sketch as parallel lines: 8a + 15b = const
\foreach \k/\lab in {0/{q=q_{0}},1/{q=q_{0}+\Delta},2/{q=q_{0}+2\Delta}}{
  \draw[thick] plot[domain=0:8,samples=2] (\x,{(30+20*\k - 8*\x)/15});
  \node[anchor=west] at (5.6,{(30+20*\k - 8*5.6)/15}) {\small \lab};
}

% Annotation: parallel families
\draw[decorate,decoration={brace,amplitude=6pt}] (7.6,3.0) -- (7.6,1.0)
node[midway,xshift=10pt] {\small parallel $q=\mathrm{const}$};

\node[align=left] at (4.2,5.6) {\small \textbf{Schematic:} $(a,b)$ projection\\[-2pt]
\small of integer lattice and $q$-levels.};

\end{tikzpicture}
\caption{\textbf{Discrete lattice structure (schematic projection).}
Integer triples $(a,b,c)\in\mathbb{Z}^{3}$ are mapped by $q(a,b,c)=8a+15b+24c$.
For fixed $c$, the level sets $q=\mathrm{const}$ appear as parallel lines in the $(a,b)$ projection; in three dimensions they form parallel lattice planes.
Under $m/m_{e}=\varphi^{q/4}$, each plane corresponds to a discrete logarithmic mass level, with the electron anchoring fixing the global shift.}
\label{fig:lattice_q_levels}
\end{figure}

This construction is deliberately minimal: it asserts only that logarithmic mass ratios may cluster near a discrete set of values parameterized by $q/4$ in base $\varphi$. Interpretation and extensions are deferred to the discussion and verification sections.
'@

Write-Text (Join-Path $secs "02_lattice.tex") $sec02

# -------------------------
# Write locked-in section: 06d_origami_inversion_holonomy.tex (Figure B)
# -------------------------
$sec06d = @'
% ============================================================
% sections/06d_origami_inversion_holonomy.tex
% Locked-in (polished) toy-model intuition: origami inversion and holonomy.
% ============================================================

\section{Origami inversion as a geometric toy model for holonomy}
\label{sec:origami_inversion_holonomy}

This subsection is explicitly a \emph{toy model} meant to clarify geometric intuition.
It does not assert that a Euclidean origami fold \emph{is} the microscopic origin of flavor or CP violation.
Rather, it isolates a concrete operation---a bistable inversion of a locally five-fold structure---that can serve as a visual analogue for an internal holonomy phase associated with a closed loop in configuration space.

\subsection{Local five-fold cap and ``pop-through'' inversion}

Consider a local five-triangle cap around a central vertex, as encountered when assembling an icosahedral surface from equilateral triangles.
A familiar mechanical feature of folded or flexed realizations is a bistable ``pop-through'':
pushing the central vertex along a normal direction can invert the cap from one stable branch to another without requiring an in-plane rotation of the adjacency order.
The cyclic order of the five sectors is preserved; what changes is the embedding branch (``outward'' versus ``inward'').

\begin{figure}[t]
\centering
\begin{tikzpicture}[scale=1.05, >=Latex]

\coordinate (O) at (0,0);

\foreach \i in {0,...,4}{
  \coordinate (V\i) at ({2.0*cos(72*\i)},{2.0*sin(72*\i)});
}

% five triangles meeting at O
\foreach \i [evaluate=\i as \j using int(mod(\i+1,5))] in {0,...,4}{
  \draw[thick] (O) -- (V\i) -- (V\j) -- cycle;
}

% pentagon boundary
\draw[thick] (V0) -- (V1) -- (V2) -- (V3) -- (V4) -- cycle;

% normal push / inversion
\draw[->,very thick] (0,0.2) -- (0,1.3) node[right] {\small push along $+z$};
\draw[->,very thick] (0,-0.2) -- (0,-1.3) node[right] {\small pop-through};

\node[align=center] at (0,2.55) {\small cyclic order preserved\\[-2pt]\small (no in-plane rotation)};
\node at (0,0) {\small $v$};

\end{tikzpicture}
\caption{\textbf{Origami ``pop-through'' inversion (schematic).}
A five-triangle cap about a central vertex $v$ admits a bistable inversion under a normal (out-of-plane) displacement, while preserving the cyclic order of face adjacency.
This supplies a concrete geometric operation that motivates a holonomy-style phase associated with a closed loop in configuration space.}
\label{fig:origami_popthrough}
\end{figure}

\subsection{Configuration-space loop and a Wilson-loop analogue}

To connect the visual operation to standard gauge-theory language, consider a one-parameter family of configurations $X(t)$ describing a deformation that takes the cap from one branch, through a transition, and back to a configuration identified as the same physical state (up to the discrete identification of the bistable branches).
Abstractly, this defines a closed loop $\gamma$ in an appropriate configuration space $\mathcal{C}$:
\begin{equation}
\gamma:[0,1]\to\mathcal{C},\qquad \gamma(0)=\gamma(1).
\end{equation}
If an internal phase degree of freedom is transported along $\gamma$ by a connection one-form $A$ (for example, in a $U(1)$ toy model), the accumulated phase is the holonomy
\begin{equation}
W[\gamma]\;=\;\exp\!\left(i\oint_{\gamma} A\right),
\label{eq:wilson_u1}
\end{equation}
which is the $U(1)$ Wilson loop.

The point of Eq.~\eqref{eq:wilson_u1} here is not to claim a specific microscopic connection, but to illustrate a mechanism class:
a discrete, geometry-driven configuration loop can, in principle, induce a nontrivial phase even when local coordinates return to their starting values.
In later sections (and in code-based audits) we work with operational matching rules for phases; the toy model clarifies what it would mean for a phase to originate from a bona fide holonomy rather than an ad hoc numerical assignment.

\subsection{Conservative takeaway}

The physically testable content remains in the numerical verification pipeline and the pre-registered matching rules used for CKM/PMNS phase audits.
This origami inversion picture is included only to provide an intuitive geometric narrative for how a discrete operation could correspond to a nontrivial holonomy phase in an internal space.
'@

Write-Text (Join-Path $secs "06d_origami_inversion_holonomy.tex") $sec06d

# -------------------------
# Ensure 06d is included in both masters
# Place it after 06c if present, else after 06_holonomy_mixing, else before end{document}.
# -------------------------
$line06d = '\input{sections/06d_origami_inversion_holonomy.tex}'

# Try insertion after 06c first, then 06c_wilson, then 06_holonomy
Ensure-Input-Line $core   $line06d 'sections/06c_'
Ensure-Input-Line $master $line06d 'sections/06c_'

# If those patterns did not match (rare), also try after 06_holonomy_mixing:
Ensure-Input-Line $core   $line06d 'sections/06_holonomy_mixing\.tex'
Ensure-Input-Line $master $line06d 'sections/06_holonomy_mixing\.tex'

# -------------------------
# Build PDFs
# -------------------------
Build-Tex "CORE_MASTER.tex"
Build-Tex "MASTER.tex"

Write-Host "DONE." -ForegroundColor Cyan
'@ | Set-Content -Path ".\rx_lock_sections_and_place_figures.ps1" -Encoding UTF8

Write-Host "Wrote script: .\rx_lock_sections_and_place_figures.ps1" -ForegroundColor Green
