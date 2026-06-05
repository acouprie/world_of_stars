import { useState, useEffect, useRef } from 'react'

// ─── Metadata ─────────────────────────────────────────────────────────────────

const BUILDING_META = {
  solar_station:     { label: 'Solar Station',     category: 'energy',         icon: '☀' },
  nuclear_plant:     { label: 'Nuclear Plant',      category: 'energy',         icon: '☢' },
  metal_mine:        { label: 'Metal Mine',         category: 'production',     icon: '⛏' },
  farm:              { label: 'Farm',               category: 'production',     icon: '✿' },
  thorium_mine:      { label: 'Thorium Mine',       category: 'production',     icon: '◇' },
  food_silo:         { label: 'Food Silo',          category: 'storage',        icon: '▲' },
  metal_warehouse:   { label: 'Metal Warehouse',    category: 'storage',        icon: '□' },
  thorium_warehouse: { label: 'Thorium Warehouse',  category: 'storage',        icon: '◆' },
  command_center:    { label: 'Command Center',     category: 'infrastructure', icon: '★' },
  research_lab:      { label: 'Research Lab',       category: 'infrastructure', icon: '⊕' },
  quantum_portal:    { label: 'Quantum Portal',     category: 'infrastructure', icon: '◎' },
  radar_satellite:   { label: 'Radar Satellite',    category: 'orbital',        icon: '⊙' },
  training_camp:     { label: 'Training Camp',      category: 'military',       icon: '⚑' },
  military_camp:     { label: 'Military Camp',      category: 'military',       icon: '✦' },
  ship_factory:      { label: 'Ship Factory',       category: 'military',       icon: '▷' },
  bunker:            { label: 'Bunker',             category: 'military',       icon: '⬢' },
}

const CATEGORY_COLORS = {
  energy:         'var(--color-energy)',
  production:     'var(--color-production)',
  infrastructure: 'var(--color-infra)',
  military:       'var(--color-military)',
  storage:        'var(--color-storage)',
  orbital:        'var(--color-orbital)',
}

// ─── CSS keyframes (injected once) ────────────────────────────────────────────

const ISLAND_CSS = `
.pov-pin { touch-action: manipulation; user-select: none; }
.pov-pin-inner { transition: filter 0.15s, box-shadow 0.15s; }
.pov-pin:hover .pov-pin-inner { filter: brightness(1.35); }
.pov-pin-selected .pov-pin-inner { filter: brightness(1.2); }
.pov-slot { touch-action: manipulation; user-select: none; }
.pov-slot-inner { transition: border-color 0.15s, opacity 0.15s; }
.pov-slot:hover .pov-slot-inner { opacity: 1 !important; border-color: var(--color-text-muted) !important; }
.pov-drop-item { cursor: pointer; transition: background 0.1s; }
.pov-drop-item:hover { background: var(--color-space-bg) !important; }
@keyframes pov-pulse {
  0%   { opacity: 0.65; transform: scale(1); }
  100% { opacity: 0;    transform: scale(2.4); }
}
`

function ensureStyles() {
  if (typeof document === 'undefined' || document.getElementById('pov-styles')) return
  const el = document.createElement('style')
  el.id = 'pov-styles'
  el.textContent = ISLAND_CSS
  document.head.appendChild(el)
}

// ─── Starfield ────────────────────────────────────────────────────────────────

const STARS = [
  { cx: 25,  cy: 18,  r: 1.5, o: 0.9 }, { cx: 72,  cy: 38,  r: 1,   o: 0.7 },
  { cx: 122, cy: 12,  r: 1,   o: 0.8 }, { cx: 158, cy: 48,  r: 1.5, o: 0.6 },
  { cx: 200, cy: 22,  r: 1,   o: 0.9 }, { cx: 242, cy: 28,  r: 1,   o: 0.7 },
  { cx: 280, cy: 14,  r: 1.5, o: 0.8 }, { cx: 332, cy: 42,  r: 1,   o: 0.6 },
  { cx: 378, cy: 26,  r: 1,   o: 0.9 }, { cx: 422, cy: 52,  r: 1.5, o: 0.7 },
  { cx: 462, cy: 20,  r: 1,   o: 0.8 }, { cx: 452, cy: 82,  r: 1,   o: 0.6 },
  { cx: 392, cy: 98,  r: 1.5, o: 0.9 }, { cx: 442, cy: 142, r: 1,   o: 0.7 },
  { cx: 462, cy: 202, r: 1,   o: 0.8 }, { cx: 448, cy: 252, r: 1.5, o: 0.6 },
  { cx: 466, cy: 304, r: 1,   o: 0.9 }, { cx: 422, cy: 382, r: 1.5, o: 0.7 },
  { cx: 452, cy: 422, r: 1,   o: 0.8 }, { cx: 382, cy: 452, r: 1,   o: 0.6 },
  { cx: 322, cy: 466, r: 1.5, o: 0.9 }, { cx: 242, cy: 458, r: 1,   o: 0.7 },
  { cx: 162, cy: 462, r: 1,   o: 0.8 }, { cx: 102, cy: 452, r: 1.5, o: 0.6 },
  { cx: 52,  cy: 466, r: 1,   o: 0.9 }, { cx: 24,  cy: 422, r: 1,   o: 0.7 },
  { cx: 62,  cy: 382, r: 1.5, o: 0.8 }, { cx: 18,  cy: 322, r: 1,   o: 0.6 },
  { cx: 32,  cy: 262, r: 1.5, o: 0.9 }, { cx: 14,  cy: 196, r: 1,   o: 0.7 },
  { cx: 62,  cy: 142, r: 1,   o: 0.8 }, { cx: 28,  cy: 88,  r: 1.5, o: 0.6 },
  { cx: 92,  cy: 62,  r: 1,   o: 0.9 }, { cx: 352, cy: 92,  r: 1,   o: 0.5 },
  { cx: 412, cy: 158, r: 1.5, o: 0.7 }, { cx: 388, cy: 352, r: 1,   o: 0.6 },
  { cx: 132, cy: 412, r: 1.5, o: 0.7 }, { cx: 78,  cy: 358, r: 1,   o: 0.6 },
  { cx: 44,  cy: 436, r: 1.5, o: 0.9 }, { cx: 192, cy: 56,  r: 1,   o: 0.8 },
  { cx: 302, cy: 68,  r: 1.5, o: 0.7 }, { cx: 362, cy: 86,  r: 1,   o: 0.6 },
  { cx: 168, cy: 78,  r: 1.5, o: 0.9 }, { cx: 458, cy: 342, r: 1,   o: 0.7 },
]

