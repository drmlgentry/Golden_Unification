import math
import random
from dataclasses import dataclass
from typing import List, Tuple, Dict

PHI = (1.0 + 5.0 ** 0.5) / 2.0

def log_phi(x: float) -> float:
    return math.log(x) / math.log(PHI)

@dataclass
class Particle:
    name: str
    m_gev: float

# Observed set (edit/extend as you like; keep deterministic)
OBS = [
    Particle("electron", 0.00051099895),
    Particle("muon",     0.105658375),
    Particle("tau",      1.77686),
    Particle("W",       80.379),
    Particle("Z",       91.1876),
    Particle("top",    172.76),
]

def q(a:int,b:int,c:int) -> int:
    return 8*a + 15*b + 24*c

def pred_mass_ratio(qv: int) -> float:
    return PHI ** (qv / 4.0)

def best_fit_eps(target_ratio: float,
                 a_rng: Tuple[int,int],
                 b_rng: Tuple[int,int],
                 c_rng: Tuple[int,int]) -> Tuple[float, Tuple[int,int,int,int]]:
    # returns (best_eps, (a,b,c,q))
    best = (1e99, (0,0,0,0))
    for a in range(a_rng[0], a_rng[1]+1):
        for b in range(b_rng[0], b_rng[1]+1):
            for c in range(c_rng[0], c_rng[1]+1):
                qv = q(a,b,c)
                r  = pred_mass_ratio(qv)
                eps = abs(log_phi(r / target_ratio))
                if eps < best[0]:
                    best = (eps, (a,b,c,qv))
    return best

def anchored_scan(particles: List[Particle],
                  anchor: Particle = OBS[0],
                  anchor_abc: Tuple[int,int,int] = (-78,-40,51),
                  a_rng: Tuple[int,int]=(-90,-60),
                  b_rng: Tuple[int,int]=(-50, 50),
                  c_rng: Tuple[int,int]=(  0, 80)) -> Dict[str,float]:
    # anchor fixes q_e = 0 by construction in your anchored model; here we simply use ratios to electron.
    m_e = anchor.m_gev
    out = {}
    for p in particles:
        target_ratio = p.m_gev / m_e
        eps, _ = best_fit_eps(target_ratio, a_rng, b_rng, c_rng)
        out[p.name] = eps
    return out

def null_ensemble(n: int,
                  particles: List[Particle],
                  seed: int = 12345) -> List[float]:
    """
    Null: destroy particle identity by permuting log-masses among names.
    For each permutation, compute mean best-fit eps over the same scan box.
    """
    rng = random.Random(seed)
    logs = [math.log(p.m_gev) for p in particles]
    scores = []
    for _ in range(n):
        rng.shuffle(logs)
        fake = [Particle(particles[i].name, math.exp(logs[i])) for i in range(len(particles))]
        eps_map = anchored_scan(fake)
        mean_eps = sum(eps_map.values()) / len(eps_map)
        scores.append(mean_eps)
    return scores

def main():
    eps_map = anchored_scan(OBS)
    mean_eps_obs = sum(eps_map.values()) / len(eps_map)

    N = 200  # increase later (e.g. 2000) once you're satisfied
    scores = null_ensemble(N, OBS, seed=12345)
    scores_sorted = sorted(scores)

    # empirical p-value: fraction of null scores <= observed
    p_emp = sum(1 for s in scores if s <= mean_eps_obs) / float(len(scores))

    print("=== Observed anchored scan (mean epsilon) ===")
    print(f"mean_eps_obs = {mean_eps_obs:.6e}")
    print("per-particle eps:")
    for k,v in eps_map.items():
        print(f"  {k:>8s}  eps={v:.6e}")

    print("\n=== Null ensemble ===")
    print(f"N = {N}")
    print(f"min  = {scores_sorted[0]:.6e}")
    print(f"med  = {scores_sorted[N//2]:.6e}")
    print(f"max  = {scores_sorted[-1]:.6e}")
    print(f"p_emp (null mean_eps <= observed) = {p_emp:.6f}")

if __name__ == "__main__":
    main()
