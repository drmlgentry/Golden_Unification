# ============================================================
# rx_add_06d_origami_holonomy_and_build.ps1
# Adds Section 06d (origami inversion -> holonomy/Berry phase)
# and rebuilds CORE_MASTER + MASTER from the papers/ directory.
# ASCII-safe: no Unicode dashes; no PowerShell $() expansion.
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
  $content | Set-Content -LiteralPath $path -Encoding UTF8
  Write-Host ("Wrote file: " + $path) -ForegroundColor Green
}

function Insert-InputAfter([string]$texFile, [string]$afterNeedle, [string]$newInputLine) {
  $full = Join-Path $papers $texFile
  if (-not (Test-Path -LiteralPath $full)) { throw ("Missing: " + $full) }

  $lines = Get-Content -LiteralPath $full
  $already = $false
  foreach ($ln in $lines) {
    if ($ln.Trim() -eq $newInputLine.Trim()) { $already = $true; break }
  }
  if ($already) {
    Write-Host ("Already present in: " + $full) -ForegroundColor DarkGray
    Write-Host ("  = " + $newInputLine) -ForegroundColor DarkGray
    return
  }

  $out = New-Object System.Collections.Generic.List[string]
  $inserted = $false
  foreach ($ln in $lines) {
    $out.Add($ln)
    if (-not $inserted -and ($ln -match [regex]::Escape($afterNeedle))) {
      $out.Add($newInputLine)
      $inserted = $true
    }
  }
  if (-not $inserted) {
    # Fall back: append near end (before \end{document})
    $out2 = New-Object System.Collections.Generic.List[string]
    $inserted2 = $false
    foreach ($ln in $out) {
      if (-not $inserted2 -and ($ln -match '^[ \t]*\\end\{document\}')) {
        $out2.Add($newInputLine)
        $inserted2 = $true
      }
      $out2.Add($ln)
    }
    $out = $out2
  }

  $out | Set-Content -LiteralPath $full -Encoding UTF8
  Write-Host ("Inserted into: " + $full) -ForegroundColor Cyan
  Write-Host ("  + " + $newInputLine) -ForegroundColor Cyan
}

function Build-Tex([string]$texName) {
  Push-Location $papers
  try {
    Write-Host ("Compiling " + $texName + "...") -ForegroundColor Cyan

    & pdflatex -interaction=nonstopmode $texName | Out-Host
    $exit = $LASTEXITCODE

    $pdf = [System.IO.Path]::ChangeExtension((Join-Path $papers $texName), ".pdf")
    $log = [System.IO.Path]::ChangeExtension((Join-Path $papers $texName), ".log")

    if (Test-Path -LiteralPath $pdf) {
      if ($exit -ne 0) {
        Write-Host ("WARNING: pdflatex exit code " + $exit + " but PDF exists: " + $pdf) -ForegroundColor Yellow
        if (Test-Path -LiteralPath $log) {
          Write-Host ("See log: " + $log) -ForegroundColor Yellow
        }
      } else {
        Write-Host ("Build OK: " + $pdf) -ForegroundColor Green
      }
    } else {
      throw ("Build failed; pdf not found: " + $pdf)
    }
  } finally {
    Pop-Location
  }
}

# --- main ---
Ensure-Dir $secs

$secPath = Join-Path $secs "06d_origami_inversion_holonomy.tex"

$sec = @"
% ============================================================
% Section 06d: Origami inversion move -> configuration holonomy
% File: papers/sections/06d_origami_inversion_holonomy.tex
% ============================================================

\\subsection{Toy model: inversion of a five-triangle patch and geometric phase}
\\label{sec:origami_inversion_holonomy}

\\paragraph{Motivation from a concrete deformation.}
Consider a local patch of a Euclidean icosahedral surface built from equilateral triangles. A common physical move in paper-folded models is to \\emph{push} a central vertex inward along an axis normal to the patch (``along the z-axis''), causing the patch to ``pop'' between two stable conformers. Empirically, the cyclic order of the incident faces around the vertex can remain preserved even though the embedding in \\(\\mathbb{R}^3\\) changes discontinuously in appearance.