// ─── Planet SVG variants ──────────────────────────────────────────────────────
// Planet center: (240, 240), radius: 160
// Orbital ring: rx=230, ry=225 — passes through the satellite slot at (82%, 15%)

function OceanicPlanet({ g }) {
  return (
    <>
      <defs>
        <radialGradient id={`${g}gr`} cx="37%" cy="32%" r="65%">
          <stop offset="0%"   stopColor="#2860c8" />
          <stop offset="55%"  stopColor="#0f2d78" />
          <stop offset="100%" stopColor="#03091e" />
        </radialGradient>
        <clipPath id={`${g}cp`}><circle cx="240" cy="240" r="160" /></clipPath>
      </defs>
      <circle cx="240" cy="240" r="160" fill={`url(#${g}gr)`} />
      <g clipPath={`url(#${g}cp)`}>
        <ellipse cx="195" cy="218" rx="50" ry="28" fill="#1a7a58" opacity="0.75" transform="rotate(-25 195 218)" />
        <ellipse cx="288" cy="268" rx="40" ry="24" fill="#1a7a58" opacity="0.65" transform="rotate(12 288 268)" />
        <ellipse cx="238" cy="178" rx="30" ry="16" fill="#1a7a58" opacity="0.55" transform="rotate(28 238 178)" />
        <ellipse cx="312" cy="212" rx="24" ry="14" fill="#1a7a58" opacity="0.5"  transform="rotate(-8 312 212)" />
        <ellipse cx="240" cy="90"  rx="56" ry="18" fill="#c8e8f4" opacity="0.55" />
        <ellipse cx="240" cy="392" rx="42" ry="14" fill="#c8e8f4" opacity="0.45" />
      </g>
      <circle cx="240" cy="240" r="164" fill="none" stroke="#4488ee" strokeWidth="10" opacity="0.12" />
      <ellipse cx="202" cy="195" rx="58" ry="40" fill="white" opacity="0.07" />
    </>
  )
}

function AridPlanet({ g }) {
  return (
    <>
      <defs>
        <radialGradient id={`${g}gr`} cx="36%" cy="30%" r="65%">
          <stop offset="0%"   stopColor="#d49840" />
          <stop offset="50%"  stopColor="#8a4e1a" />
          <stop offset="100%" stopColor="#2a0e06" />
        </radialGradient>
        <clipPath id={`${g}cp`}><circle cx="240" cy="240" r="160" /></clipPath>
      </defs>
      <circle cx="240" cy="240" r="160" fill={`url(#${g}gr)`} />
      <g clipPath={`url(#${g}cp)`}>
        <ellipse cx="240" cy="198" rx="155" ry="8"  fill="#c48830" opacity="0.5"  transform="rotate(-8 240 198)" />
        <ellipse cx="240" cy="226" rx="155" ry="7"  fill="#c48830" opacity="0.4"  transform="rotate(-5 240 226)" />
        <ellipse cx="240" cy="254" rx="155" ry="6"  fill="#b07820" opacity="0.45" transform="rotate(-3 240 254)" />
        <ellipse cx="240" cy="278" rx="155" ry="8"  fill="#c48830" opacity="0.35" transform="rotate(-7 240 278)" />
        <ellipse cx="210" cy="180" rx="40"  ry="22" fill="#b87828" opacity="0.55" transform="rotate(18 210 180)" />
        <ellipse cx="290" cy="300" rx="35"  ry="18" fill="#986020" opacity="0.5"  transform="rotate(-12 290 300)" />
      </g>
      <circle cx="240" cy="240" r="164" fill="none" stroke="#e8a840" strokeWidth="8" opacity="0.1" />
      <ellipse cx="200" cy="192" rx="55" ry="38" fill="white" opacity="0.07" />
    </>
  )
}

