@'
# ============================================================
# Rx: Add Null Tests v3 (Rank-locked + Gap null) and run
# Writes:
#   code\null_tests_v3_ranklocked.py
# Produces:
#   shared\paperIX_null_v3.tex
# ============================================================

$ErrorActionPreference = "Stop"

function Ensure-Dir([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path | Out-Null
        Write-Host "Created directory: $Path" -ForegroundColor Green
    } else {
        Write-Host "Directory exists:  $Path" -ForegroundColor DarkGray
    }
}

# Resolve repo root = folder containing this script
$RepoRoot = (Resolve-Path ".").Path
$CodeDir  = Join-Path $RepoRoot "code"
$SharedDir = Join-Path $RepoRoot "shared"

Ensure-Dir $CodeDir
Ensure-Dir $SharedDir

$PyPath = Join-Path $CodeDir "null_tests_v3_ranklocked.py"

$Py = @'
#!/usr/bin/env python3
# ============================================================
# Null Tests v3: Rank-locked jitter + Gap-permutation null
# Anchored quantization score vs q-set derived from scan box.
# Outputs a LaTeX block for Paper IX.
# ============================================================

from __future__ import annotations
import argparse
import math
import os
import random
import statistics
from dataclasses import dataclass
from typing import Dict, List, Sequence, Tuple

# ----------------------------
# Physics inputs (edit here if desired)
# ----------------------------
# Using the same 6-particle set you have been reporting.
# Units: GeV for W, Z, top; GeV for leptons via conversion.
# Electron, muon, tau given in GeV.
MOBS_GEV: Dict[str, float] = {
    "electron": 0.00051099895e-3,   # MeV -> GeV
    "muon":     0.105658375e-3,     # MeV -> GeV
    "tau":      1.77686e-0,         # GeV
    "W":        80.379,
    "Z":        91.1876,
    "top":      172.76,
}

# ----------------------------
# Model: q(a,b,c) = 8a + 15b + 24c and ell = log_phi(m/me)
# Fit score uses q/4 as the lattice coordinate in ell-space.
# ----------------------------

@dataclass(frozen=True)
class ScanBox:
    a_min: int
    a_max: int
    b_min: int
    b_max: int
    c_min: int
    c_max: int

def log_base(x: float, base: float) -> float:
    return math.log(x) / math.log(base)

def build_qset(box: ScanBox) -> List[int]:
    qs = set()
    for a in range(box.a_min, box.a_max + 1):
        for b in range(box.b_min, box.b_max + 1):
            for c in range(box.c_min, box.c_max + 1):
                q = 8*a + 15*b + 24*c
                qs.add(q)
    return sorted(qs)

def ell_from_masses(masses: Dict[str, float], phi: float, m_e: float) -> Dict[str, float]:
    out = {}
    for k, m in masses.items():
        out[k] = log_base(m / m_e, phi)
    return out

def quantize_eps(ell: float, qset: Sequence[int]) -> Tuple[float, int]:
    # minimize |q/4 - ell| over q in qset
    best = None
    best_q = None
    for q in qset:
        e = abs((q / 4.0) - ell)
        if best is None or e < best:
            best = e
            best_q = q
    return float(best), int(best_q)

def score_spectrum(ells: Dict[str, float], qset: Sequence[int]) -> Tuple[float, Dict[str, Tuple[float, int]]]:
    per = {}
    eps_list = []
    for name, ell in ells.items():
        eps, q_best = quantize_eps(ell, qset)
        per[name] = (eps, q_best)
        eps_list.append(eps)
    return float(sum(eps_list) / len(eps_list)), per

# ----------------------------
# Nulls
# ----------------------------

def sorted_by_mass(masses: Dict[str, float]) -> List[Tuple[str, float]]:
    return sorted(masses.items(), key=lambda kv: kv[1])

def rank_locked_jitter(
    ell_sorted: List[Tuple[str, float]],
    sigma: float,
    rng: random.Random,
    max_tries: int = 100000
) -> List[Tuple[str, float]]:
    """
    Add N(0,sigma^2) jitter to each ell_i but reject if ordering changes.
    Returns list in the same particle order as ell_sorted.
    """
    base_vals = [v for _, v in ell_sorted]
    names = [n for n, _ in ell_sorted]

    for _ in range(max_tries):
        jit = [v + rng.gauss(0.0, sigma) for v in base_vals]
        ok = all(jit[i] < jit[i+1] for i in range(len(jit)-1))
        if ok:
            return list(zip(names, jit))

    raise RuntimeError(f"rank_locked_jitter: exceeded max_tries={max_tries} (sigma={sigma})")

def gap_permutation_null(
    ell_sorted: List[Tuple[str, float]],
    rng: random.Random
) -> List[Tuple[str, float]]:
    """
    Preserve min ell and multiset of gaps but permute the gaps.
    Ordering is preserved by construction.
    """
    names = [n for n, _ in ell_sorted]
    vals  = [v for _, v in ell_sorted]
    gaps = [vals[i+1] - vals[i] for i in range(len(vals)-1)]
    rng.shuffle(gaps)
    out = [vals[0]]
    for g in gaps:
        out.append(out[-1] + g)
    return list(zip(names, out))

