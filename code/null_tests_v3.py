#!/usr/bin/env python3
import os, math, random, argparse
from dataclasses import dataclass
from typing import Dict, List, Tuple

PHI = (1.0 + 5.0 ** 0.5) / 2.0

def q_of(a: int, b: int, c: int) -> int:
    return 8*a + 15*b + 24*c

def log_phi(x: float) -> float:
    return math.log(x) / math.log(PHI)

def ratio_from_q(q: int) -> float:
    return PHI ** (q / 4.0)

@dataclass
class Particle:
    name: str
    mexp: float

DEFAULT_PARTICLES = [
    Particle("electron", 0.00051099895),
    Particle("muon",     0.105658375),
    Particle("tau",      1.77686),
    Particle("W",        80.379),
    Particle("Z",        91.1876),
    Particle("top",      172.76),
]

DEFAULT_BOUNDS = dict(a_min=-80, a_max=20, b_min=-40, b_max=40, c_min=-40, c_max=60)

def build_q_set(bounds: Dict[str,int]) -> List[int]:
    qs = set()
    for a in range(bounds["a_min"], bounds["a_max"]+1):
        for b in range(bounds["b_min"], bounds["b_max"]+1):
            for c in range(bounds["c_min"], bounds["c_max"]+1):
                qs.add(q_of(a,b,c))
    return sorted(qs)

def best_eps_for_mass_ratio(ratio: float, q_set: List[int]) -> Tuple[float,int]:
    best_eps = 1e99
    best_q = None
    for q in q_set:
        eps = abs(log_phi(ratio_from_q(q) / ratio))
        if eps < best_eps:
            best_eps = eps
            best_q = q
    return best_eps, best_q

def observed_mean_eps(particles: List[Particle], q_set: List[int]) -> Tuple[float, Dict[str,Tuple[float,int]]]:
    me = particles[0].mexp
    details = {}
    eps_list = []
    for p in particles:
        ratio = p.mexp / me
        eps, qb = best_eps_for_mass_ratio(ratio, q_set)
        details[p.name] = (eps, qb)
        eps_list.append(eps)
    return sum(eps_list)/len(eps_list), details

def null_A_loguniform(particles: List[Particle], q_set: List[int], N: int, seed: int) -> List[float]:
    random.seed(seed)
    me = particles[0].mexp
    ratios_obs = [p.mexp/me for p in particles]
    loglo = math.log(min(ratios_obs))
    loghi = math.log(max(ratios_obs))

    out = []
    for _ in range(N):
        ratios = [math.exp(random.uniform(loglo, loghi)) for _ in particles]
        ratios[0] = 1.0
        eps_list = [best_eps_for_mass_ratio(r, q_set)[0] for r in ratios]
        out.append(sum(eps_list)/len(eps_list))
    return out

def null_B_jitter(particles: List[Particle], q_set: List[int], N: int, sigma: float, seed: int) -> List[float]:
    random.seed(seed + int(1000*sigma))
    me = particles[0].mexp
    ratios_obs = [p.mexp/me for p in particles]
    logs = [math.log(r) for r in ratios_obs]

    out = []
    for _ in range(N):
        logs_j = logs[:]
        for i in range(1, len(logs_j)):
            logs_j[i] = logs_j[i] + random.gauss(0.0, sigma)
        ratios = [math.exp(x) for x in logs_j]
        ratios[0] = 1.0
        eps_list = [best_eps_for_mass_ratio(r, q_set)[0] for r in ratios]
        out.append(sum(eps_list)/len(eps_list))
    return out

def empirical_pvalue(samples: List[float], obs: float) -> float:
    return sum(1 for x in samples if x <= obs) / len(samples)

