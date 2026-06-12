# Research cost/time table proposal + integrated validation:
#  - realistic income timeline (anchored: CC5 ~d10-14, CC10 ~d50-60, 30% to research)
#  - single research queue, sensible priority policy
#  - exploration XP simulation (mission ramp, Carto bonus, per-level gain mult)
#  - checkpoint audit: who binds (cost/time vs lab vs exploration), slack in days
import math

# ── Proposed cost model: cost(l) = base * f**(l-1) (total res), time likewise ──
TECHS = {
 # name:                (base, f,   max, t_base_min, g,    split m/f/t)
 'forage_cristallin':   (1600, 1.40, 18,  8, 1.55, (0.50,0.30,0.20)),
 'hydroponie':          (1600, 1.40, 18,  8, 1.55, (0.50,0.30,0.20)),
 'armement':            (1600, 1.40, 18,  8, 1.55, (0.45,0.20,0.35)),
 'blindage_tactique':   (1600, 1.40, 18,  8, 1.55, (0.45,0.20,0.35)),
 'raffinage_thorium':   (2400, 1.40, 15, 10, 1.55, (0.50,0.30,0.20)),
 'guerre_electronique': (2400, 1.40, 15, 10, 1.55, (0.45,0.20,0.35)),
 'conversion_energetique':(800,1.45, 10,  6, 1.60, (0.40,0.25,0.35)),
 'cartographie_stellaire':(1000,1.45,10,  6, 1.60, (0.40,0.25,0.35)),
 'renseignement':       (1800, 1.45, 10,  6, 1.60, (0.40,0.25,0.35)),
 'technologie_cristal': (2000, 1.00,  1, 30, 1.00, (0.40,0.20,0.40)),
 'colonisation':        (None, None,  2, None, None,(0.40,0.30,0.30)),  # manual
 'regeneration_cellulaire':(60000,1.60,5, 720,1.70,(0.35,0.25,0.40)),
}
COLO = {1:(50000, 24*60), 2:(150000, 72*60)}  # (cost, minutes)

def cost(t,l):
    if t=='colonisation': return COLO[l][0]
    b,f,*_ = TECHS[t]; return b*f**(l-1)
def rtime_min(t,l):
    if t=='colonisation': return COLO[l][1]
    b,f,mx,tb,g,_ = TECHS[t]; return tb*g**(l-1)

# ── Realistic timeline anchors (days -> total income res/h, all 3 resources) ──
INCOME = [(0,150),(2,500),(3,850),(8,2100),(14,5200),(30,11300),(55,23500),(90,23500)]
def income(d):
    for (d0,i0),(d1,i1) in zip(INCOME,INCOME[1:]):
        if d<=d1: return i0+(i1-i0)*(d-d0)/(d1-d0)
    return INCOME[-1][1]
RESEARCH_SHARE = 0.30
def budget(d, dt=0.05):  # cumulative research budget up to day d
    s=0; x=0
    while x<d: s+=RESEARCH_SHARE*income(x)*24*dt; x+=dt
    return s

# lab availability (CC mapping, realistic days, + small build margin)
LAB_DAY = {1:2.0, 2:9.0, 3:9.2, 4:9.5, 5:16.0, 6:16.5, 7:17.0, 8:36.0, 9:37.0, 10:38.5}
MIL_DAY = {4:9.0, 7:26.0, 9:40.0}   # military_camp checkpoints (CC4/CC7-era costs)

# ── Exploration simulation ────────────────────────────────────────────────────
def explo_sim(factor, sci_base=60, sonde_base=25, escort_base=10, days=90):
    # mission schedule: (from_day, missions/day, n_sci, n_sonde, n_escort)
    sched=[(0,6,0,3,0),(4,8,2,2,1),(7,8,4,1,2),(15,8,6,1,2),(35,10,8,1,2)]
    thr=[400*factor**i for i in range(12)]
    E_MULT = 0.60*0.55+0.18*1.15+0.04*2.25      # 0.627
    xp=0; lvl=0; reach={}; carto=lambda d: min(10, int(d/4))  # carto ~1 lvl / 4 days
    d=0.0; step=0.1
    while d<days:
        rate=next((s for s in reversed(sched) if d>=s[0]))
        base = rate[2]*sci_base + rate[3]*sonde_base + rate[4]*escort_base
        gain = rate[1]*step * E_MULT*base * (1+0.04*carto(d)) * (1.0292**lvl)
        xp += gain
        while lvl<11 and xp >= sum(thr[:lvl+1]): lvl+=1; reach[lvl]=round(d,1)
        d+=step
    return reach

print("Exploration curve scan (threshold factor):")
for f in (1.2, 1.5, 1.6, 1.7):
    r=explo_sim(f)
    print(f"  x{f}: " + "  ".join(f"L{k}=d{v}" for k,v in r.items() if k in (1,3,5,7,8,10)))

EXPLO_DAY = explo_sim(1.7)   # retained candidate