function VolcanicPlanet({ g }) {
  return (
    <>
      <defs>
        <radialGradient id={`${g}gr`} cx="38%" cy="32%" r="65%">
          <stop offset="0%"   stopColor="#7a1c1c" />
          <stop offset="45%"  stopColor="#3a0a0a" />
          <stop offset="100%" stopColor="#0e0202" />
        </radialGradient>
        <clipPath id={`${g}cp`}><circle cx="240" cy="240" r="160" /></clipPath>
      </defs>
      <circle cx="240" cy="240" r="160" fill={`url(#${g}gr)`} />
      <g clipPath={`url(#${g}cp)`}>
        <path d="M178,312 Q208,250 198,198 Q212,194 222,250 Q216,312 178,312Z" fill="#e86020" opacity="0.55" />
        <path d="M258,282 Q280,228 274,183 Q288,180 290,226 Q285,280 258,282Z" fill="#e87830" opacity="0.5"  />
        <path d="M218,372 Q234,330 224,294 Q238,290 240,330 Q235,372 218,372Z" fill="#d05020" opacity="0.45" />
        <path d="M154,252 Q170,220 166,194 Q178,192 180,218 Q175,252 154,252Z" fill="#f08030" opacity="0.4"  />
      </g>
      <circle cx="240" cy="240" r="164" fill="none" stroke="#e85020" strokeWidth="10" opacity="0.18" />
      <ellipse cx="204" cy="195" rx="54" ry="37" fill="white" opacity="0.06" />
    </>
  )
}

function GlacialPlanet({ g }) {
  return (
    <>
      <defs>
        <radialGradient id={`${g}gr`} cx="38%" cy="30%" r="65%">
          <stop offset="0%"   stopColor="#c8e8f8" />
          <stop offset="45%"  stopColor="#5090b8" />
          <stop offset="100%" stopColor="#0a1828" />
        </radialGradient>
        <clipPath id={`${g}cp`}><circle cx="240" cy="240" r="160" /></clipPath>
      </defs>
      <circle cx="240" cy="240" r="160" fill={`url(#${g}gr)`} />
      <g clipPath={`url(#${g}cp)`}>
        <ellipse cx="240" cy="108" rx="100" ry="38" fill="#e8f4fc" opacity="0.75" />
        <ellipse cx="240" cy="372" rx="80"  ry="30" fill="#d8eefa" opacity="0.65" />
        <ellipse cx="190" cy="222" rx="48"  ry="26" fill="#8ab8d8" opacity="0.45" transform="rotate(-15 190 222)" />
        <ellipse cx="295" cy="262" rx="42"  ry="22" fill="#a0c8e8" opacity="0.4"  transform="rotate(10 295 262)" />
        <ellipse cx="240" cy="240" rx="158" ry="155" fill="none" stroke="#c8e8ff" strokeWidth="3" opacity="0.08" />
      </g>
      <circle cx="240" cy="240" r="164" fill="none" stroke="#88ccee" strokeWidth="10" opacity="0.15" />
      <ellipse cx="198" cy="190" rx="62" ry="44" fill="white" opacity="0.12" />
    </>
  )
}

function ForestPlanet({ g }) {
  return (
    <>
      <defs>
        <radialGradient id={`${g}gr`} cx="36%" cy="30%" r="65%">
          <stop offset="0%"   stopColor="#3a7830" />
          <stop offset="50%"  stopColor="#1a4018" />
          <stop offset="100%" stopColor="#050e04" />
        </radialGradient>
        <clipPath id={`${g}cp`}><circle cx="240" cy="240" r="160" /></clipPath>
      </defs>
      <circle cx="240" cy="240" r="160" fill={`url(#${g}gr)`} />
      <g clipPath={`url(#${g}cp)`}>
        <ellipse cx="188" cy="208" rx="55" ry="32" fill="#2a6020" opacity="0.7"  transform="rotate(-20 188 208)" />
        <ellipse cx="288" cy="265" rx="45" ry="26" fill="#356828" opacity="0.65" transform="rotate(15 288 265)" />
        <ellipse cx="232" cy="172" rx="38" ry="20" fill="#285a20" opacity="0.6"  transform="rotate(25 232 172)" />
        <ellipse cx="308" cy="210" rx="30" ry="18" fill="#3a7030" opacity="0.55" transform="rotate(-10 308 210)" />
        <ellipse cx="185" cy="285" rx="35" ry="20" fill="#6a4830" opacity="0.45" transform="rotate(8 185 285)"  />
        <ellipse cx="260" cy="305" rx="28" ry="16" fill="#5a4028" opacity="0.4"  transform="rotate(-12 260 305)" />
      </g>
      <circle cx="240" cy="240" r="164" fill="none" stroke="#48a830" strokeWidth="8" opacity="0.12" />
      <ellipse cx="200" cy="192" rx="56" ry="40" fill="white" opacity="0.07" />
    </>
  )
}