def write_tex(out_path: str, obs_mean: float, details: Dict[str,Tuple[float,int]],
              A_stats: Dict[str,float], B_rows: List[Tuple[float,Dict[str,float]]]) -> None:

    lines = []
    lines.append("% ============================================================")
    lines.append("% AUTO: Null Tests v3 (anchored lattice fit) - generated file")
    lines.append("% ============================================================")
    lines.append("\\subsection{Null tests and empirical p-values}")
    lines.append("We quantify whether the anchored lattice fit quality could arise under simple null ensembles.")
    lines.append("The test statistic is the mean per-particle log-base-$\\varphi$ error $\\bar\\epsilon$.")
    lines.append("")
    lines.append("\\paragraph{Observed anchored scan.}")
    lines.append("\\begin{align}")
    lines.append(f"\\bar\\epsilon_\\mathrm{{obs}} &= {obs_mean:.6e}.")
    lines.append("\\end{align}")
    lines.append("")
    lines.append("\\begin{center}")
    lines.append("\\begin{tabular}{lcc}")
    lines.append("\\hline")
    lines.append("Particle & $\\epsilon$ & best $q$\\\\")
    lines.append("\\hline")
    for name,(eps,qb) in details.items():
        lines.append(f"{name} & {eps:.6e} & {qb}\\\\")
    lines.append("\\hline")
    lines.append("\\end{tabular}")
    lines.append("\\end{center}")
    lines.append("")
    lines.append("\\paragraph{Null A (log-uniform i.i.d.).}")
    lines.append("\\begin{align}")
    lines.append(f"\\mathrm{{min}}={A_stats['min']:.6e},\\;\\mathrm{{med}}={A_stats['med']:.6e},\\;\\mathrm{{max}}={A_stats['max']:.6e},\\;p_\\mathrm{{emp}}={A_stats['p']:.6f}.")
    lines.append("\\end{align}")
    lines.append("")
    lines.append("\\paragraph{Null B (jittered spectrum).}")
    lines.append("\\begin{center}")
    lines.append("\\begin{tabular}{lcccc}")
    lines.append("\\hline")
    lines.append("$\\sigma$ & min & med & max & $p_\\mathrm{emp}$\\\\")
    lines.append("\\hline")
    for sigma,st in B_rows:
        lines.append(f"{sigma:.3f} & {st['min']:.6e} & {st['med']:.6e} & {st['max']:.6e} & {st['p']:.6f}\\\\")
    lines.append("\\hline")
    lines.append("\\end{tabular}")
    lines.append("\\end{center}")
    lines.append("")

    os.makedirs(os.path.dirname(os.path.abspath(out_path)), exist_ok=True)
    with open(out_path, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines) + "\n")

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--N", type=int, default=2000)
    ap.add_argument("--seed", type=int, default=12345)
    ap.add_argument("--out", type=str, default=None)
    ap.add_argument("--sigma_list", type=str, default="0.150,0.300,0.500")
    args = ap.parse_args()

    here = os.path.dirname(os.path.abspath(__file__))
    default_out = os.path.abspath(os.path.join(here, "..", "shared", "paperIX_null_v3.tex"))
    out_path = os.path.abspath(args.out) if args.out else default_out

    q_set = build_q_set(DEFAULT_BOUNDS)
    obs_mean, details = observed_mean_eps(DEFAULT_PARTICLES, q_set)

    A = null_A_loguniform(DEFAULT_PARTICLES, q_set, N=args.N, seed=args.seed)
    A_sorted = sorted(A)
    A_stats = dict(min=min(A), med=A_sorted[len(A_sorted)//2], max=max(A), p=empirical_pvalue(A, obs_mean))

    B_rows = []
    for s in [float(x.strip()) for x in args.sigma_list.split(",") if x.strip()]:
        B = null_B_jitter(DEFAULT_PARTICLES, q_set, N=args.N, sigma=s, seed=args.seed)
        B_sorted = sorted(B)
        st = dict(min=min(B), med=B_sorted[len(B_sorted)//2], max=max(B), p=empirical_pvalue(B, obs_mean))
        B_rows.append((s, st))

    write_tex(out_path, obs_mean, details, A_stats, B_rows)
    print("Wrote LaTeX block to:", out_path)
    print("Bytes:", os.path.getsize(out_path))
    print("N =", args.N, "seed =", args.seed)

if __name__ == "__main__":
    main()