# ── Research queue simulation ─────────────────────────────────────────────────
# priority policy: bootstrap line, then flagship push with round-robin trailing
PLAN  = [('cartographie_stellaire',3),('conversion_energetique',4),('technologie_cristal',1),
         ('forage_cristallin',5),('armement',4),('hydroponie',4),('raffinage_thorium',3),
         ('blindage_tactique',4),('guerre_electronique',3),('cartographie_stellaire',6),
         ('forage_cristallin',9),('hydroponie',7),('armement',8),('raffinage_thorium',6),
         ('renseignement',4),('colonisation',1),('cartographie_stellaire',10),
         ('forage_cristallin',13),('armement',13),('hydroponie',10),('blindage_tactique',8),
         ('regeneration_cellulaire',2),('colonisation',2),('raffinage_thorium',10),
         ('forage_cristallin',18),('armement',18)]
steps=[]
cur={t:0 for t in TECHS}
for t,target in PLAN:
    while cur[t]<target: cur[t]+=1; steps.append((t,cur[t]))

# checkpoints: tech -> {level: {'lab':x,'explo':y,'mil':z}}
CKPT={
 'forage_cristallin':   {1:{'lab':1,'explo':1},7:{'lab':4,'explo':4},13:{'lab':7,'explo':6},17:{'lab':10,'explo':8}},
 'hydroponie':          {1:{'lab':1,'explo':1},7:{'lab':4,'explo':4},13:{'lab':7,'explo':6},17:{'lab':10,'explo':8}},
 'armement':            {1:{'lab':1,'explo':1},7:{'lab':4,'explo':4,'mil':4},13:{'lab':7,'explo':6,'mil':7},17:{'lab':10,'explo':8,'mil':9}},
 'blindage_tactique':   {1:{'lab':1,'explo':1},7:{'lab':4,'explo':4,'mil':4},13:{'lab':7,'explo':6,'mil':7},17:{'lab':10,'explo':8,'mil':9}},
 'raffinage_thorium':   {1:{'lab':2,'explo':2},6:{'lab':5,'explo':4},11:{'lab':8,'explo':6}},
 'guerre_electronique': {1:{'lab':2,'explo':2},6:{'lab':5,'explo':4,'mil':4},11:{'lab':8,'explo':6,'mil':7}},
 'conversion_energetique':{1:{'lab':1,'explo':1},6:{'lab':4,'explo':3}},
 'cartographie_stellaire':{1:{'lab':1,'explo':1},4:{'lab':3,'explo':2},8:{'lab':6,'explo':4}},
 'renseignement':       {1:{'lab':2,'explo':2},4:{'lab':4,'explo':3},8:{'lab':7,'explo':5}},
 'technologie_cristal': {1:{'lab':1,'explo':1}},
 'colonisation':        {1:{'lab':4,'explo':2},2:{'lab':4,'explo':4}},
 'regeneration_cellulaire':{1:{'lab':7,'explo':8},3:{'lab':7,'explo':9},5:{'lab':7,'explo':10}},
}
def gate_day(t,l):
    g={'day':0,'who':'-'}
    for lv,req in CKPT.get(t,{}).items():
        if l>=lv:
            for k,v in req.items():
                d = LAB_DAY[v] if k=='lab' else EXPLO_DAY.get(v,999) if k=='explo' else MIL_DAY[v]
                if d>g['day']: g={'day':d,'who':f"{k}{v}@L{lv}"}
    return g

day=0.0; spent=0.0; events=[]; binds=[]
for t,l in steps:
    c=cost(t,l)
    while budget(day)-spent < c: day+=0.25            # wait for resources
    g=gate_day(t,l)
    if g['day']>day:
        binds.append((t,l,round(day,1),g)); day=g['day']  # gate binds
    spent+=c; day+=rtime_min(t,l)/60/24                # research time (queue)
    events.append((t,l,round(day,1)))

print("\nResearch timeline (selected milestones):")
SEL={('cartographie_stellaire',3),('conversion_energetique',4),('technologie_cristal',1),
     ('forage_cristallin',5),('forage_cristallin',7),('forage_cristallin',13),('forage_cristallin',18),
     ('armement',7),('armement',13),('armement',18),('raffinage_thorium',6),
     ('colonisation',1),('colonisation',2),('regeneration_cellulaire',1),('regeneration_cellulaire',2),
     ('cartographie_stellaire',10),('renseignement',4)}
for t,l,d in events:
    if (t,l) in SEL: print(f"  d{d:>6}  {t} {l}")

print("\nGates that actually bound (player had cost ready before the gate):")
for t,l,d,g in binds: print(f"  {t} L{l}: ready d{d}, gated until d{g['day']} by {g['who']}")

print(f"\nTotal spent on research by end: {spent:,.0f} res over {day:.0f} days")
print(f"Conversion 1-4 cumulative cost: {sum(cost('conversion_energetique',i) for i in range(1,5)):,.0f}")
for t in ('forage_cristallin','raffinage_thorium','conversion_energetique','regeneration_cellulaire'):
    b,f,mx,tb,g,_=TECHS[t]
    print(f"{t}: L1={cost(t,1):,.0f}  Lmax={cost(t,mx):,.0f}  cumul={sum(cost(t,i) for i in range(1,mx+1)):,.0f}  "
          f"t(Lmax)={rtime_min(t,mx)/60:.1f}h")