function TemperatePlanet({ g }) {
  return (
    <>
      <defs>
        <radialGradient id={`${g}gr`} cx="37%" cy="31%" r="65%">
          <stop offset="0%"   stopColor="#3090d8" />
          <stop offset="50%"  stopColor="#0a4898" />
          <stop offset="100%" stopColor="#020c20" />
        </radialGradient>
        <clipPath id={`${g}cp`}><circle cx="240" cy="240" r="160" /></clipPath>
      </defs>
      <circle cx="240" cy="240" r="160" fill={`url(#${g}gr)`} />
      <g clipPath={`url(#${g}cp)`}>
        {/* Continents */}
        <ellipse cx="182" cy="220" rx="54" ry="34" fill="#3a8840" opacity="0.88" transform="rotate(-22 182 220)" />
        <ellipse cx="168" cy="248" rx="30" ry="18" fill="#286830" opacity="0.75" transform="rotate(-10 168 248)" />
        <ellipse cx="298" cy="265" rx="46" ry="28" fill="#4a9048" opacity="0.82" transform="rotate(16 298 265)" />
        <ellipse cx="318" cy="245" rx="22" ry="14" fill="#5a9850" opacity="0.7"  transform="rotate(8 318 245)"  />
        <ellipse cx="238" cy="172" rx="28" ry="15" fill="#c8a060" opacity="0.65" transform="rotate(20 238 172)" />
        {/* Cloud bands */}
        <ellipse cx="240" cy="98"  rx="64" ry="18" fill="#d8eef8" opacity="0.6"  />
        <ellipse cx="160" cy="138" rx="42" ry="12" fill="#d8eef8" opacity="0.45" transform="rotate(-10 160 138)" />
        <ellipse cx="310" cy="375" rx="52" ry="15" fill="#d8eef8" opacity="0.4"  />
      </g>
      <circle cx="240" cy="240" r="164" fill="none" stroke="#50a8e0" strokeWidth="10" opacity="0.18" />
      <ellipse cx="202" cy="195" rx="58" ry="40" fill="white" opacity="0.07" />
    </>
  )
}

function TundraPlanet({ g }) {
  return (
    <>
      <defs>
        <radialGradient id={`${g}gr`} cx="36%" cy="30%" r="65%">
          <stop offset="0%"   stopColor="#8a6040" />
          <stop offset="50%"  stopColor="#4a2e18" />
          <stop offset="100%" stopColor="#100a04" />
        </radialGradient>
        <clipPath id={`${g}cp`}><circle cx="240" cy="240" r="160" /></clipPath>
      </defs>
      <circle cx="240" cy="240" r="160" fill={`url(#${g}gr)`} />
      <g clipPath={`url(#${g}cp)`}>
        <ellipse cx="188" cy="208" rx="55" ry="32" fill="#e8e0d8" opacity="0.7"  transform="rotate(-20 188 208)" />
        <ellipse cx="288" cy="265" rx="45" ry="26" fill="#f0ece8" opacity="0.65" transform="rotate(15 288 265)" />
        <ellipse cx="232" cy="172" rx="38" ry="20" fill="#ddd8d0" opacity="0.6"  transform="rotate(25 232 172)" />
        <ellipse cx="308" cy="210" rx="30" ry="18" fill="#e8e4e0" opacity="0.55" transform="rotate(-10 308 210)" />
        <ellipse cx="185" cy="285" rx="35" ry="20" fill="#c8b8a8" opacity="0.45" transform="rotate(8 185 285)"  />
        <ellipse cx="260" cy="305" rx="28" ry="16" fill="#d8c8b8" opacity="0.4"  transform="rotate(-12 260 305)" />
      </g>
      <circle cx="240" cy="240" r="164" fill="none" stroke="#b09080" strokeWidth="8" opacity="0.1" />
      <ellipse cx="202" cy="195" rx="58" ry="40" fill="white" opacity="0.07" />
    </>
  )
}

