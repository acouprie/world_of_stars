// ── Planet / biome colour constants (Pixi can't read CSS vars) ────────────────

export const PLANET_COLORS = {
  empty:        { color: 0xE8E4D8, alpha: 0.5, radius: 6 },
  player_other: { color: 0x7A9EC4, alpha: 1.0, radius: 7 },
  player_mine:  { color: 0x4CAF7A, alpha: 1.0, radius: 9 },
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
