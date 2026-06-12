import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib import font_manager
import os, json

os.makedirs("/home/claude/charts", exist_ok=True)
rng = np.random.default_rng(20260605)

# ─────────────────────────────── Palette World of Stars ───────────────────────────────
BG="#0d0e12"; SURF="#1c1d27"; BORD="#2a2b38"; TXT="#e8e4d8"; MUT="#a09e96"
AMBER="#c8a96e"; ORANGE="#e8622a"; QUANTUM="#2ec4a0"; BLUE="#4e8faf"; VIOLET="#8b7fcc"; ENERGY="#e9d454"

plt.rcParams.update({
    "figure.facecolor": BG, "axes.facecolor": SURF, "savefig.facecolor": BG,
    "text.color": TXT, "axes.labelcolor": TXT, "xtick.color": MUT, "ytick.color": MUT,
    "axes.edgecolor": BORD, "grid.color": BORD, "font.size": 11, "axes.titlesize": 13,
    "axes.grid": True, "grid.alpha": 0.35,
})

# ─────────────────────────────── Stats v2 ───────────────────────────────
# index, atk, def, int, combat, is_mule
TYPES = {
    "Maraudeur":   (16, 20, 6,  True,  False),
    "Régulier":    (11, 30, 8,  True,  False),
    "Sentinelle":  (9,  52, 10, True,  False),
    "Scientifique":(2,  14, 7,  True,  False),
    "Sonde":       (0,  12, 4,  False, False),
    "Spectre":     (0,  10, 2,  False, False),
    "Mule":        (0,  16, 1,  False, True),
}

JITTER=(0.85,1.15); RETREAT=0.55; K=8.0; CAP=40

def build(comp, stats=TYPES):
    """comp: dict {type:count} ou liste de (atk,def,int,combat,is_mule,count) pour unités synthétiques."""
    atk=[]; dfn=[]; inte=[]; comb=[]; mule=[]
    if isinstance(comp, dict):
        for t,n in comp.items():
            a,d,i,c,m = stats[t]
            atk+=[a]*n; dfn+=[d]*n; inte+=[i]*n; comb+=[c]*n; mule+=[m]*n
    else:
        for (a,d,i,c,m,n) in comp:
            atk+=[a]*n; dfn+=[d]*n; inte+=[i]*n; comb+=[c]*n; mule+=[m]*n
    return (np.array(atk,float), np.array(dfn,float), np.array(inte,int),
            np.array(comb,bool), np.array(mule,bool))

def army_int(alive, atk, inte):
    m = alive & (atk>0)
    s = atk[m].sum()
    return float((inte[m]*atk[m]).sum()/s) if s>0 else 0.0

def volley(att_alive, att_atk, def_alive, def_dfn, def_comb, def_mule, mult, jw):
    sm = att_alive & (att_atk>0)
    n = int(sm.sum())
    if n==0: return None
    elig = np.where(def_alive & def_comb)[0]
    if elig.size==0: elig = np.where(def_alive & ~def_mule)[0]
    if elig.size==0: elig = np.where(def_alive)[0]
    if elig.size==0: return None
    chosen = rng.choice(elig, size=n, replace=True)
    dmg = np.zeros(def_dfn.shape)
    jit = rng.uniform(jw[0], jw[1], size=n)
    np.add.at(dmg, chosen, att_atk[sm]*jit*mult)
    return (dmg>=def_dfn) & def_alive

def battle(A, D, jw=JITTER, retreat=RETREAT, k=K, cap=CAP):
    aa,ad,ai,ac,am = A; da,dd,di,dc,dm = D
    aliveA=np.ones(len(aa),bool); aliveD=np.ones(len(da),bool)
    a0=len(aa); rounds=0; retreated=False
    while aliveA.any() and aliveD.any():
        rounds+=1
        if rounds>cap: break
        ia=army_int(aliveA,aa,ai); idf=army_int(aliveD,da,di)
        if abs(ia-idf)<1e-9:
            kD=volley(aliveA,aa,aliveD,dd,dc,dm,1.0,jw)
            kA=volley(aliveD,da,aliveA,ad,ac,am,1.0,jw)
            if kD is not None: aliveD &= ~kD
            if kA is not None: aliveA &= ~kA
        elif ia>idf:
            kD=volley(aliveA,aa,aliveD,dd,dc,dm,1.0,jw)
            if kD is not None: aliveD &= ~kD
            if aliveD.any():
                kA=volley(aliveD,da,aliveA,ad,ac,am,1.0,jw)
                if kA is not None: aliveA &= ~kA
        else:
            kA=volley(aliveD,da,aliveA,ad,ac,am,1.0,jw)
            if kA is not None: aliveA &= ~kA
            if aliveA.any():
                kD=volley(aliveA,aa,aliveD,dd,dc,dm,1.0,jw)
                if kD is not None: aliveD &= ~kD
        if aliveD.any() and (a0-aliveA.sum())/a0 > retreat:
            delta=army_int(aliveA,aa,ai)-army_int(aliveD,da,di)
            m=min(max(0.5-delta/k,0.0),1.5)
            kA=volley(aliveD,da,aliveA,ad,ac,am,m,jw)
            if kA is not None: aliveA &= ~kA
            retreated=True; break
    nA=int(aliveA.sum()); nD=int(aliveD.sum())
    if nD==0 and nA>0: outcome="att"
    elif nA==0: outcome="def"
    else: outcome="standoff"
    return outcome, rounds, (a0-nA)/a0, (len(da)-nD)/len(da)