function CrystallinePlanet({ g }) {
  return (
    <>
      <defs>
        <radialGradient id={`${g}gr`} cx="38%" cy="30%" r="65%">
          <stop offset="0%"   stopColor="#c8b8f0" />
          <stop offset="45%"  stopColor="#5828a8" />
          <stop offset="100%" stopColor="#0c0520" />
        </radialGradient>
        <clipPath id={`${g}cp`}><circle cx="240" cy="240" r="160" /></clipPath>
      </defs>
      <circle cx="240" cy="240" r="160" fill={`url(#${g}gr)`} />
      <g clipPath={`url(#${g}cp)`}>
        <polygon points="220,180 240,140 260,180 240,200" fill="#a8e8f8" opacity="0.5" />
        <polygon points="170,240 195,200 210,250 185,270" fill="#c8b8f0" opacity="0.45" />
        <polygon points="275,220 300,185 315,230 290,255" fill="#a0d8f0" opacity="0.5" />
        <polygon points="200,295 225,265 240,310 215,330" fill="#c0a8e8" opacity="0.4" />
        <polygon points="295,295 315,270 330,310 310,330" fill="#a8e0f8" opacity="0.45" />
        <line x1="220" y1="180" x2="170" y2="240" stroke="#d0e8ff" strokeWidth="1.5" opacity="0.3" />
        <line x1="260" y1="180" x2="300" y2="185" stroke="#d0e8ff" strokeWidth="1.5" opacity="0.3" />
        <line x1="185" y1="270" x2="215" y2="265" stroke="#d0e8ff" strokeWidth="1"   opacity="0.25" />
      </g>
      <circle cx="240" cy="240" r="164" fill="none" stroke="#b0a0e8" strokeWidth="9" opacity="0.2" />
      <ellipse cx="202" cy="195" rx="58" ry="40" fill="white" opacity="0.07" />
    </>
  )
}

function FungalPlanet({ g }) {
  return (
    <>
      <defs>
        <radialGradient id={`${g}gr`} cx="36%" cy="32%" r="65%">
          <stop offset="0%"   stopColor="#9848b8" />
          <stop offset="50%"  stopColor="#4a1860" />
          <stop offset="100%" stopColor="#100510" />
        </radialGradient>
        <clipPath id={`${g}cp`}><circle cx="240" cy="240" r="160" /></clipPath>
      </defs>
      <circle cx="240" cy="240" r="160" fill={`url(#${g}gr)`} />
      <g clipPath={`url(#${g}cp)`}>
        <ellipse cx="200" cy="280" rx="38" ry="22" fill="#d07830" opacity="0.55" transform="rotate(-8 200 280)"  />
        <ellipse cx="270" cy="255" rx="30" ry="18" fill="#e08838" opacity="0.5"  transform="rotate(12 270 255)"  />
        <ellipse cx="230" cy="315" rx="26" ry="16" fill="#c87028" opacity="0.5"  transform="rotate(5 230 315)"   />
        <ellipse cx="185" cy="225" rx="22" ry="32" fill="#b05898" opacity="0.55" transform="rotate(-15 185 225)" />
        <ellipse cx="275" cy="200" rx="18" ry="28" fill="#c068a8" opacity="0.5"  transform="rotate(10 275 200)"  />
        <ellipse cx="310" cy="275" rx="16" ry="24" fill="#b05898" opacity="0.45" transform="rotate(-5 310 275)"  />
        <ellipse cx="240" cy="180" rx="14" ry="20" fill="#c870b0" opacity="0.45" transform="rotate(20 240 180)"  />
        <ellipse cx="220" cy="240" rx="12" ry="8"  fill="#f09840" opacity="0.4"  />
        <ellipse cx="260" cy="290" rx="10" ry="7"  fill="#f09848" opacity="0.35" />
      </g>
      <circle cx="240" cy="240" r="164" fill="none" stroke="#a858c8" strokeWidth="9" opacity="0.15" />
      <ellipse cx="202" cy="195" rx="58" ry="40" fill="white" opacity="0.07" />
    </>
  )
}

function ToxicPlanet({ g }) {
  return (
    <>
      <defs>
        <radialGradient id={`${g}gr`} cx="37%" cy="34%" r="65%">
          <stop offset="0%"   stopColor="#a8b820" />
          <stop offset="45%"  stopColor="#504808" />
          <stop offset="100%" stopColor="#120f02" />
        </radialGradient>
        <clipPath id={`${g}cp`}><circle cx="240" cy="240" r="160" /></clipPath>
      </defs>
      <circle cx="240" cy="240" r="160" fill={`url(#${g}gr)`} />
      <g clipPath={`url(#${g}cp)`}>
        <ellipse cx="240" cy="170" rx="155" ry="28" fill="#788010" opacity="0.65" transform="rotate(-4 240 170)" />
        <ellipse cx="240" cy="205" rx="155" ry="22" fill="#909810" opacity="0.55" transform="rotate(-7 240 205)" />
        <ellipse cx="240" cy="240" rx="155" ry="20" fill="#686800" opacity="0.5"  transform="rotate(-3 240 240)" />
        <ellipse cx="240" cy="272" rx="155" ry="24" fill="#7a7808" opacity="0.6"  transform="rotate(-6 240 272)" />
        <ellipse cx="200" cy="305" rx="38"  ry="18" fill="#5a4808" opacity="0.55" transform="rotate(15 200 305)"  />
        <ellipse cx="285" cy="310" rx="30"  ry="14" fill="#4a3806" opacity="0.5"  transform="rotate(-10 285 310)" />
      </g>
      <circle cx="240" cy="240" r="164" fill="none" stroke="#90a010" strokeWidth="10" opacity="0.2" />
      <ellipse cx="202" cy="195" rx="58" ry="40" fill="white" opacity="0.07" />
    </>
  )
}

