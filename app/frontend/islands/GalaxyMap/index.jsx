import { useEffect, useRef } from 'react'

// Pixi.js galaxy map island.
// Receives initial planet data as props from Rails (ERB → JSON).
// Live updates via ActionCable (GalaxyChannel).
// See docs/architecture.md — "Points d'attention carte galaxie (Pixi.js)"
export default function GalaxyMap({ planets = [], currentPlayerId }) {
  const canvasRef = useRef(null)

  useEffect(() => {
    // TODO: initialize Pixi.js Application
    // import('@pixi/app').then(({ Application }) => { ... })
    // Use Pointer Events (not MouseEvents) for desktop + mobile
    // app.stage.on('pointerdown', onSelectPlanet)
    // app.stage.on('pointermove', onDragMap)
  }, [])

  return (
    <div className="w-full h-full" ref={canvasRef}>
      {/* Pixi.js canvas injected here */}
    </div>
  )
}
