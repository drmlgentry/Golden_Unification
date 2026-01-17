# code/null_tests_fast_v2.py
# ============================================================
# Golden Unification — Null Tests (v2, fast, q-set accelerated)
# Writes: ../shared/paperIX_null_pvalues.tex
# ============================================================
#
# This script fixes the key problem you observed: a permutation null can be
# invariant under the anchored score. Here we implement two defensible nulls:
#
#   Null A: i.i.d. log-uniform masses over the observed range
#   Null B: jittered spectrum (Gaussian noise in log space)
#
# The anchored lattice fit is computed in a q-set accelerated way:
# epsilon(m) = | q/4 - log_phi(m/m_e) | minimized over all feasible q
# where q = 8a + 15b + 24c with (a,b,c) in a bounded integer box.
#
# Usage examples (run from repo root):
#   python .\code\null_tests_fast_v2.py
#   python .\code\null_tests_fast_v2.py --N 5000 --seed 1
#   python .\code\null_tests_fast_v2.py --sigma 0.15 0.30 0.50 --N 2000
#
# Notes:
# - We keep the electron as the anchor (m_e fixed).
# - We use your current observed set: e, mu, tau, W, Z, top (modifiable).
# - If you later extend the species set, update OBS_MASSES_MEV accordingly,
#   but do NOT change the scan box once pre-registered.
#
# ============================================================

from __future__ import annotations

import argparse
import math
import os
import random
import statistics
from dataclasses import dataclass
from typing import Dict, List, Tuple


# ----------------------------
# Constants / observed dataset
# ----------------------------

PHI = (1.0 + 5.0 ** 0.5) / 2.0

# Observed masses in MeV (consistent units; ratios are unitless).
# If you prefer GeV for heavy states, convert them to MeV here.
OBS_MASSES_MEV: Dict[str, float] = {
    "electron": 0.51099895,      # MeV
    "muon": 105.6583755,         # MeV
    "tau": 1776.86,              # MeV
    "W": 80379.0,                # MeV (80.379 GeV)
    "Z": 91187.6,                # MeV (91.1876 GeV)
    "top": 172760.0,             # MeV (172.76 GeV)
}

ANCHOR = "electron"

# Default scan box (anchored model) — matches your anchored runs.
A_MIN, A_MAX = -80, 20
B_MIN, B_MAX = -40, 40
C_MIN, C_MAX = -40, 60

# q(a,b,c) definition (fixed)
def q_from_abc(a: int, b: int, c: int) -> int:
    return 8 * a + 15 * b + 24 * c


# ----------------------------
# Utility math
# ----------------------------

def log_phi(x: float) -> float:
    return math.log(x) / math.log(PHI)

def quantile(sorted_vals: List[float], q: float) -> float:
    """Linear interpolation quantile for 0<=q<=1 on a pre-sorted list."""
    if not sorted_vals:
        raise ValueError("quantile(): empty list")
    if q <= 0:
        return sorted_vals[0]
    if q >= 1:
        return sorted_vals[-1]
    pos = (len(sorted_vals) - 1) * q
    lo = int(math.floor(pos))
    hi = int(math.ceil(pos))
    if lo == hi:
        return sorted_vals[lo]
    w = pos - lo
    return (1 - w) * sorted_vals[lo] + w * sorted_vals[hi]


# ----------------------------
# q-set precomputation
# ----------------------------

def build_feasible_q_set() -> List[int]:
    """
    Enumerate all q values reachable within the scan box.
    We deduplicate q values (because epsilon depends only on q).
    """
    qs = set()
    for a in range(A_MIN, A_MAX + 1):
        for b in range(B_MIN, B_MAX + 1):
            # Precompute partial to save multiplications
            ab = 8 * a + 15 * b
            for c in range(C_MIN, C_MAX + 1):
                qs.add(ab + 24 * c)
    q_list = sorted(qs)
    return q_list