function IrradiatedPlanet({ g }) {
  return (
    <>
      <defs>
        <radialGradient id={`${g}gr`} cx="38%" cy="32%" r="65%">
          <stop offset="0%"   stopColor="#306830" />
          <stop offset="40%"  stopColor="#102818" />
          <stop offset="100%" stopColor="#020802" />
        </radialGradient>
        <clipPath id={`${g}cp`}><circle cx="240" cy="240" r="160" /></clipPath>
      </defs>
      <circle cx="240" cy="240" r="160" fill={`url(#${g}gr)`} />
      <g clipPath={`url(#${g}cp)`}>
        <circle cx="185" cy="210" r="22" fill="none" stroke="#28f040" strokeWidth="3" opacity="0.55" />
        <circle cx="185" cy="210" r="10" fill="#28f040" opacity="0.25" />
        <circle cx="295" cy="275" r="16" fill="none" stroke="#30e848" strokeWidth="2.5" opacity="0.5" />
        <circle cx="295" cy="275" r="7"  fill="#30e848" opacity="0.2" />
        <circle cx="240" cy="315" r="12" fill="none" stroke="#28f040" strokeWidth="2" opacity="0.45" />
        <circle cx="240" cy="315" r="5"  fill="#28f040" opacity="0.2" />
        <path d="M155,245 Q175,235 168,250 Q185,238 178,255 Q195,242 188,260" fill="none" stroke="#28e838" strokeWidth="2" opacity="0.4" />
        <path d="M275,180 Q290,172 285,188 Q300,178 295,195 Q310,183 305,200" fill="none" stroke="#30f040" strokeWidth="1.5" opacity="0.35" />
        <ellipse cx="240" cy="240" rx="155" ry="152" fill="none" stroke="#28f040" strokeWidth="1.5" opacity="0.12" />
      </g>
      <circle cx="240" cy="240" r="164" fill="none" stroke="#28d838" strokeWidth="10" opacity="0.22" />
      <ellipse cx="202" cy="195" rx="58" ry="40" fill="white" opacity="0.07" />
    </>
  )
}

function BarrenPlanet({ g }) {
  return (
    <>
      <defs>
        <radialGradient id={`${g}gr`} cx="38%" cy="32%" r="65%">
          <stop offset="0%"   stopColor="#885830" />
          <stop offset="50%"  stopColor="#482008" />
          <stop offset="100%" stopColor="#100602" />
        </radialGradient>
        <clipPath id={`${g}cp`}><circle cx="240" cy="240" r="160" /></clipPath>
      </defs>
      <circle cx="240" cy="240" r="160" fill={`url(#${g}gr)`} />
      <g clipPath={`url(#${g}cp)`}>
        {/* Rocky surface — irregular faceted terrain */}
        <path d="M155,200 L178,182 L210,190 L225,210 L200,228 L168,220 Z" fill="#6a3810" opacity="0.65" />
        <path d="M268,175 L295,162 L320,178 L315,205 L285,212 L262,196 Z" fill="#7a4418" opacity="0.6"  />
        <path d="M175,270 L195,255 L222,268 L215,292 L188,298 L170,284 Z" fill="#5a2e0c" opacity="0.7"  />
        <path d="M290,255 L318,245 L332,268 L322,290 L295,286 L280,270 Z" fill="#6e3c14" opacity="0.65" />
        <path d="M230,310 L252,300 L268,318 L258,338 L234,336 L222,320 Z" fill="#5c3010" opacity="0.6"  />
        {/* Cracked surface lines */}
        <path d="M185,215 Q210,235 198,262 Q220,248 240,268" fill="none" stroke="#3a1a06" strokeWidth="2.5" opacity="0.55" />
        <path d="M272,198 Q295,220 310,215 Q298,238 285,255" fill="none" stroke="#3a1a06" strokeWidth="2" opacity="0.5"  />
        <path d="M165,270 Q175,290 195,295 Q178,310 190,328"  fill="none" stroke="#2e1404" strokeWidth="1.5" opacity="0.45" />
        {/* Dust patches */}
        <ellipse cx="240" cy="192" rx="80" ry="6"  fill="#9a6028" opacity="0.35" transform="rotate(-12 240 192)" />
        <ellipse cx="240" cy="292" rx="65" ry="5"  fill="#7a4820" opacity="0.3"  transform="rotate(9 240 292)"  />
      </g>
      <circle cx="240" cy="240" r="164" fill="none" stroke="#7a4020" strokeWidth="6" opacity="0.08" />
      <ellipse cx="202" cy="195" rx="58" ry="40" fill="white" opacity="0.07" />
    </>
  )
}

