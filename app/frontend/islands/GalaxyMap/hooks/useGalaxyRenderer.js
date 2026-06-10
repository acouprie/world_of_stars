import { useState, useEffect, useRef, useCallback } from 'react'
import { Graphics, Container, Text, TextStyle, Circle } from 'pixi.js'
import { PLANET_COLORS, PLANET_STYLE, COORD_MAX, WORLD_SIZE, ZOOM_MAX, getZoomMin, makeLcg } from '../constants'

export function useGalaxyRenderer(app, planets, currentUserId) {
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

    // ── Containers séparés — nécessaire pour le tore toroïdal ───────────────
    // Le fond (3×3 tuiles) et les planètes (repositionnées par modulo) ne
    // peuvent pas partager un world container transformé globalement.
    const bgContainer     = new Container()
    const planetContainer = new Container()
    const selRing         = new Graphics()
    app.stage.addChild(bgContainer)
    app.stage.addChild(planetContainer)
    app.stage.addChild(selRing)

    let scale = Math.max(getZoomMin(app.screen.width, app.screen.height), 0.5)
    let offX  = 0
    let offY  = 0

    const mine  = planets.find(p => p.planet_type === 'player' && p.user_id === currentUserId)
    const focus = mine ?? { coord_x: 50, coord_y: 50 }
    const fpx   = (focus.coord_x / COORD_MAX) * WORLD_SIZE
    const fpy   = (focus.coord_y / COORD_MAX) * WORLD_SIZE
    offX = app.screen.width  / 2 - fpx * scale
    offY = app.screen.height / 2 - fpy * scale
    // Pas de clampOffset ici — l'offset défile librement, le modulo gère le wrap

    // ── Background (stars + grid) — 3×3 tuiles pour le scroll toroïdal ───────
    function drawHex(
      graphics,
      cx,
      cy,
      radius
    ) {
      for (let i = 0; i < 6; i++) {
        const a1 =
          ((Math.PI * 2) / 6) * i

        const a2 =
          ((Math.PI * 2) / 6) * (i + 1)

        const x1 =
          cx + Math.cos(a1) * radius

        const y1 =
          cy + Math.sin(a1) * radius

        const x2 =
          cx + Math.cos(a2) * radius

        const y2 =
          cy + Math.sin(a2) * radius

        graphics.moveTo(x1, y1)
        graphics.lineTo(x2, y2)
      }
    }

    function buildBackground() {
      const g = new Graphics()
      const rand = makeLcg(42)

      // ─────────────────────────────────────────────
      // Couche 1 : étoiles lointaines
      // ─────────────────────────────────────────────

      for (let i = 0; i < 1800; i++) {
        const x = rand() * WORLD_SIZE
        const y = rand() * WORLD_SIZE

        const radius =
          rand() < 0.85
            ? 0.4
            : rand() < 0.95
              ? 0.8
              : 1.2

        const alpha =
          0.04 +
          rand() * 0.08

        g.circle(x, y, radius)
        g.fill({
          color: 0xffffff,
          alpha,
        })
      }

      // ─────────────────────────────────────────────
      // Couche 2 : étoiles brillantes
      // ─────────────────────────────────────────────

      for (let i = 0; i < 140; i++) {
        const x = rand() * WORLD_SIZE
        const y = rand() * WORLD_SIZE

        const radius = 1.8 + rand() * 2.5

        g.circle(x, y, radius)
        g.fill({
          color: 0xf6f0d0,
          alpha: 0.25,
        })

        g.circle(x, y, radius * 2.8)
        g.fill({
          color: 0xf6f0d0,
          alpha: 0.04,
        })
      }

      // ─────────────────────────────────────────────
      // Couche 3 : nébuleuses
      // ─────────────────────────────────────────────

      const nebulaColors = [
        0x5bc4d4, // Elyrans
        0xb87fe8, // Nexhianti
        0x4e8faf, // secondaire
      ]

      for (let i = 0; i < 8; i++) {
        const centerX = rand() * WORLD_SIZE
        const centerY = rand() * WORLD_SIZE

        const color =
          nebulaColors[
            Math.floor(rand() * nebulaColors.length)
          ]

        const cloudCount = 15 + Math.floor(rand() * 10)

        for (let c = 0; c < cloudCount; c++) {
          const ox = (rand() - 0.5) * 500
          const oy = (rand() - 0.5) * 500

          const radius =
            80 +
            rand() * 220

          g.circle(
            centerX + ox,
            centerY + oy,
            radius
          )

          g.fill({
            color,
            alpha: 0.012,
          })
        }
      }

      // ─────────────────────────────────────────────
      // Couche 4 : grille hexagonale
      // ─────────────────────────────────────────────

      const hexRadius = 120

      const hexWidth = Math.sqrt(3) * hexRadius
      const hexHeight = hexRadius * 2

      const vertSpacing = hexHeight * 0.75

      for (
        let row = -2;
        row < WORLD_SIZE / vertSpacing + 2;
        row++
      ) {
        for (
          let col = -2;
          col < WORLD_SIZE / hexWidth + 2;
          col++
        ) {
          const cx =
            col * hexWidth +
            (row % 2) * (hexWidth / 2)

          const cy =
            row * vertSpacing

          drawHex(
            g,
            cx,
            cy,
            hexRadius
          )
        }
      }

      g.stroke({
        color: 0x5bc4d4,
        alpha: 0.025,
        width: 1,
      })

      // ─────────────────────────────────────────────
      // Couche 5 : axes galactiques
      // ─────────────────────────────────────────────

      for (let i = 0; i < 5; i++) {
        const y =
          WORLD_SIZE *
          (i + 1) /
          6

        g.moveTo(0, y)
        g.lineTo(WORLD_SIZE, y)
      }

      for (let i = 0; i < 5; i++) {
        const x =
          WORLD_SIZE *
          (i + 1) /
          6

        g.moveTo(x, 0)
        g.lineTo(x, WORLD_SIZE)
      }

      g.stroke({
        color: 0xc8a96e,
        alpha: 0.015,
        width: 1,
      })

      // ─────────────────────────────────────────────
      // Couche 6 : lignes de navigation
      // ─────────────────────────────────────────────

      for (let i = 0; i < 12; i++) {
        const x1 = rand() * WORLD_SIZE
        const y1 = rand() * WORLD_SIZE

        const x2 =
          x1 +
          (rand() - 0.5) * 1200

        const y2 =
          y1 +
          (rand() - 0.5) * 1200

        g.moveTo(x1, y1)
        g.lineTo(x2, y2)
      }

      g.stroke({
        color: 0x5bc4d4,
        alpha: 0.015,
        width: 1,
      })

      return g
    }

    const bgTiles = []
    for (let cy = -1; cy <= 1; cy++) {
      for (let cx = -1; cx <= 1; cx++) {
        const g = buildBackground()
        bgContainer.addChild(g)
        bgTiles.push({ cx, cy, g })
      }
    }

    // ── Planets ───────────────────────────────────────────────────────────────
    const objs        = []
    const CULL_BUFFER = 100
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

      const isColonized = planet.planet_type === 'player'

      // ── Glow layers — static, built once, hidden by LOD below threshold ──────
      const glowLayers = isColonized ? PLANET_STYLE.GLOW_LAYERS : PLANET_STYLE.GLOW_LAYERS_EMPTY
      const glow = new Graphics()
      for (const layer of glowLayers) {
        glow.circle(0, 0, cfg.radius * layer.radiusMul)
        glow.fill({ color: cfg.color, alpha: layer.alpha })
      }
      glow.visible = false
      c.addChild(glow)

      // ── Home halo — behind the core, improved radius/alpha ───────────────────
      if (planet.is_home) {
        const halo = new Graphics()
        halo.circle(0, 0, cfg.radius * PLANET_STYLE.HOME_HALO.radiusMul)
        halo.fill({ color: cfg.color, alpha: PLANET_STYLE.HOME_HALO.alpha })
        c.addChild(halo)
      }

      // ── Core ─────────────────────────────────────────────────────────────────
      const dot = new Graphics()
      dot.circle(0, 0, cfg.radius)
      dot.fill({ color: cfg.color, alpha: cfg.alpha })
      c.addChild(dot)

      // ── Orbit ring — colonised planets only, hidden by LOD below threshold ───
      let ring = null
      if (isColonized) {
        ring = new Graphics()
        ring.circle(0, 0, cfg.radius * PLANET_STYLE.RING.radiusMul)
        ring.stroke({ color: cfg.color, alpha: PLANET_STYLE.RING.alpha, width: PLANET_STYLE.RING.width })
        ring.visible = false
        c.addChild(ring)
      }

      const label = new Text({
        text: planet.name,
        style: new TextStyle({ fontSize: 10, fill: 0xA09E96, fontFamily: 'Courier New, monospace' }),
      })
      label.position.set(cfg.radius + 3, -5)
      label.visible = false
      c.addChild(label)

      // Pas de position fixe — repositionné dynamiquement par modulo dans applyTransform
      planetContainer.addChild(c)
      objs.push({ planet, cfg, container: c, label, glow, ring })

      c.on('pointertap', e => {
        e.stopPropagation()
        planetTapHandled = true
        setSelectedPlanet(planet)
      })
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    function updateLabels(sc) {
      const vis = sc > 1.5
      for (const { label } of objs) label.visible = vis
    }

    function updateLOD(sc) {
      const detailed = sc > PLANET_STYLE.LOD_THRESHOLD
      for (const { glow, ring } of objs) {
        glow.visible = detailed
        if (ring) ring.visible = detailed
      }
    }

    function screenToWorld(sx, sy) {
      const ww = WORLD_SIZE * scale
      const wh = WORLD_SIZE * scale
      const wx = (sx - offX) / scale
      const wy = (sy - offY) / scale
      const cx = Math.floor(((wx / WORLD_SIZE) * COORD_MAX % COORD_MAX + COORD_MAX) % COORD_MAX)
      const cy = Math.floor(((wy / WORLD_SIZE) * COORD_MAX % COORD_MAX + COORD_MAX) % COORD_MAX)
      return { x: cx, y: cy }
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
        ctx.arc((planet.coord_x / COORD_MAX) * W, (planet.coord_y / COORD_MAX) * H, 2, 0, Math.PI * 2)
        ctx.fill()
      }
      ctx.globalAlpha = 1
      const sw = app.screen.width, sh = app.screen.height
      const ww = WORLD_SIZE * scale, wh = WORLD_SIZE * scale
      // Viewport en espace monde normalisé [0,1) — avec wrap toroïdal
      const vx0 = (((-offX / ww) % 1) + 1) % 1
      const vy0 = (((-offY / wh) % 1) + 1) % 1
      const vw  = sw / ww
      const vh  = sh / wh
      const mx = vx0 * W, my = vy0 * H
      const mw = vw * W,  mh = vh * H
      ctx.strokeStyle = 'rgba(200,169,110,0.6)'
      ctx.lineWidth   = 1
      const mw1 = Math.min(mw, W - mx), mw2 = mw - mw1
      const mh1 = Math.min(mh, H - my), mh2 = mh - mh1
      ctx.strokeRect(mx, my, mw1, mh1)
      if (mw2 > 0)             ctx.strokeRect(0,  my, mw2, mh1)
      if (mh2 > 0)             ctx.strokeRect(mx, 0,  mw1, mh2)
      if (mw2 > 0 && mh2 > 0) ctx.strokeRect(0,  0,  mw2, mh2)
    }

    function applyTransform() {
      const ww = WORLD_SIZE * scale
      const wh = WORLD_SIZE * scale
      const sw = app.screen.width
      const sh = app.screen.height

      // Offset normalisé dans [0, ww[ pour les tuiles de fond
      const nx = ((offX % ww) + ww) % ww
      const ny = ((offY % wh) + wh) % wh

      // Tuiles de fond 3×3
      for (const { cx, cy, g } of bgTiles) {
        g.position.set(nx + cx * ww, ny + cy * wh)
        g.scale.set(scale)
      }

      // Planètes : repositionnement par modulo + frustum culling
      for (const { planet, cfg, container } of objs) {
        const basePx = (planet.coord_x / COORD_MAX) * WORLD_SIZE
        const basePy = (planet.coord_y / COORD_MAX) * WORLD_SIZE
        const sx = ((basePx * scale + offX) % ww + ww) % ww
        const sy = ((basePy * scale + offY) % wh + wh) % wh
        const onScreen = sx > -CULL_BUFFER && sx < sw + CULL_BUFFER
                      && sy > -CULL_BUFFER && sy < sh + CULL_BUFFER
        container.visible = onScreen
        if (onScreen) {
          container.position.set(sx, sy)
          container.scale.set(scale)
        }
      }

      updateLabels(scale)
      updateLOD(scale)
      drawMinimap()
    }

    applyTransform()

    // ── Resize handler ────────────────────────────────────────────────────────
    const onResize = () => {
      const sw = app.screen.width, sh = app.screen.height
      const zoomMin = getZoomMin(sw, sh)
      if (scale < zoomMin) scale = zoomMin
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
      // Position en screen-space via modulo (même logique que applyTransform)
      const basePx = (obj.planet.coord_x / COORD_MAX) * WORLD_SIZE
      const basePy = (obj.planet.coord_y / COORD_MAX) * WORLD_SIZE
      const ww = WORLD_SIZE * scale
      const wh = WORLD_SIZE * scale
      const sx = ((basePx * scale + offX) % ww + ww) % ww
      const sy = ((basePy * scale + offY) % wh + wh) % wh
      const r = obj.cfg.radius * scale + 6 + Math.sin(elapsed * 0.003) * 2
      selRing.circle(sx, sy, r)
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

      // Coordonnées monde pour le bandeau — toujours, même hors planète
      const rect = canvas.getBoundingClientRect()
      setHoveredCoords(screenToWorld(e.clientX - rect.left, e.clientY - rect.top))

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
      offX = dragOffStart.x + dx
      offY = dragOffStart.y + dy
      // Pas de clampOffset — l'offset défile librement, le modulo gère le wrap
      applyTransform()
    }

    function onPtrUp(e) {
      ptrs.delete(e.pointerId)
      if (ptrs.size < 2) lastPinchDist = 0

      if (!hasMoved && ptrs.size === 0 && !planetTapHandled) {
        setSelectedPlanet(null)
      }
      if (ptrs.size === 0) setHoveredCoords(null)

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
      bgContainer.destroy({ children: true })
      planetContainer.destroy({ children: true })
      selRing.destroy()
      controlsRef.current = null
    }
  }, [app, planets, currentUserId]) // eslint-disable-line react-hooks/exhaustive-deps

  return { selectedPlanet, setSelectedPlanet, hoveredCoords, minimapCanvasRef, controlsRef }
}