The key observation for our purposes is that such a pop is naturally treated as a \\emph{path in configuration space} rather than a pointwise spatial inversion. This makes it a natural source of holonomy-like observables.

\\paragraph{Configuration-space loop.}
Let \\(\\mathcal{C}\\) denote the configuration space of the constrained patch (edge lengths fixed; fold angles allowed within admissible constraints). A deformation protocol is a continuous path
\\[
\\gamma : [0,1] \\to \\mathcal{C}, \\qquad \\gamma(0)=c_0,
\\]
and a ``pop-through and return'' protocol corresponds to a closed loop \\(\\gamma\\) with \\(\\gamma(1)=\\gamma(0)=c_0\\). Even if the patch appears to return to the same macroscopic geometry, the loop in \\(\\mathcal{C}\\) can be topologically nontrivial.

\\paragraph{Berry holonomy (U(1) toy coupling).}
Now couple a toy quantum degree of freedom \\(|\\psi(c)\\rangle\\) adiabatically to the configuration \\(c\\in\\mathcal{C}\\). Under an adiabatic traverse of \\(\\gamma\\), the state acquires a geometric phase
\\[
\\exp\\bigl( i\\,\\Phi[\\gamma] \\bigr), \\qquad
\\Phi[\\gamma] = \\oint_{\\gamma} \\mathcal{A},
\\]
where \\(\\mathcal{A} = i\\langle \\psi | \\mathrm{d}\\psi \\rangle\\) is the Berry connection 1-form on \\(\\mathcal{C}\\). This is the simplest (U(1)) holonomy. The phase \\(\\Phi\\) is gauge-invariant modulo \\(2\\pi\\) and depends on the \\emph{loop} rather than only the endpoints.

This provides a mathematically controlled analog of how a discrete geometric move can produce a robust phase observable without invoking new local dynamics.

\\paragraph{Relation to Wilson loops.}
In the U(1) case, the above phase is a Wilson loop of the Berry connection:
\\[
W[\\gamma] = \\exp\\left(i\\oint_{\\gamma} \\mathcal{A}\\right).
\\]
Section~06c introduced Wilson-loop language directly. Here we emphasize the geometric interpretation: the ``origami inversion'' move supplies a concrete candidate for \\(\\gamma\\).

\\paragraph{How this connects to CP phases (conservative statement).}
In the Standard Model, the physically meaningful CP-violating phase is not an arbitrary parameter; it is meaningful only through rephasing-invariant combinations such as the Jarlskog invariant \\(J\\). A holonomy-based hypothesis is therefore credible only insofar as it produces:
(i) a phase defined modulo discrete equivalences,
(ii) a stable rule that maps geometry to the phase before fitting,
and (iii) a rephasing-invariant observable (e.g., \\(J\\)).

Accordingly, we treat the origami inversion toy model as a \\emph{geometric source} of a phase-like observable, not as a literal identification of antiparticles. The correct falsifiable content is whether a discrete geometric protocol can define \\(\\theta_{\\star}\\) (or \\(\\sin\\theta_{\\star}\\)) in a way that is stable and predictive when inserted into the CKM/PMNS audit pipeline of Section~06.

\\paragraph{Immediate next step.}
A minimal numerical experiment (future work) is to define a low-dimensional parameterization of the patch (e.g., by one or two fold angles), specify an explicit \\(|\\psi(c)\\rangle\\), compute \\(\\Phi[\\gamma]\\) for the pop-through loop, and test whether the resulting phase exhibits the same discrete ambiguities as the matching rules used for \\(\\delta\\) in Section~06.
"@

Write-UTF8 $secPath $sec

# Insert after 06c if present, otherwise append before \end{document}
$needle = "sections/06c_wilson_loop_u1.tex"
$newLine = "\input{sections/06d_origami_inversion_holonomy.tex}"

Insert-InputAfter "CORE_MASTER.tex" $needle $newLine
Insert-InputAfter "MASTER.tex"      $needle $newLine

Build-Tex "CORE_MASTER.tex"
Build-Tex "MASTER.tex"

Write-Host "DONE." -ForegroundColor Cyan