function PlanetSVG({ visualType, pid }) {
  const g = `pv${pid}`
  const variants = {
    oceanic:     OceanicPlanet,
    arid:        AridPlanet,
    volcanic:    VolcanicPlanet,
    glacial:     GlacialPlanet,
    forest:      ForestPlanet,
    temperate:   TemperatePlanet,
    tundra:      TundraPlanet,
    crystalline: CrystallinePlanet,
    fungal:      FungalPlanet,
    toxic:       ToxicPlanet,
    irradiated:  IrradiatedPlanet,
    barren:      BarrenPlanet,
  }
  const Variant = variants[visualType] || ForestPlanet

  return (
    <svg
      viewBox="0 0 480 480"
      xmlns="http://www.w3.org/2000/svg"
      style={{ width: '100%', height: '100%', display: 'block', pointerEvents: 'none' }}
      aria-hidden="true"
    >
      {/* Background fill */}
      <rect width="480" height="480" fill="var(--color-space-bg-2)" />

      {/* Stars */}
      {STARS.map((s, i) => (
        <circle key={i} cx={s.cx} cy={s.cy} r={s.r} fill="white" opacity={s.o} />
      ))}

      {/* Planet */}
      <Variant g={g} />

      {/* Orbital ring — rx=230 ry=225 passes through satellite slot (82%, 15%) */}
      <ellipse
        cx="240" cy="240"
        rx="230" ry="225"
        fill="none"
        stroke="var(--color-quantum)"
        strokeWidth="1.5"
        strokeDasharray="8 6"
        opacity="0.35"
      />
    </svg>
  )
}

// ─── Building Pin ─────────────────────────────────────────────────────────────

const CONSTRUCTION_COLOR = 'var(--color-primary)'

function BuildingPin({ building, selected, onSelect, i18n, containerSize }) {
  const meta      = BUILDING_META[building.building_type] || { label: building.building_type, category: 'infrastructure', icon: '?' }
  const cat       = building.is_orbital ? 'orbital' : meta.category
  const baseColor = CATEGORY_COLORS[cat] || 'var(--color-text-muted)'
  const color     = building.in_progress ? CONSTRUCTION_COLOR : baseColor

  const lvl     = building.level
  const BASE    = containerSize * 0.075
  const pinSize = lvl >= 5 ? BASE * 1.3 : lvl >= 3 ? BASE * 1.15 : BASE
  const borderW = lvl >= 5 ? 2 : lvl >= 3 ? 1.5 : 1
  const offset  = (44 - pinSize) / 2

  const pinBg = building.in_progress
    ? 'color-mix(in srgb, var(--color-primary) 18%, var(--color-space-bg))'
    : 'var(--color-surface)'

  const pulseColor  = building.in_progress ? CONSTRUCTION_COLOR : baseColor
  const pulseSpeed  = building.in_progress ? '1.2s' : '1.8s'
  const showPulse   = building.in_progress || lvl >= 5

  const label = i18n?.building_labels?.[building.building_type] ?? meta.label
  const title = building.in_progress
    ? `${label} — construction en cours`
    : `${label} — Lv. ${lvl}`

  return (
    <div
      className={`pov-pin${selected ? ' pov-pin-selected' : ''}`}
      role="button"
      tabIndex={0}
      title={title}
      style={{
        position:  'absolute',
        left:      `${building.position_x * 100}%`,
        top:       `${building.position_y * 100}%`,
        transform: 'translate(-50%, -50%)',
        width:     '44px',
        height:    '44px',
        display:   'flex',
        alignItems:     'center',
        justifyContent: 'center',
        zIndex:    selected ? 10 : 2,
        cursor:    'pointer',
      }}
      onClick={(e) => { e.stopPropagation(); onSelect(building.id) }}
      onKeyDown={e => e.key === 'Enter' && onSelect(building.id)}
    >
      {showPulse && (
        <div
          aria-hidden="true"
          style={{
            position:     'absolute',
            top:          `${offset}px`,
            left:         `${offset}px`,
            width:        `${pinSize}px`,
            height:       `${pinSize}px`,
            borderRadius: '50%',
            border:       `2px solid ${pulseColor}`,
            animation:    `pov-pulse ${pulseSpeed} ease-out infinite`,
            pointerEvents: 'none',
          }}
        />
      )}

      <div
        className="pov-pin-inner"
        style={{
          width:          `${pinSize}px`,
          height:         `${pinSize}px`,
          minWidth:       `${pinSize}px`,
          minHeight:      `${pinSize}px`,
          borderRadius:   '50%',
          background:     pinBg,
          border:         `${borderW}px solid ${color}`,
          display:        'flex',
          justifyContent: 'center',
          alignItems:     'center',
          color,
          fontSize:    `${Math.round(pinSize)}px`,
          boxShadow:   building.in_progress
            ? `0 0 8px color-mix(in srgb, ${CONSTRUCTION_COLOR} 60%, transparent)`
            : selected ? `0 0 8px ${baseColor}` : 'none',
          fontFamily:  'monospace',
          flexShrink:  0,
          overflow:    'hidden',
          opacity:     building.in_progress && lvl === 0 ? 0.8 : 1,
        }}
      >
        <span style={{ display: 'block', lineHeight: '1', transform: 'translateY(-0.1em)' }}>
          {meta.icon}
        </span>
      </div>
    </div>
  )
}

// ─── Slot Pin (empty) ─────────────────────────────────────────────────────────