def montecarlo(A, D, n=2000, **kw):
    w={"att":0,"def":0,"standoff":0}; R=AL=DL=0.0
    for _ in range(n):
        o,r,al,dl=battle(A,D,**kw); w[o]+=1; R+=r; AL+=al; DL+=dl
    return dict(att=w["att"]/n, deff=w["def"]/n, standoff=w["standoff"]/n,
               hold=(w["def"]+w["standoff"])/n, rounds=R/n, al=AL/n, dl=DL/n)

# ════════════════════════ TEST 1 — Win-rate vs ratio de force ════════════════════════
print("T1 win-rate vs ratio…")
Dn=80
ratios=np.round(np.arange(0.6,2.81,0.15),2)
matchups={
    "Maraudeur → Régulier":("Maraudeur","Régulier",ORANGE),
    "Maraudeur → Sentinelle":("Maraudeur","Sentinelle",AMBER),
    "Régulier → Sentinelle":("Régulier","Sentinelle",QUANTUM),
    "Maraudeur → Maraudeur (miroir)":("Maraudeur","Maraudeur",BLUE),
}
t1={}
for label,(at,dt,col) in matchups.items():
    ys=[]
    for r in ratios:
        A=build({at:int(round(Dn*r))}); D=build({dt:Dn})
        ys.append(montecarlo(A,D,n=1200)["att"]*100)
    t1[label]=(list(ratios),ys,col)

fig,ax=plt.subplots(figsize=(8,4.6))
for label,(xs,ys,col) in t1.items():
    ax.plot(xs,ys,marker="o",ms=4,color=col,label=label,lw=2)
ax.axhline(50,color=MUT,ls="--",lw=1,alpha=.6); ax.axvline(1.0,color=MUT,ls=":",lw=1,alpha=.6)
ax.set_xlabel("Ratio de force attaquant / défenseur (effectif)"); ax.set_ylabel("Victoire attaquant (%)")
ax.set_title("Probabilité de victoire en fonction du ratio de force")
ax.legend(fontsize=8.5,facecolor=SURF,edgecolor=BORD,labelcolor=TXT); ax.set_ylim(-3,103)
fig.tight_layout(); fig.savefig("/home/claude/charts/c1_winrate_ratio.png",dpi=130); plt.close()

# ════════════════════════ TEST 2 — Matrice des ratios de bascule (50%) ════════════════════════
print("T2 break-even matrix…")
combat3=["Maraudeur","Régulier","Sentinelle"]
def breakeven(at,dt,Dn=80):
    lo,hi=0.4,5.0
    # sweep grossier puis interpolation
    for r in np.arange(0.4,5.01,0.1):
        A=build({at:int(round(Dn*r))}); D=build({dt:Dn})
        if montecarlo(A,D,n=700)["att"]>=0.5:
            return round(float(r),2)
    return float("inf")
mat=np.zeros((3,3))
for i,at in enumerate(combat3):
    for j,dt in enumerate(combat3):
        mat[i,j]=breakeven(at,dt)
        print(f"   {at:11s} -> {dt:11s} : x{mat[i,j]}")

fig,ax=plt.subplots(figsize=(6.4,5.2))
disp=np.where(np.isfinite(mat),mat,np.nan)
im=ax.imshow(disp,cmap="copper",vmin=0.6,vmax=3.2)
ax.set_xticks(range(3)); ax.set_yticks(range(3))
ax.set_xticklabels(combat3); ax.set_yticklabels(combat3)
ax.set_xlabel("Défenseur"); ax.set_ylabel("Attaquant")
ax.set_title("Ratio de force pour 50% de victoire\n(plus bas = attaquant plus efficace)")
for i in range(3):
    for j in range(3):
        v=mat[i,j]; txt="∞" if not np.isfinite(v) else f"×{v:.1f}"
        ax.text(j,i,txt,ha="center",va="center",color="#111",fontsize=14,fontweight="bold")