# ----------------------------
# LaTeX output
# ----------------------------

def fmt_sci(x: float) -> str:
    # TeX-friendly scientific format
    if x == 0.0:
        return "0"
    exp = int(math.floor(math.log10(abs(x))))
    mant = x / (10**exp)
    return f"{mant:.6f}\\times 10^{{{exp}}}"

def latex_block(
    box: ScanBox,
    qset_size: int,
    mean_obs: float,
    per_obs: Dict[str, Tuple[float, int]],
    nullA: Dict[str, object],
    nullB: Dict[str, object],
) -> str:
    lines: List[str] = []
    lines.append("% ============================================================")
    lines.append("% Paper IX — Null tests (v3): rank-locked jitter + gap-permutation")
    lines.append("% Auto-generated by code/null_tests_v3_ranklocked.py")
    lines.append("% ============================================================")
    lines.append("\\subsection{Null tests (v3): rank-locked and gap-permutation ensembles}")
    lines.append("We evaluate whether the anchored lattice-quantization score is unusually small compared to")
    lines.append("two hierarchy-preserving null ensembles. We define the empirical tail probability")
    lines.append("\\begin{equation}")
    lines.append("p_{\\mathrm{emp}} \\equiv \\Pr\\big(\\overline{\\epsilon}_{\\mathrm{null}} \\le \\overline{\\epsilon}_{\\mathrm{obs}}\\big),")
    lines.append("\\end{equation}")
    lines.append("so that small $p_{\\mathrm{emp}}$ indicates unusually strong alignment, while large $p_{\\mathrm{emp}}$")
    lines.append("indicates no evidence for unusually small error under the null.")
    lines.append("")
    lines.append("\\paragraph{Scan box and admissible $q$-set.}")
    lines.append(f"We construct the admissible $q$-set from the integer box")
    lines.append("\\begin{equation}")
    lines.append(
        f"a\\in[{box.a_min},{box.a_max}],\\quad b\\in[{box.b_min},{box.b_max}],\\quad c\\in[{box.c_min},{box.c_max}],"
    )
    lines.append("\\end{equation}")
    lines.append(f"yielding $|\\mathcal{{Q}}|={qset_size}$ distinct $q$ values after deduplication.")
    lines.append("")
    lines.append("\\paragraph{Observed anchored score.}")
    lines.append("\\begin{align}")
    lines.append(f"\\overline{{\\epsilon}}_\\mathrm{{obs}} &= {mean_obs:.6e}.")
    lines.append("\\end{align}")
    lines.append("Per-particle best-fit $q$ values in this scan box are:")
    lines.append("\\begin{center}")
    lines.append("\\begin{tabular}{lrr}")
    lines.append("\\hline")
    lines.append("Particle & $\\epsilon_i$ & $q_i^{\\star}$\\\\")
    lines.append("\\hline")
    for name in ["electron","muon","tau","W","Z","top"]:
        eps_i, q_i = per_obs[name]
        lines.append(f"{name} & {eps_i:.6e} & {q_i}\\\\")
    lines.append("\\hline")
    lines.append("\\end{tabular}")
    lines.append("\\end{center}")
    lines.append("")
    lines.append("\\paragraph{Null A: rank-locked jitter in log-space.}")
    lines.append("We jitter each logarithmic mass coordinate by $\\mathcal{N}(0,\\sigma^2)$ but reject draws that change the")
    lines.append("rank ordering of the spectrum. Results:")
    lines.append("\\begin{align}")
    lines.append(
        f"N &= {nullA['N']},\\quad \\sigma={nullA['sigma']:.3f},\\quad "
        f"\\min={nullA['min']:.6e},\\quad \\mathrm{{med}}={nullA['med']:.6e},\\quad \\max={nullA['max']:.6e},\\quad "
        f"p_\\mathrm{{emp}}={nullA['p_emp']:.6g}."
    )
    lines.append("\\end{align}")
    lines.append("")
    lines.append("\\paragraph{Null B: gap-permutation null.}")
    lines.append("We preserve the minimum logarithmic mass and the multiset of adjacent gaps, but randomly permute the gaps.")
    lines.append("This preserves the overall hierarchy profile while removing any specific assignment structure. Results:")
    lines.append("\\begin{align}")
    lines.append(
        f"N &= {nullB['N']},\\quad "
        f"\\min={nullB['min']:.6e},\\quad \\mathrm{{med}}={nullB['med']:.6e},\\quad \\max={nullB['max']:.6e},\\quad "
        f"p_\\mathrm{{emp}}={nullB['p_emp']:.6g}."
    )
    lines.append("\\end{align}")
    lines.append("")
    lines.append("\\paragraph{Interpretation.}")
    lines.append("These two nulls preserve salient features of a hierarchical spectrum (ordering and/or gap structure).")
    lines.append("Accordingly, they provide a stricter baseline than i.i.d. log-uniform draws for assessing whether")
    lines.append("anchored lattice quantization yields unusually small mean error.")
    lines.append("")
    return "\n".join(lines)