def best_eps_for_mass_ratio(q_list: List[int], ratio: float) -> Tuple[float, int]:
    """
    Compute epsilon_min(ratio) = min_q | q/4 - log_phi(ratio) |.
    Returns (eps_min, q_best). Uses binary search around target q.
    """
    target = 4.0 * log_phi(ratio)

    # Binary search for nearest q in q_list to target
    lo, hi = 0, len(q_list) - 1
    while lo < hi:
        mid = (lo + hi) // 2
        if q_list[mid] < target:
            lo = mid + 1
        else:
            hi = mid

    # lo is the first index with q >= target (or last)
    candidates = []
    candidates.append(q_list[lo])
    if lo > 0:
        candidates.append(q_list[lo - 1])
    if lo + 1 < len(q_list):
        candidates.append(q_list[lo + 1])

    best_q = candidates[0]
    best_eps = abs(best_q / 4.0 - log_phi(ratio))
    for q in candidates[1:]:
        eps = abs(q / 4.0 - log_phi(ratio))
        if eps < best_eps:
            best_eps = eps
            best_q = q
    return best_eps, best_q


@dataclass
class FitResult:
    mean_eps: float
    per_particle_eps: Dict[str, float]
    per_particle_qbest: Dict[str, int]


def anchored_fit_score(q_list: List[int], masses_mev: Dict[str, float]) -> FitResult:
    """
    Anchored fit: electron is the anchor with ratio=1 => epsilon=0.
    For each other particle, compute eps_min using q-set.
    """
    if ANCHOR not in masses_mev:
        raise ValueError(f"Anchor '{ANCHOR}' missing from masses")

    me = masses_mev[ANCHOR]
    per_eps: Dict[str, float] = {}
    per_q: Dict[str, int] = {}

    # Anchor (exact by convention)
    per_eps[ANCHOR] = 0.0
    per_q[ANCHOR] = 0  # by definition q_e=0 after anchoring

    for name, m in masses_mev.items():
        if name == ANCHOR:
            continue
        ratio = m / me
        eps, qbest = best_eps_for_mass_ratio(q_list, ratio)
        per_eps[name] = eps
        per_q[name] = qbest

    # mean epsilon over all species including anchor (anchor adds 0)
    mean_eps = sum(per_eps.values()) / len(per_eps)
    return FitResult(mean_eps=mean_eps, per_particle_eps=per_eps, per_particle_qbest=per_q)


# ----------------------------
# Null ensembles
# ----------------------------

def null_log_uniform(
    rng: random.Random,
    base_masses: Dict[str, float],
    n_nonanchor: int,
) -> Dict[str, float]:
    """
    Null A: draw non-anchor masses i.i.d. log-uniform over observed range
    of non-anchor masses. Keep anchor fixed.
    """
    me = base_masses[ANCHOR]
    non_anchor = [m for k, m in base_masses.items() if k != ANCHOR]
    mmin = min(non_anchor)
    mmax = max(non_anchor)

    ln_min = math.log(mmin)
    ln_max = math.log(mmax)

    out: Dict[str, float] = {ANCHOR: me}
    # Preserve the same particle labels (except we resample their values)
    labels = [k for k in base_masses.keys() if k != ANCHOR]
    if len(labels) != n_nonanchor:
        # In practice: n_nonanchor should equal len(labels)
        labels = labels[:n_nonanchor]

    for lbl in labels:
        ln_m = ln_min + (ln_max - ln_min) * rng.random()
        out[lbl] = math.exp(ln_m)
    return out


def null_jittered(
    rng: random.Random,
    base_masses: Dict[str, float],
    sigma: float,
) -> Dict[str, float]:
    """
    Null B: jitter observed non-anchor masses in ln-space by N(0, sigma^2).
    Keep anchor fixed.
    """
    me = base_masses[ANCHOR]
    out: Dict[str, float] = {ANCHOR: me}
    for k, m in base_masses.items():
        if k == ANCHOR:
            continue
        z = rng.gauss(0.0, 1.0)
        out[k] = m * math.exp(sigma * z)
    return out


# ----------------------------
# Reporting / LaTeX writer
# ----------------------------

