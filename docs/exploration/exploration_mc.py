# Exploration magnitude - Monte Carlo validation at k=5 scale.
# Mechanism proposal under test:
#  - 3 independent rolls (XP / resources / losses), tier tables from GDD §7 (unchanged)
#  - LOSSES: rolled fraction f, then per-class expected losses = f * mod_escort * w_class
#      mod_escort = 1 - 0.5 * (combat units share, by count), only on non-critical tiers
#      w: recon 0.6, scientist 1.0, mule 1.2, combat 1.1 (escorts absorb)
#      CRITICAL tier (2%, 60-100%) ignores ALL modifiers (existential dread preserved)
#  - LOOT: tier % applied to cost of NON-COMBAT units only (anti money-printer),
#      capped by team transport capacity (sum over 3 resources)
#  - XP: tier % applied to team XP base (sci 60, sonde 25, others 10)
#  - Cartographie stellaire lvl c: XP x(1+0.04c), loot x(1+0.04c), losses x(1-0.02c)
#      (losses part skipped on critical tier as well)
import random
random.seed(42)

UNITS = {  # cost(k=5), transport, xp_base, class
 'maraudeur':  (500, 20, 10,'combat'), 'regulier': (575, 20, 10,'combat'),
 'sentinelle': (800, 20, 10,'combat'), 'scientifique': (650, 60, 60,'sci'),
 'sonde':      (750,150, 25,'recon'),  'spectre':  (675,  0, 25,'recon'),
 'mule':       (550,350, 10,'mule')}
W = {'recon':0.6,'sci':1.0,'mule':1.2,'combat':1.1}

RES_TIERS  = [(0.20,0,0),(0.58,0.01,0.06),(0.18,0.06,0.12),(0.04,0.12,0.25)]
XP_TIERS   = [(0.18,0,0),(0.60,0.30,0.80),(0.18,0.80,1.50),(0.04,1.50,3.00)]
LOSS_TIERS = [(0.55,0,0),(0.33,0.02,0.10),(0.10,0.10,0.30),(0.02,0.60,1.00)]

def roll(tiers):
    r=random.random(); acc=0
    for i,(p,lo,hi) in enumerate(tiers):
        acc+=p
        if r<acc: return random.uniform(lo,hi), i==len(tiers)-1
    return random.uniform(*tiers[-1][1:]), True

def mission(comp, carto=0):
    n=sum(comp.values())
    cost_all = sum(UNITS[u][0]*k for u,k in comp.items())
    cost_loot= sum(UNITS[u][0]*k for u,k in comp.items() if UNITS[u][3]!='combat')
    transport= sum(UNITS[u][1]*k for u,k in comp.items())
    xp_base  = sum(UNITS[u][2]*k for u,k in comp.items())
    share_c  = sum(k for u,k in comp.items() if UNITS[u][3]=='combat')/n
    # XP
    fx,_ = roll(XP_TIERS); xp = fx*xp_base*(1+0.04*carto)
    # loot
    fr,_ = roll(RES_TIERS); loot = min(fr*cost_loot*(1+0.04*carto), transport)
    # losses
    fl,crit = roll(LOSS_TIERS); loss_cost=0
    for u,k in comp.items():
        if crit: e = fl*k
        else:    e = fl*(1-0.5*share_c)*(1-0.02*carto)*W[UNITS[u][3]]*k
        loss_cost += min(e,k)*UNITS[u][0]
    return loot, loss_cost, xp, crit and fl>0.95

def run(name, comp, carto=0, N=200_000):
    n=sum(comp.values()); dur=(20+n)/60  # hours
    L=S=X=wip=pos=0
    for _ in range(N):
        lo,lc,xp,w = mission(comp,carto)
        L+=lo; S+=lc; X+=xp; wip+=w; pos+= lo>lc
    L/=N;S/=N;X/=N
    print(f"  {name:<34} net {L-S:>+6.0f}/mission ({(L-S)/dur:>+5.0f}/h) "
          f"loot {L:>5.0f} loss {S:>5.0f} (ratio {L/S:4.2f}) XP {X:>4.0f} "
          f"P(net+)={pos/N:4.0%}")

print("Composition sweep (carto 0, early/mid game):")
run("3 Sondes (bootstrap j1)", {'sonde':3})
run("10 Sondes", {'sonde':10})
run("10 Mules (run de butin)", {'mule':10})
run("5 Sci + 2 Maraudeurs + 2 Sondes", {'scientifique':5,'maraudeur':2,'sonde':2})
run("5 Sci + 5 Sentinelles (blindé)", {'scientifique':5,'sentinelle':5})
run("8 Sci + 4 Sent + 2 Sondes", {'scientifique':8,'sentinelle':4,'sonde':2})

print("\nLate game (Cartographie stellaire 10):")
run("8 Sci + 4 Sent + 2 Sondes, carto10", {'scientifique':8,'sentinelle':4,'sonde':2}, carto=10)
run("10 Sondes, carto10", {'sonde':10}, carto=10)

print("\nReference points: mine j10 ~1240/h, j30 ~4600/h (une ressource)")
print("Explorer 8 missions/j std team: net/day and XP/day:")
import statistics