cb=fig.colorbar(im,fraction=0.046); cb.ax.yaxis.set_tick_params(color=MUT)
fig.tight_layout(); fig.savefig("/home/claude/charts/c2_breakeven_matrix.png",dpi=130); plt.close()

# ════════════════════════ TEST 3 — Valeur du mur ════════════════════════
print("T3 valeur du mur…")
ATTfix={"Maraudeur":120,"Régulier":60}
sent=list(range(0,91,10)); wins=[]; losses=[]
for ns in sent:
    D=build({"Régulier":100,"Sentinelle":ns}) if ns else build({"Régulier":100})
    m=montecarlo(build(ATTfix),D,n=1500); wins.append(m["att"]*100); losses.append(m["al"]*100)
fig,ax=plt.subplots(figsize=(8,4.4))
ax.plot(sent,wins,marker="o",color=ORANGE,lw=2,label="Victoire attaquant (%)")
ax.plot(sent,losses,marker="s",color=AMBER,lw=2,label="Pertes attaquant (%)")
ax.axhline(50,color=MUT,ls="--",lw=1,alpha=.6)
ax.set_xlabel("Sentinelles ajoutées à la défense (sur 100 Réguliers, attaquant fixe)")
ax.set_ylabel("%"); ax.set_title("Valeur défensive du mur — attaquant constant (180 unités)")
ax.legend(facecolor=SURF,edgecolor=BORD,labelcolor=TXT,fontsize=9)
fig.tight_layout(); fig.savefig("/home/claude/charts/c3_wall_value.png",dpi=130); plt.close()

# ════════════════════════ TEST 4 — Distribution de la durée ════════════════════════
print("T4 durée…")
def durations(A,D,n=4000):
    return [battle(A,D)[1] for _ in range(n)]
d_mirror=durations(build({"Régulier":100}),build({"Régulier":100}))
d_raid  =durations(build({"Maraudeur":120}),build({"Régulier":80}))
fig,ax=plt.subplots(figsize=(8,4.2))
bins=np.arange(0.5,max(max(d_mirror),max(d_raid))+1.5,1)
ax.hist(d_mirror,bins=bins,color=BLUE,alpha=.8,label="Miroir Régulier 100v100")
ax.hist(d_raid,bins=bins,color=ORANGE,alpha=.7,label="Raid 120 Maraudeur vs 80 Régulier")
ax.set_xlabel("Durée du combat (rounds)"); ax.set_ylabel("Occurrences (sur 4000)")
ax.set_title("Distribution de la durée des combats")
ax.legend(facecolor=SURF,edgecolor=BORD,labelcolor=TXT,fontsize=9)
fig.tight_layout(); fig.savefig("/home/claude/charts/c4_duration.png",dpi=130); plt.close()

# ════════════════════════ TEST 5 — Repli vs delta d'INT (unité synthétique) ════════════════════════
print("T5 repli vs delta…")
deltas=[]; surv=[]
ATT_INT=6
for dint in range(0,15):
    # attaquant 60 Maraudeurs ; défenseur 150 unités synthétiques (atk9,def30) avec INT variable
    A=build({"Maraudeur":60})
    D=build([(9,30,dint,True,False,150)])
    res=[battle(A,D) for _ in range(1500)]
    al=np.mean([r[2] for r in res])
    deltas.append(ATT_INT-dint); surv.append((1-al)*100)
order=np.argsort(deltas); dx=np.array(deltas)[order]; sy=np.array(surv)[order]
fig,ax=plt.subplots(figsize=(8,4.2))
ax.plot(dx,sy,marker="o",color=QUANTUM,lw=2)
ax.axvline(0,color=MUT,ls=":",lw=1,alpha=.7)
ax.set_xlabel("Δ intelligence (attaquant − défenseur)"); ax.set_ylabel("Survivants attaquant au repli (%)")
ax.set_title("Efficacité du repli selon le delta d'intelligence")
fig.tight_layout(); fig.savefig("/home/claude/charts/c5_retreat_delta.png",dpi=130); plt.close()

# ════════════════════════ TEST 6 — Robustesse (perturbation ±15%) ════════════════════════
print("T6 robustesse…")
# métrique sensible : victoire attaquant sur Maraudeur->Régulier au ratio 1.5
def metric(stats):
    A=build({"Maraudeur":120},stats); D=build({"Régulier":80},stats)
    return montecarlo(A,D,n=1500)["att"]*100
