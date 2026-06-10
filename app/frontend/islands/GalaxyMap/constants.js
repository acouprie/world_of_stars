// ── Planet / biome colour constants (Pixi can't read CSS vars) ────────────────

export const PLANET_COLORS = {
  empty:        { color: 0xE8E4D8, alpha: 0.5, radius: 6 },
  player_other: { color: 0x7A9EC4, alpha: 1.0, radius: 7 },
  player_mine:  { color: 0x4CAF7A, alpha: 1.0, radius: 9 },
}

// ── Visual style for planet rendering (Star Citizen / Mass Effect aesthetic) ──
// All values are relative to cfg.radius so they scale uniformly with planet size.
export const PLANET_STYLE = {
  // LOD threshold: below this zoom scale, only the core is rendered
  LOD_THRESHOLD: 1.5,

  // Glow layers for colonised planets (player_mine, player_other) — outermost first
  GLOW_LAYERS: [
    { radiusMul: 4.0, alpha: 0.04 },
    { radiusMul: 2.8, alpha: 0.10  },
    { radiusMul: 1.5, alpha: 0.22  },
  ],

  // Minimal glow for unclaimed planets — keeps readability at low zoom
  GLOW_LAYERS_EMPTY: [
    { radiusMul: 2.2, alpha: 0.08 },
  ],

  // Thin orbit ring drawn around colonised planets only
  RING: {
    radiusMul: 1.55, // ring radius = cfg.radius * radiusMul
    alpha:     0.35,
    width:     0.6,
  },

  // Halo behind the home planet
  HOME_HALO: {
    radiusMul: 1.7, // was cfg.radius + 5 for player_mine (r=9) ≈ 14 → 9 * 1.7 = 15.3
    alpha:     0.20,
  },
}

export const BIOME_COLORS = {
  oceanic:     '#2860c8',
  arid:        '#d49840',
  volcanic:    '#e85020',
  glacial:     '#5090b8',
  forest:      '#3a7830',
  temperate:   '#3090d8',
  tundra:      '#8a6040',
  crystalline: '#c8b8f0',
  fungal:      '#9848b8',
  toxic:       '#a8b820',
  irradiated:  '#28d838',
  barren:      '#885830',
}

// ── World constants ───────────────────────────────────────────────────────────

export const COORD_MAX  = 100 // must match Planet::COORD_MAX in Ruby
export const WORLD_SIZE = 4000
export const ZOOM_MAX   = 4.0

export function getZoomMin(sw, sh) {
  return Math.max(sw / WORLD_SIZE, sh / WORLD_SIZE)
}

// ── LCG — deterministic star positions ───────────────────────────────────────

export function makeLcg(seed) {
  let s = seed >>> 0
  return () => { s = (Math.imul(s, 1664525) + 1013904223) >>> 0; return s / 0xFFFFFFFF }
}

// ── Pan clamping ──────────────────────────────────────────────────────────────

export function clampOffset(x, y, scale, sw, sh) {
  const ww = WORLD_SIZE * scale
  const wh = WORLD_SIZE * scale
  let minX, maxX, minY, maxY
  if (ww <= sw) {
    const cx = (sw - ww) / 2; minX = maxX = cx
  } else {
    maxX = 0; minX = sw - ww
  }
  if (wh <= sh) {
    const cy = (sh - wh) / 2; minY = maxY = cy
  } else {
    maxY = 0; minY = sh - wh
  }
  return { x: Math.max(minX, Math.min(maxX, x)), y: Math.max(minY, Math.min(maxY, y)) }
}
