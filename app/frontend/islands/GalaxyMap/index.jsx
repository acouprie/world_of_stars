import { useState, useEffect, useRef, useCallback } from 'react'
import { Application, Graphics, Container, Text, TextStyle, Circle } from 'pixi.js'

// ── Planet / biome colour constants (Pixi can't read CSS vars) ────────────────

const PLANET_COLORS = {
  empty:        { color: 0xE8E4D8, alpha: 0.5, radius: 6 },
  player_other: { color: 0x7A9EC4, alpha: 1.0, radius: 7 },
  player_mine:  { color: 0x4CAF7A, alpha: 1.0, radius: 9 },
}

const BIOME_COLORS = {
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

const COORD_MAX  = 100 // must match Planet::COORD_MAX in Ruby
const WORLD_SIZE = 4000
const ZOOM_MAX   = 4.0

function getZoomMin(sw, sh) {
  return Math.max(sw / WORLD_SIZE, sh / WORLD_SIZE)
}

// ── LCG — deterministic star positions ───────────────────────────────────────

function makeLcg(seed) {
  let s = seed >>> 0
  return () => { s = (Math.imul(s, 1664525) + 1013904223) >>> 0; return s / 0xFFFFFFFF }
}

// ── Pan clamping ──────────────────────────────────────────────────────────────

function clampOffset(x, y, scale, sw, sh) {
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

// ── useIsMobile ───────────────────────────────────────────────────────────────

function useIsMobile() {
  const [mobile, setMobile] = useState(() => window.innerWidth < 768)
  useEffect(() => {
    const h = () => setMobile(window.innerWidth < 768)
    window.addEventListener('resize', h)
    return () => window.removeEventListener('resize', h)
  }, [])
  return mobile
}

// ── usePlanets ────────────────────────────────────────────────────────────────

function usePlanets() {
  const [planets,       setPlanets]       = useState([])
  const [currentUserId, setCurrentUserId] = useState(null)
  const [loading,       setLoading]       = useState(true)
  const [error,         setError]         = useState(null)

  useEffect(() => {
    const ctrl = new AbortController()
    fetch('/api/planets', { headers: { Accept: 'application/json' }, signal: ctrl.signal })
      .then(r => { if (!r.ok) throw new Error(r.status); return r.json() })
      .then(d => { setPlanets(d.planets); setCurrentUserId(d.current_user_id); setLoading(false) })
      .catch(e => { if (e.name !== 'AbortError') { setError(e.message); setLoading(false) } })
    return () => ctrl.abort()
  }, [])

  return { planets, currentUserId, loading, error }
}

// ── usePixiApp ────────────────────────────────────────────────────────────────

function usePixiApp(containerRef) {
  const [app, setApp] = useState(null)

  useEffect(() => {
    const container = containerRef.current
    if (!container) return
    let destroyed = false
    let instance  = null

    const pixi = new Application()
    pixi.init({
      background: 0x0d0e12,
      antialias: true,
      resolution: window.devicePixelRatio || 1,
      autoDensity: true,
      resizeTo: container,
    }).then(() => {
      if (destroyed) { pixi.destroy(true, { children: true }); return }
      pixi.canvas.style.cssText = 'position:absolute;top:0;left:0;'
      container.appendChild(pixi.canvas)
      instance = pixi
      setApp(pixi)
    })

    return () => {
      destroyed = true
      if (instance) { instance.destroy(true, { children: true }); setApp(null) }
    }
  }, []) // eslint-disable-line react-hooks/exhaustive-deps

  return app
}

// ── useGalaxyRenderer ─────────────────────────────────────────────────────────

function useGalaxyRenderer(app, planets, currentUserId) {
  const [selectedPlanet, _setSelectedPlanet] = useState(null)
  const [hoveredCoords,   setHoveredCoords]  = useState(null)
  const minimapCanvasRef = useRef(null)
  const controlsRef      = useRef(null)
  const selIdRef         = useRef(null)

  // Wrap setter so callers always sync the ref
  const setSelectedPlanet = useCallback((planet) => {
    selIdRef.current = planet?.id ?? null
    _setSelectedPlanet(planet)
  }, [])

  useEffect(() => {
    if (!app || planets.length === 0) return

    // ── World container ───────────────────────────────────────────────────────
    const world = new Container()
    app.stage.addChild(world)

    let scale = Math.max(getZoomMin(app.screen.width, app.screen.height), 0.5)
    let offX  = 0
    let offY  = 0

    const mine  = planets.find(p => p.planet_type === 'player' && p.user_id === currentUserId)
    const focus = mine ?? { coord_x: 50, coord_y: 50 }
    const fpx   = (focus.coord_x / COORD_MAX) * WORLD_SIZE
    const fpy   = (focus.coord_y / COORD_MAX) * WORLD_SIZE
    const sw0   = app.screen.width
    const sh0   = app.screen.height
    offX = sw0 / 2 - fpx * scale
    offY = sh0 / 2 - fpy * scale
    ;({ x: offX, y: offY } = clampOffset(offX, offY, scale, sw0, sh0))

    // ── Stars ─────────────────────────────────────────────────────────────────
    const rand    = makeLcg(42)
    const starGfx = new Graphics()
    for (let i = 0; i < 300; i++) {
      const x = rand() * WORLD_SIZE
      const y = rand() * WORLD_SIZE
      const r = [0.5, 1, 1.5][Math.floor(rand() * 3)]
      const a = 0.06 + rand() * 0.06
      starGfx.circle(x, y, r)
      starGfx.fill({ color: 0xFFFFFF, alpha: a })
    }
    world.addChild(starGfx)

    // ── Grid ──────────────────────────────────────────────────────────────────
    const gridGfx = new Graphics()
    const step    = WORLD_SIZE / 10
    for (let i = 0; i <= 10; i++) {
      const p = i * step
      gridGfx.moveTo(p, 0);    gridGfx.lineTo(p, WORLD_SIZE)
      gridGfx.moveTo(0, p);    gridGfx.lineTo(WORLD_SIZE, p)
    }
    gridGfx.stroke({ color: 0xFFFFFF, alpha: 0.04, width: 1 })
    world.addChild(gridGfx)

    // ── Planets ───────────────────────────────────────────────────────────────
    const objs    = []
    const selRing = new Graphics()
    world.addChild(selRing)
    let planetTapHandled = false

    for (const planet of planets) {
      const px  = (planet.coord_x / COORD_MAX) * WORLD_SIZE
      const py  = (planet.coord_y / COORD_MAX) * WORLD_SIZE
      const isM = planet.user_id === currentUserId
      const cfg = isM
        ? PLANET_COLORS.player_mine
        : planet.planet_type === 'player' ? PLANET_COLORS.player_other : PLANET_COLORS.empty

      const c = new Container()
      c.position.set(px, py)
      c.eventMode = 'static'
      c.cursor    = 'pointer'
      c.hitArea   = new Circle(0, 0, cfg.radius + 10)

      if (planet.is_home) {
        const halo = new Graphics()
        halo.circle(0, 0, cfg.radius + 5)
        halo.fill({ color: cfg.color, alpha: 0.25 })
        c.addChild(halo)
      }

      const dot = new Graphics()
      dot.circle(0, 0, cfg.radius)
      dot.fill({ color: cfg.color, alpha: cfg.alpha })
      c.addChild(dot)

      const label = new Text({
        text: planet.name,
        style: new TextStyle({ fontSize: 10, fill: 0xA09E96, fontFamily: 'Courier New, monospace' }),
      })
      label.position.set(cfg.radius + 3, -5)
      label.visible = false
      c.addChild(label)

      world.addChild(c)
      objs.push({ planet, cfg, label })

      c.on('pointertap', e => {
        e.stopPropagation()
        planetTapHandled = true
        setSelectedPlanet(planet)
      })
      c.on('pointerover', () => setHoveredCoords({ x: planet.coord_x, y: planet.coord_y }))
      c.on('pointerout',  () => setHoveredCoords(null))
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    function updateLabels(sc) {
      const vis = sc > 1.5
      for (const { label } of objs) label.visible = vis
    }

    function drawMinimap() {
      const mc = minimapCanvasRef.current
      if (!mc) return
      const ctx = mc.getContext('2d')
      const W = mc.width, H = mc.height
      ctx.clearRect(0, 0, W, H)
      ctx.fillStyle = 'rgba(20,21,28,0.85)'
      ctx.fillRect(0, 0, W, H)
      for (const { planet, cfg } of objs) {
        ctx.globalAlpha = cfg.alpha
        ctx.fillStyle   = '#' + cfg.color.toString(16).padStart(6, '0')
        ctx.beginPath()
        ctx.arc((planet.coord_x / COORD_MAX) * W, (planet.coord_y / COORD_MAX) * H, 1.5, 0, Math.PI * 2)
        ctx.fill()
      }
      ctx.globalAlpha = 1
      const sw = app.screen.width, sh = app.screen.height
      const vx = (-offX / scale / WORLD_SIZE) * W
      const vy = (-offY / scale / WORLD_SIZE) * H
      const vw = (sw / scale / WORLD_SIZE) * W
      const vh = (sh / scale / WORLD_SIZE) * H
      ctx.strokeStyle = 'rgba(200,169,110,0.6)'
      ctx.lineWidth   = 1
      ctx.strokeRect(vx, vy, vw, vh)
    }

    function applyTransform() {
      world.position.set(offX, offY)
      world.scale.set(scale)
      updateLabels(scale)
      drawMinimap()
    }

    applyTransform()

    // ── Resize handler ────────────────────────────────────────────────────────
    const onResize = () => {
      const sw = app.screen.width, sh = app.screen.height
      const zoomMin = getZoomMin(sw, sh)
      if (scale < zoomMin) scale = zoomMin
      ;({ x: offX, y: offY } = clampOffset(offX, offY, scale, sw, sh))
      applyTransform()
    }
    app.renderer.on('resize', onResize)

    // ── Ticker — selection ring pulse ─────────────────────────────────────────
    let elapsed = 0
    const tickerFn = ticker => {
      elapsed += ticker.deltaMS
      selRing.clear()
      const sid = selIdRef.current
      if (!sid) return
      const obj = objs.find(o => o.planet.id === sid)
      if (!obj) return
      const r = obj.cfg.radius + 6 + Math.sin(elapsed * 0.003) * 2
      const wx = (obj.planet.coord_x / COORD_MAX) * WORLD_SIZE
      const wy = (obj.planet.coord_y / COORD_MAX) * WORLD_SIZE
      selRing.circle(wx, wy, r)
      selRing.stroke({ color: obj.cfg.color, alpha: 0.85, width: 1.5 })
    }
    app.ticker.add(tickerFn)

    // ── Zoom helpers ──────────────────────────────────────────────────────────

    function applyZoom(factor, cx, cy) {
      const sw = app.screen.width, sh = app.screen.height
      const zoomMin = getZoomMin(sw, sh)
      const ns = Math.max(zoomMin, Math.min(ZOOM_MAX, scale * factor))
      const sf = ns / scale
      offX = cx - sf * (cx - offX)
      offY = cy - sf * (cy - offY)
      scale = ns
      ;({ x: offX, y: offY } = clampOffset(offX, offY, scale, sw, sh))
      applyTransform()
    }

    controlsRef.current = {
      zoom: factor => applyZoom(factor, app.screen.width / 2, app.screen.height / 2),
      resetView() {
        const f  = mine ?? { coord_x: 50, coord_y: 50 }
        const sw = app.screen.width, sh = app.screen.height
        scale = Math.max(getZoomMin(sw, sh), 0.5)
        offX  = sw / 2 - (f.coord_x / COORD_MAX) * WORLD_SIZE * scale
        offY  = sh / 2 - (f.coord_y / COORD_MAX) * WORLD_SIZE * scale
        ;({ x: offX, y: offY } = clampOffset(offX, offY, scale, sw, sh))
        applyTransform()
      },
    }

    // ── Pointer interaction ───────────────────────────────────────────────────
    const canvas = app.canvas
    const ptrs   = new Map()
    let isDragging    = false
    let hasMoved      = false
    let dragStart     = { x: 0, y: 0 }
    let dragOffStart  = { x: 0, y: 0 }
    let lastPinchDist = 0

    function onPtrDown(e) {
      e.preventDefault()
      ptrs.set(e.pointerId, { x: e.clientX, y: e.clientY })
      planetTapHandled = false
      hasMoved         = false
      if (ptrs.size === 1) {
        isDragging   = true
        dragStart    = { x: e.clientX, y: e.clientY }
        dragOffStart = { x: offX, y: offY }
      } else if (ptrs.size === 2) {
        isDragging = false
        const [a, b] = [...ptrs.values()]
        lastPinchDist = Math.hypot(b.x - a.x, b.y - a.y)
      }
    }

    function onPtrMove(e) {
      e.preventDefault()
      ptrs.set(e.pointerId, { x: e.clientX, y: e.clientY })

      if (ptrs.size === 2) {
        const [a, b] = [...ptrs.values()]
        const dist   = Math.hypot(b.x - a.x, b.y - a.y)
        if (lastPinchDist > 0) {
          const rect = canvas.getBoundingClientRect()
          applyZoom(dist / lastPinchDist, (a.x + b.x) / 2 - rect.left, (a.y + b.y) / 2 - rect.top)
        }
        lastPinchDist = dist
        isDragging    = false
        hasMoved      = true
        return
      }

      if (!isDragging) return
      const dx = e.clientX - dragStart.x
      const dy = e.clientY - dragStart.y
      if (!hasMoved && Math.hypot(dx, dy) > 5) hasMoved = true
      if (!hasMoved) return
      const sw = app.screen.width, sh = app.screen.height
      offX = dragOffStart.x + dx
      offY = dragOffStart.y + dy
      ;({ x: offX, y: offY } = clampOffset(offX, offY, scale, sw, sh))
      applyTransform()
    }

    function onPtrUp(e) {
      ptrs.delete(e.pointerId)
      if (ptrs.size < 2) lastPinchDist = 0

      if (!hasMoved && ptrs.size === 0 && !planetTapHandled) {
        setSelectedPlanet(null)
        setHoveredCoords(null)
      }

      isDragging = ptrs.size === 1
      if (isDragging) {
        const [ptr] = ptrs.values()
        dragStart    = { x: ptr.x, y: ptr.y }
        dragOffStart = { x: offX, y: offY }
        hasMoved     = false
      }
    }

    function onPtrCancel(e) {
      ptrs.delete(e.pointerId)
      isDragging    = false
      lastPinchDist = 0
    }

    function onWheel(e) {
      e.preventDefault()
      const rect = canvas.getBoundingClientRect()
      applyZoom(e.deltaY < 0 ? 1.1 : 0.9, e.clientX - rect.left, e.clientY - rect.top)
    }

    canvas.addEventListener('pointerdown',   onPtrDown,   { passive: false })
    canvas.addEventListener('pointermove',   onPtrMove,   { passive: false })
    canvas.addEventListener('pointerup',     onPtrUp)
    canvas.addEventListener('pointercancel', onPtrCancel)
    canvas.addEventListener('wheel',         onWheel,     { passive: false })

    return () => {
      canvas.removeEventListener('pointerdown',   onPtrDown)
      canvas.removeEventListener('pointermove',   onPtrMove)
      canvas.removeEventListener('pointerup',     onPtrUp)
      canvas.removeEventListener('pointercancel', onPtrCancel)
      canvas.removeEventListener('wheel',         onWheel)
      app.renderer.off('resize', onResize)
      app.ticker.remove(tickerFn)
      world.destroy({ children: true })
      controlsRef.current = null
    }
  }, [app, planets, currentUserId]) // eslint-disable-line react-hooks/exhaustive-deps

  return { selectedPlanet, setSelectedPlanet, hoveredCoords, minimapCanvasRef, controlsRef }
}

// ── InfoPanel ─────────────────────────────────────────────────────────────────

function DisabledButton({ label }) {
  return (
    <button
      disabled
      title="Disponible prochainement"
      style={{
        width: '100%', padding: '8px 12px',
        border: '1px solid var(--color-border)', borderRadius: '4px',
        background: 'none', color: 'var(--color-text-subtle)',
        fontSize: '12px', fontFamily: 'Courier New, monospace',
        cursor: 'not-allowed', letterSpacing: '0.05em',
      }}
    >
      {label}
    </button>
  )
}

function InfoPanel({ planet, currentUserId, onClose, isMobile }) {
  const open = planet !== null

  const desktopStyle = {
    width: open ? '280px' : '0',
    overflow: 'hidden',
    transition: 'width 0.2s ease',
    flexShrink: 0,
    background: 'var(--color-surface)',
    borderLeft: '1px solid var(--color-border)',
  }

  const mobileStyle = {
    position: 'absolute',
    bottom: 0, left: 0, right: 0,
    maxHeight: open ? '50vh' : '0',
    overflow: 'hidden',
    transition: 'max-height 0.2s ease',
    background: 'var(--color-surface)',
    borderTop: '1px solid var(--color-border)',
    zIndex: 20,
  }

  const panelStyle = isMobile ? mobileStyle : desktopStyle

  if (!open) return <div style={panelStyle} aria-hidden="true" />

  const ismine  = planet.user_id === currentUserId
  const isother = planet.planet_type === 'player' && !ismine
  const isempty = planet.planet_type === 'empty'
  const biomeHex = BIOME_COLORS[planet.biome] || '#a09e96'

  let subtitle = ''
  if (planet.is_home)  subtitle = "Planète d'origine"
  else if (ismine)     subtitle = 'Ma planète'
  else if (isother)    subtitle = 'Planète joueur'
  else                 subtitle = 'Planète libre'

  const statusColor = isempty ? 'var(--color-text-subtle)' : ismine ? 'var(--color-quantum)' : 'var(--color-secondary)'
  const statusLabel = isempty ? 'Non colonisée' : ismine ? 'Colonisée — vous' : 'Colonisée'

  return (
    <div style={{ ...panelStyle, padding: '16px', overflowY: 'auto', display: 'flex', flexDirection: 'column', gap: '12px', color: 'var(--color-text)' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
        <div>
          <div style={{ fontFamily: 'Orbitron, sans-serif', fontSize: '13px', fontWeight: 700, color: 'var(--color-primary)', letterSpacing: '0.05em' }}>
            {planet.name}
          </div>
          <div style={{ fontSize: '11px', color: 'var(--color-text-muted)', marginTop: '2px' }}>{subtitle}</div>
        </div>
        <button
          onClick={onClose}
          aria-label="Fermer"
          style={{ background: 'none', border: 'none', color: 'var(--color-text-muted)', cursor: 'pointer', fontSize: '16px', padding: '0 0 0 8px', lineHeight: 1 }}
        >✕</button>
      </div>

      <div style={{ fontSize: '11px', fontFamily: 'Courier New, monospace', color: 'var(--color-text-muted)' }}>
        [ {planet.coord_x} : {planet.coord_y} ]
      </div>

      <div>
        <span style={{
          display: 'inline-block', padding: '2px 8px', borderRadius: '4px',
          fontSize: '11px', fontFamily: 'Courier New, monospace', letterSpacing: '0.05em',
          background: biomeHex + '22', border: `1px solid ${biomeHex}`, color: biomeHex,
        }}>
          {planet.biome}
        </span>
      </div>

      <div style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '11px', color: 'var(--color-text-muted)' }}>
        <span style={{ width: 6, height: 6, borderRadius: '50%', background: statusColor, display: 'inline-block', flexShrink: 0 }} />
        {statusLabel}
      </div>

      <div style={{ height: 1, background: 'var(--color-border)' }} />

      {ismine && (
        <a
          href={`/planets/${planet.id}`}
          style={{
            display: 'block', textAlign: 'center', padding: '8px 12px',
            border: '1px solid var(--color-primary)', borderRadius: '4px',
            color: 'var(--color-primary)', fontSize: '12px',
            fontFamily: 'Courier New, monospace', textDecoration: 'none', letterSpacing: '0.05em',
          }}
        >
          Gérer la planète
        </a>
      )}

      {isother && (
        <>
          <div style={{ fontSize: '11px', color: 'var(--color-text-muted)' }}>
            Joueur : <span style={{ color: 'var(--color-text)' }}>{planet.user_name}</span>
          </div>
          <DisabledButton label="Envoyer une flotte" />
          <DisabledButton label="Espionner" />
        </>
      )}

      {isempty && (
        <>
          <div style={{ fontSize: '11px', color: 'var(--color-text-subtle)' }}>Planète non colonisée</div>
          <DisabledButton label="Explorer" />
        </>
      )}
    </div>
  )
}

// ── GalaxyMap ─────────────────────────────────────────────────────────────────

export default function GalaxyMap() {
  const isMobile     = useIsMobile()
  const containerRef = useRef(null)
  const { planets, currentUserId, loading, error } = usePlanets()
  const app = usePixiApp(containerRef)
  const { selectedPlanet, setSelectedPlanet, hoveredCoords, minimapCanvasRef, controlsRef } =
    useGalaxyRenderer(app, planets, currentUserId)

  const coordText = hoveredCoords
    ? `x: ${hoveredCoords.x}  y: ${hoveredCoords.y}`
    : 'x: —  y: —'

  const btnBase = {
    width: 44, height: 44,
    display: 'flex', alignItems: 'center', justifyContent: 'center',
    background: 'var(--color-surface)', border: '1px solid var(--color-border)',
    borderRadius: '4px', color: 'var(--color-text)', fontSize: '18px',
    cursor: 'pointer', fontFamily: 'Courier New, monospace',
  }

  return (
    <div style={{ display: 'flex', width: '100%', height: '100%', position: 'relative' }}>
      {/* Canvas area */}
      <div
        ref={containerRef}
        style={{ flex: 1, position: 'relative', overflow: 'hidden', background: 'var(--color-space-bg)' }}
      >
        {loading && (
          <div style={{ position: 'absolute', inset: 0, display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--color-text-muted)', fontSize: '13px', fontFamily: 'Courier New, monospace', zIndex: 5, pointerEvents: 'none' }}>
            Chargement de la galaxie…
          </div>
        )}
        {error && (
          <div style={{ position: 'absolute', inset: 0, display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--color-alert)', fontSize: '13px', fontFamily: 'Courier New, monospace', zIndex: 5, pointerEvents: 'none' }}>
            Erreur : {error}
          </div>
        )}

        {/* Coordinate display */}
        <div style={{ position: 'absolute', top: 8, left: 8, zIndex: 10, color: 'var(--color-text-subtle)', fontSize: '11px', fontFamily: 'Courier New, monospace', pointerEvents: 'none', letterSpacing: '0.05em', userSelect: 'none' }}>
          {coordText}
        </div>

        {/* Zoom buttons */}
        <div style={{ position: 'absolute', top: 8, right: 8, zIndex: 10, display: 'flex', flexDirection: 'column', gap: 4 }}>
          <button style={btnBase} onClick={() => controlsRef.current?.zoom(1.2)} aria-label="Zoom avant">+</button>
          <button style={btnBase} onClick={() => controlsRef.current?.zoom(0.8)} aria-label="Zoom arrière">−</button>
          <button style={btnBase} onClick={() => controlsRef.current?.resetView()} aria-label="Centrer" title="Centrer sur ma planète">⌂</button>
        </div>

        {/* Minimap */}
        <canvas
          ref={minimapCanvasRef}
          width={100}
          height={100}
          style={{
            position: 'absolute', bottom: 12, left: 12, zIndex: 10,
            border: '0.5px solid var(--color-border)', borderRadius: 8, opacity: 0.85,
          }}
        />
      </div>

      <InfoPanel
        planet={selectedPlanet}
        currentUserId={currentUserId}
        isMobile={isMobile}
        onClose={() => setSelectedPlanet(null)}
      />
    </div>
  )
}