base=metric(TYPES)
perturb=[("Maraudeur","atk"),("Maraudeur","def"),("Régulier","atk"),("Régulier","def")]
idxmap={"atk":0,"def":1}
rows=[]
for (t,stat) in perturb:
    res={}
    for sign,lbl in [(-0.15,"-15%"),(0.15,"+15%")]:
        st={k:list(v) for k,v in TYPES.items()}
        st[t][idxmap[stat]]=type(TYPES[t][idxmap[stat]])(round(TYPES[t][idxmap[stat]]*(1+sign)))
        st={k:tuple(v) for k,v in st.items()}
        res[lbl]=metric(st)
    rows.append((f"{t} {stat.upper()}",res["-15%"],res["+15%"]))
    print(f"   {t} {stat}: -15%={res['-15%']:.1f}  base={base:.1f}  +15%={res['+15%']:.1f}")
# tornado
fig,ax=plt.subplots(figsize=(8,4.0))
labels=[r[0] for r in rows]; y=np.arange(len(rows))
for i,(lab,lo,hi) in enumerate(rows):
    ax.plot([lo,hi],[i,i],color=BORD,lw=8,solid_capstyle="round",zorder=1)
    ax.scatter([lo],[i],color=BLUE,zorder=3,s=55)
    ax.scatter([hi],[i],color=ORANGE,zorder=3,s=55)
ax.axvline(base,color=AMBER,lw=2,ls="--",label=f"Base = {base:.0f}%")
ax.set_yticks(y); ax.set_yticklabels(labels)
ax.set_xlabel("Victoire attaquant Maraudeur→Régulier @ ratio 1,5 (%)")
ax.set_title("Robustesse : effet d'une perturbation ±15% d'une stat")
ax.scatter([],[],color=BLUE,label="−15%"); ax.scatter([],[],color=ORANGE,label="+15%")
ax.legend(facecolor=SURF,edgecolor=BORD,labelcolor=TXT,fontsize=8.5,loc="lower right")
fig.tight_layout(); fig.savefig("/home/claude/charts/c6_robustness.png",dpi=130); plt.close()

# ════════════════════════ TEST 7 — chiffres récap (asymétrie de rôle, non-combattants) ════════════════════════
print("T7 récap…")
summary={}
# Home advantage : miroir, attaquant gagne X%
for t in combat3:
    summary[f"miroir_{t}"]=montecarlo(build({t:100}),build({t:100}),n=2500)
# raids
for d in (40,60,80):
    summary[f"raid_M_vs_{d}R"]=montecarlo(build({"Maraudeur":100}),build({"Régulier":d}),n=2500)
# non-combattants
summary["spectre_vs_reg"]=montecarlo(build({"Spectre":150}),build({"Régulier":40}),n=1500)
summary["mule_pillage"]=montecarlo(build({"Régulier":40}),build({"Mule":120}),n=1500)
# asymétrie de rôle : mêmes forces, on échange attaquant/défenseur
fa=montecarlo(build({"Régulier":100}),build({"Maraudeur":100}),n=2500)
fb=montecarlo(build({"Maraudeur":100}),build({"Régulier":100}),n=2500)
summary["role_R_att_vs_M_def"]=fa; summary["role_M_att_vs_R_def"]=fb

out={
 "stats":{k:{"atk":v[0],"def":v[1],"int":v[2]} for k,v in TYPES.items()},
 "t1":t1,"breakeven":mat.tolist(),"combat3":combat3,
 "wall":{"sent":sent,"wins":wins,"losses":losses},
 "dur":{"mirror_mean":float(np.mean(d_mirror)),"raid_mean":float(np.mean(d_raid)),
        "mirror_p95":float(np.percentile(d_mirror,95)),"raid_p95":float(np.percentile(d_raid,95))},
 "retreat":{"delta":[int(x) for x in dx],"surv":[float(s) for s in sy]},
 "robust":{"base":base,"rows":rows},
 "summary":{k:{kk:round(vv,3) for kk,vv in v.items()} for k,v in summary.items()},
}
json.dump(out,open("/home/claude/sim_results.json","w"),ensure_ascii=False,indent=1)
print("\n--- charts générés ---"); print(os.listdir("/home/claude/charts"))
print("\nRESUME CLEF:")
print(" home advantage (miroir, victoire ATT):",
      {t:round(summary[f'miroir_{t}']['att']*100,1) for t in combat3})
print(" raids M vs 40/60/80 R (victoire ATT, pertes ATT):",
      {d:(round(summary[f'raid_M_vs_{d}R']['att']*100,1),round(summary[f'raid_M_vs_{d}R']['al']*100,1)) for d in (40,60,80)})
print(" Spectre att win%:",round(summary['spectre_vs_reg']['att']*100,2),
      "| Mule pillage win%:",round(summary['mule_pillage']['att']*100,1))
print(" robustesse base/min/max:",round(base,1),
      round(min(min(r[1],r[2]) for r in rows),1),round(max(max(r[1],r[2]) for r in rows),1))