function SlotPin({ slot, isOpen, onOpen, onClose, i18n }) {
  const isOrbital  = slot.is_orbital
  const activeColor = isOrbital ? 'var(--color-quantum)' : 'var(--color-primary)'
  const baseColor   = isOrbital ? 'var(--color-quantum)' : 'var(--color-text)'
  const color       = isOpen ? activeColor : baseColor

  return (
    <div
      className="pov-slot"
      style={{
        position:  'absolute',
        left:      `${slot.position_x * 100}%`,
        top:       `${slot.position_y * 100}%`,
        transform: 'translate(-50%, -50%)',
        width:     '44px',
        height:    '44px',
        display:   'flex',
        alignItems: 'center',
        justifyContent: 'center',
        zIndex:    1,
      }}
    >
      <div
        className="pov-slot-inner"
        role="button"
        tabIndex={0}
        title={isOrbital ? (i18n?.slot_orbital ?? 'Orbital slot') : (i18n?.slot_empty ?? 'Empty slot')}
        onClick={(e) => { e.stopPropagation(); isOpen ? onClose() : onOpen() }}
        onKeyDown={e => e.key === 'Enter' && (isOpen ? onClose() : onOpen())}
        style={{
          width:        '28px',
          height:       '28px',
          borderRadius: '50%',
          border:       `1px solid ${color}`,
          background:   'var(--color-space-bg-2)',
          display:      'flex',
          alignItems:   'center',
          justifyContent: 'center',
          color,
          fontSize:     '18px',
          opacity:      isOpen ? 1 : (isOrbital ? 0.75 : 0.45),
          fontFamily:   'monospace',
          cursor:       'pointer',
          transition:   'opacity 0.15s, background 0.15s',
        }}
      >
        +
      </div>
    </div>
  )
}

// ─── Main component ──────────────────────────────────────────────────────────

export default function PlanetOrbitalView({
  planet = {},
  buildings = [],
  slots = [],
  available_building_types = [],
  i18n = {},
  onBuildingSelect,
}) {
  const [selectedId, setSelectedId] = useState(null)
  const [openSlot, setOpenSlot]     = useState(null)

  useEffect(() => { ensureStyles() }, [])

  useEffect(() => {
    const handler = () => { setOpenSlot(null); setSelectedId(null) }
    document.addEventListener("planet:panel-closed", handler)
    return () => document.removeEventListener("planet:panel-closed", handler)
  }, [])

  const containerRef = useRef(null)
  const [containerSize, setContainerSize] = useState(480)

  useEffect(() => {
    const el = containerRef.current
    if (!el) return
    const ro = new ResizeObserver(([entry]) => {
      setContainerSize(entry.contentRect.width)
    })
    ro.observe(el)
    return () => ro.disconnect()
  }, [])

  function handleBuildingSelect(buildingId) {
    setSelectedId(buildingId)
    setOpenSlot(null)
    if (typeof onBuildingSelect === 'function') {
      onBuildingSelect(buildingId)
    } else {
      document.dispatchEvent(
        new CustomEvent('planet:building-select', { bubbles: true, detail: { building_id: buildingId } })
      )
    }
  }

  function handleSlotSelect(slotIndex, buildingType) {
    setOpenSlot(null)
    if (typeof onBuildingSelect === 'function') {
      onBuildingSelect(slotIndex, buildingType)
    } else {
      document.dispatchEvent(
        new CustomEvent('planet:building-construct', { bubbles: true, detail: { slot_index: slotIndex, building_type: buildingType } })
      )
    }
  }

  return (
    <div style={{ background: 'var(--color-space-bg)', padding: '16px' }}>
      {/* Orbital view — SVG layer + pin layer share the same positioned container */}
      <div
        style={{
          position:     'relative',
          width:        '100%',
          maxWidth:     '1024px',
          aspectRatio:  '1',
          margin:       '0 auto',
          borderRadius: '12px',
          border:       '1px solid var(--color-border)',
          overflow:     'hidden',
        }}
      >
        {/* SVG planet layer */}
        <div style={{ position: 'absolute', inset: 0 }}>
          <PlanetSVG visualType={planet.biome} pid={planet.id || 0} />
        </div>

        {/* Building pins */}
        {buildings.map(b => (
          <BuildingPin
            key={b.id}
            building={b}
            selected={selectedId === b.id}
            onSelect={handleBuildingSelect}
            i18n={i18n}
            containerSize={containerSize}
          />
        ))}

        {/* Empty slot pins */}
        {slots.map(s => (
          <SlotPin
            key={s.slot_index}
            slot={s}
            isOpen={openSlot === s.slot_index}
            onOpen={() => {
              setSelectedId(null)
              setOpenSlot(s.slot_index)
              document.dispatchEvent(
                new CustomEvent('planet:slot-open', { bubbles: true, detail: { slot_index: s.slot_index } })
              )
            }}
            onClose={() => setOpenSlot(null)}
            i18n={i18n}
          />
        ))}
      </div>
    </div>
  )
}