# ----------------------------
# Main
# ----------------------------

def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--N", type=int, default=5000, help="number of null samples per ensemble")
    ap.add_argument("--seed", type=int, default=12345)
    ap.add_argument("--sigma", type=float, default=0.300, help="rank-locked jitter sigma in ell-space (log_phi units)")
    ap.add_argument("--a_min", type=int, default=-80)
    ap.add_argument("--a_max", type=int, default=20)
    ap.add_argument("--b_min", type=int, default=-40)
    ap.add_argument("--b_max", type=int, default=40)
    ap.add_argument("--c_min", type=int, default=-40)
    ap.add_argument("--c_max", type=int, default=60)
    ap.add_argument("--out_tex", type=str, default=os.path.join("..","shared","paperIX_null_v3.tex"))
    args = ap.parse_args()

    rng = random.Random(args.seed)

    phi = (1.0 + math.sqrt(5.0)) / 2.0
    m_e = MOBS_GEV["electron"]

    box = ScanBox(args.a_min, args.a_max, args.b_min, args.b_max, args.c_min, args.c_max)
    qset = build_qset(box)

    # Observed
    ell_obs = ell_from_masses(MOBS_GEV, phi=phi, m_e=m_e)
    mean_obs, per_obs = score_spectrum(ell_obs, qset)

    # Prepare sorted ell list by mass (for hierarchy-preserving nulls)
    ell_sorted = sorted(ell_obs.items(), key=lambda kv: MOBS_GEV[kv[0]])

    # Null A: rank-locked jitter
    valsA: List[float] = []
    for _ in range(args.N):
        sample_pairs = rank_locked_jitter(ell_sorted, sigma=args.sigma, rng=rng)
        ell_s = {name: ell for name, ell in sample_pairs}
        mean_s, _ = score_spectrum(ell_s, qset)
        valsA.append(mean_s)

    valsA_sorted = sorted(valsA)
    p_emp_A = sum(1 for v in valsA if v <= mean_obs) / float(len(valsA))

    nullA = {
        "N": args.N,
        "sigma": args.sigma,
        "min": min(valsA),
        "med": statistics.median(valsA),
        "max": max(valsA),
        "p_emp": p_emp_A,
    }

    # Null B: gap-permutation
    valsB: List[float] = []
    for _ in range(args.N):
        sample_pairs = gap_permutation_null(ell_sorted, rng=rng)
        ell_s = {name: ell for name, ell in sample_pairs}
        mean_s, _ = score_spectrum(ell_s, qset)
        valsB.append(mean_s)

    p_emp_B = sum(1 for v in valsB if v <= mean_obs) / float(len(valsB))
    nullB = {
        "N": args.N,
        "min": min(valsB),
        "med": statistics.median(valsB),
        "max": max(valsB),
        "p_emp": p_emp_B,
    }

    tex = latex_block(box, qset_size=len(qset), mean_obs=mean_obs, per_obs=per_obs, nullA=nullA, nullB=nullB)

    out_path = args.out_tex
    # If out_tex is relative, interpret relative to code/ directory runtime
    # (most users run: python .\code\null_tests_v3_ranklocked.py from repo root)
    # so normalize safely:
    out_path = os.path.normpath(out_path)

    out_dir = os.path.dirname(out_path)
    if out_dir and not os.path.exists(out_dir):
        os.makedirs(out_dir, exist_ok=True)

    with open(out_path, "w", encoding="utf-8") as f:
        f.write(tex + "\n")

    print("=== v3 null tests written ===")
    print(f"Observed mean_eps = {mean_obs:.6e}")
    print(f"Null A (rank-locked jitter): N={args.N} sigma={args.sigma:.3f} p_emp={p_emp_A:.6g} med={nullA['med']:.6e}")
    print(f"Null B (gap-permutation):   N={args.N} p_emp={p_emp_B:.6g} med={nullB['med']:.6e}")
    print(f"Wrote LaTeX block to: {os.path.abspath(out_path)}")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
'@

# Write the python file
$Py | Set-Content -Path $PyPath -Encoding UTF8
Write-Host "Wrote file: $PyPath" -ForegroundColor Green

# Run it (from repo root). Default writes to ..\shared\paperIX_null_v3.tex
Write-Host "" 
Write-Host "Running: python .\code\null_tests_v3_ranklocked.py --N 5000 --sigma 0.300" -ForegroundColor Cyan
python .\code\null_tests_v3_ranklocked.py --N 5000 --sigma 0.300

Write-Host ""
Write-Host "If you want faster runs: use --N 1000 (draft), then increase to 20000 for final." -ForegroundColor DarkGray
'@ | Set-Content -Path ".\rx_add_null_v3_and_run.ps1" -Encoding UTF8

Write-Host "Wrote script: .\rx_add_null_v3_and_run.ps1" -ForegroundColor Green