def format_sci(x: float) -> str:
    # LaTeX-friendly scientific notation
    if x == 0:
        return "0"
    exp = int(math.floor(math.log10(abs(x))))
    mant = x / (10 ** exp)
    return f"{mant:.6f}\\times 10^{{{exp}}}"


def write_tex(
    out_path: str,
    obs: FitResult,
    nullA_stats: Dict[str, float],
    nullB_rows: List[Tuple[float, Dict[str, float]]],
    N: int,
    seed: int,
) -> None:
    """
    Write shared/paperIX_null_pvalues.tex including Null A and Null B.
    nullA_stats: keys = min, med, p16, p84, p_emp
    nullB_rows: list of (sigma, statsdict)
    """
    os.makedirs(os.path.dirname(out_path), exist_ok=True)

    lines: List[str] = []
    lines.append("% ============================================================")
    lines.append("% Paper IX — Null tests (v2) generated by code/null_tests_fast_v2.py")
    lines.append("% ============================================================")
    lines.append("")
    lines.append("\\subsection{Null tests and empirical tail probabilities}")
    lines.append(
        "We evaluate the anchored lattice score $\\overline{\\epsilon}$ on the observed spectrum and on "
        "two pre-registered null ensembles. We report the one-sided empirical tail probability "
        "$p_{\\mathrm{emp}}=\\Pr(\\overline{\\epsilon}_{\\mathrm{null}}\\le\\overline{\\epsilon}_{\\mathrm{obs}})$ "
        f"estimated from $N_{{\\mathrm{{null}}}}={N}$ trials (seed={seed})."
    )
    lines.append("")
    lines.append("\\paragraph{Observed score.}")
    lines.append("\\begin{equation}")
    lines.append(f"\\overline{{\\epsilon}}_{{\\mathrm{{obs}}}} = {format_sci(obs.mean_eps)}.")
    lines.append("\\end{equation}")
    lines.append("")
    lines.append("\\paragraph{Null A (i.i.d. log-uniform over observed range).}")
    lines.append("\\begin{center}")
    lines.append("\\begin{tabular}{l c}")
    lines.append("\\hline")
    lines.append("Statistic & Value \\\\")
    lines.append("\\hline")
    lines.append(f"$\\min$ & ${format_sci(nullA_stats['min'])}$ \\\\")
    lines.append(f"$\\mathrm{{median}}$ & ${format_sci(nullA_stats['med'])}$ \\\\")
    lines.append(f"$16\\%$ & ${format_sci(nullA_stats['p16'])}$ \\\\")
    lines.append(f"$84\\%$ & ${format_sci(nullA_stats['p84'])}$ \\\\")
    lines.append(f"$p_\\mathrm{{emp}}$ & ${nullA_stats['p_emp']:.6g}$ \\\\")
    lines.append("\\hline")
    lines.append("\\end{tabular}")
    lines.append("\\end{center}")
    lines.append("")
    lines.append("\\paragraph{Null B (jittered spectrum in log-space).}")
    lines.append("\\begin{center}")
    lines.append("\\begin{tabular}{c c c c c}")
    lines.append("\\hline")
    lines.append("$\\sigma$ & $\\min$ & median & $[16\\%,84\\%]$ & $p_\\mathrm{emp}$ \\\\")
    lines.append("\\hline")
    for sigma, st in nullB_rows:
        lines.append(
            f"{sigma:.3f} & ${format_sci(st['min'])}$ & ${format_sci(st['med'])}$ & "
            f"$[{format_sci(st['p16'])},\\,{format_sci(st['p84'])}]$ & ${st['p_emp']:.6g}$ \\\\"
        )
    lines.append("\\hline")
    lines.append("\\end{tabular}")
    lines.append("\\end{center}")
    lines.append("")
    lines.append("% End of auto-generated block.")

    with open(out_path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")


def summarize_trials(vals: List[float], obs_val: float) -> Dict[str, float]:
    if not vals:
        raise ValueError("No trials to summarize")
    s = sorted(vals)
    return {
        "min": s[0],
        "med": quantile(s, 0.5),
        "p16": quantile(s, 0.16),
        "p84": quantile(s, 0.84),
        "p_emp": sum(1 for v in vals if v <= obs_val) / len(vals),
    }


# ----------------------------
# Main
# ----------------------------

def resolve_default_out_tex() -> str:
    # Place output in ../shared relative to this file.
    here = os.path.dirname(os.path.abspath(__file__))
    shared = os.path.normpath(os.path.join(here, "..", "shared"))
    return os.path.join(shared, "paperIX_null_pvalues.tex")


def main() -> None:
    ap = argparse.ArgumentParser(description="Null tests v2 (fast) for anchored lattice score.")
    ap.add_argument("--N", type=int, default=2000, help="number of null trials per ensemble")
    ap.add_argument("--seed", type=int, default=1, help="RNG seed")
    ap.add_argument(
        "--sigma",
        type=float,
        nargs="*",
        default=[0.15, 0.30, 0.50],
        help="sigma values for jittered null (log-space); e.g. 0.15 0.30 0.50",
    )
    ap.add_argument("--out-tex", type=str, default=resolve_default_out_tex(), help="output .tex path")
    args = ap.parse_args()

    # Precompute feasible q values once
    print("Building feasible q-set from scan box...")
    q_list = build_feasible_q_set()
    print(f"  q-set size (deduped): {len(q_list)}")
    print(f"  scan box: a[{A_MIN},{A_MAX}], b[{B_MIN},{B_MAX}], c[{C_MIN},{C_MAX}]")
    print("")

    # Observed fit
    obs = anchored_fit_score(q_list, OBS_MASSES_MEV)
    print("=== Observed anchored scan (mean epsilon) ===")
    print(f"mean_eps_obs = {obs.mean_eps:.6e}")
    print("per-particle eps:")
    for k in OBS_MASSES_MEV.keys():
        print(f"  {k:>8s}  eps={obs.per_particle_eps[k]:.6e}  q_best={obs.per_particle_qbest[k]}")
    print("")

    rng = random.Random(args.seed)

    # Null A: log-uniform i.i.d.
    print("=== Null A: log-uniform i.i.d. ===")
    trialsA: List[float] = []
    labels_nonanchor = [k for k in OBS_MASSES_MEV.keys() if k != ANCHOR]
    for _ in range(args.N):
        massesA = null_log_uniform(rng, OBS_MASSES_MEV, n_nonanchor=len(labels_nonanchor))
        fitA = anchored_fit_score(q_list, massesA)
        trialsA.append(fitA.mean_eps)
    statsA = summarize_trials(trialsA, obs.mean_eps)
    print(f"N = {args.N}")
    print(f"min={statsA['min']:.6e} med={statsA['med']:.6e} max={max(trialsA):.6e} p_emp={statsA['p_emp']:.6g}")
    print("")

    # Null B: jittered spectrum for each sigma
    nullB_rows: List[Tuple[float, Dict[str, float]]] = []
    print("=== Null B: jittered spectrum ===")
    for sigma in args.sigma:
        trialsB: List[float] = []
        for _ in range(args.N):
            massesB = null_jittered(rng, OBS_MASSES_MEV, sigma=sigma)
            fitB = anchored_fit_score(q_list, massesB)
            trialsB.append(fitB.mean_eps)
        statsB = summarize_trials(trialsB, obs.mean_eps)
        nullB_rows.append((sigma, statsB))
        print(f"sigma={sigma:.3f}  min={statsB['min']:.6e} med={statsB['med']:.6e} "
              f"max={max(trialsB):.6e} p_emp={statsB['p_emp']:.6g}")
    print("")

    # Write LaTeX block
    out_tex = args.out_tex
    write_tex(out_tex, obs, statsA, nullB_rows, N=args.N, seed=args.seed)
    print(f"Wrote LaTeX block to: {out_tex}")
    print("")
    print("Next action:")
    print("1) In Paper IX (or CORE_MASTER), add:")
    print("   \\input{../shared/paperIX_null_pvalues.tex}")
    print("2) Rebuild CORE_MASTER.tex / MASTER.tex.")


if __name__ == "__main__":
    main()
