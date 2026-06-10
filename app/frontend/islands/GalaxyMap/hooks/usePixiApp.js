import { useState, useEffect } from 'react'
import { Application } from 'pixi.js'

export function usePixiApp(containerRef) {
  const [app, setApp] = useState(null)

  useEffect(() => {
    const container = containerRef.current
    if (!container) return
    let destroyed = false
    let instance  = null

    const pixi = new Application()
    pixi.init({
      background: 0x090b10,
      antialias: true,
      resolution: window.devicePixelRatio || 1,
      autoDensity: true,
      resizeTo: container,
    }).then(() => {
      if (destroyed) { pixi.destroy(true, { children: true }); return }
      pixi.canvas.style.cssText = 'position:absolute;top:0;left:0;touch-action:none;'
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
