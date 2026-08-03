import { useRef, useState, useEffect } from 'react'
import { BIOME_COLORS, PLANET_COLORS, HUD, WORLD_SIZE } from './constants'
import { useIsMobile } from './hooks/useIsMobile'
import { usePlanets } from './hooks/usePlanets'
import { usePixiApp } from './hooks/usePixiApp'
import { useGalaxyRenderer } from './hooks/useGalaxyRenderer'

// ── DisabledButton ─────────────────────────────────────────────────────────────

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

// ── ExplorationModal ───────────────────────────────────────────────────────────

function ExplorationModal({ sourcePlanetId, targetPlanet, onClose }) {
  const [readiness, setReadiness] = useState(null)
  const [force, setForce] = useState({})
  const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

  useEffect(() => {
    fetch(`/api/planets/${sourcePlanetId}/exploration_readiness`)
      .then(r => r.json())
      .then(data => {
        setReadiness(data)
        const initial = {}
        data.units.forEach(u => { initial[u.type] = 0 })
        setForce(initial)
      })
  }, [sourcePlanetId])

  const totalForce = Object.values(force).reduce((a, b) => a + b, 0)
  const durationMin = 20 + totalForce
  const canSubmit = readiness?.can_launch && totalForce > 0

  return (
    <div
      onClick={e => { if (e.target === e.currentTarget) onClose() }}
      style={{
        position: 'fixed', inset: 0, zIndex: 100,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        background: 'rgba(0,0,0,0.6)', backdropFilter: 'blur(2px)',
      }}
    >
      <div style={{
        width: '100%', maxWidth: 420,
        background: 'var(--color-surface)',
        border: '1px solid var(--color-border)',
        borderRadius: '8px',
        padding: '20px',
        display: 'flex', flexDirection: 'column', gap: '16px',
        color: 'var(--color-text)',
        margin: '0 16px',
      }}>
        {/* Header */}
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
          <div>
            <div style={{ fontFamily: 'Orbitron, sans-serif', fontSize: '12px', fontWeight: 700, color: 'var(--color-quantum)', letterSpacing: '0.08em', textTransform: 'uppercase' }}>
              Exploration
            </div>
            <div style={{ fontSize: '13px', color: 'var(--color-text)', marginTop: '4px' }}>
              {targetPlanet.name}
              <span style={{ fontSize: '11px', color: 'var(--color-text-muted)', marginLeft: '6px' }}>
                [ {targetPlanet.coord_x} : {targetPlanet.coord_y} ]
              </span>
            </div>
          </div>
          <button
            onClick={onClose}
            style={{ background: 'none', border: 'none', color: 'var(--color-text-muted)', cursor: 'pointer', fontSize: '16px', padding: 0, lineHeight: 1 }}
          >✕</button>
        </div>

        <div style={{ height: 1, background: 'var(--color-border)' }} />

        {!readiness ? (
          <div style={{ fontSize: '12px', color: 'var(--color-text-muted)', fontFamily: 'Courier New, monospace', textAlign: 'center', padding: '12px 0' }}>
            Chargement…
          </div>
        ) : (
          <>
            {!readiness.can_launch && (
              <div style={{ fontSize: '11px', color: 'var(--color-alert)', fontFamily: 'Courier New, monospace' }}>
                ⊘ Missions actives : {readiness.active_missions} / {readiness.max_missions}
              </div>
            )}

            {readiness.units.length === 0 ? (
              <div style={{ fontSize: '12px', color: 'var(--color-text-subtle)', fontFamily: 'Courier New, monospace' }}>
                Aucune unité disponible pour l'exploration.
              </div>
            ) : (
              <form
                action={`/planets/${sourcePlanetId}/explorations`}
                method="post"
                style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}
              >
                <input type="hidden" name="authenticity_token" value={csrfToken} />
                <input type="hidden" name="target_planet_id" value={targetPlanet.id} />

                <div style={{ fontSize: '11px', color: 'var(--color-text-muted)', fontFamily: 'Courier New, monospace', textTransform: 'uppercase', letterSpacing: '0.06em' }}>
                  Composer la force
                </div>

                {readiness.units.map(unit => (
                  <div key={unit.type} style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: '8px' }}>
                    <div style={{ display: 'flex', flexDirection: 'column', gap: '1px' }}>
                      <span style={{ fontSize: '12px', color: 'var(--color-text)', fontFamily: 'Courier New, monospace' }}>{unit.name}</span>
                      <span style={{ fontSize: '10px', color: 'var(--color-text-muted)', fontFamily: 'Courier New, monospace' }}>Disponibles : {unit.count}</span>
                    </div>
                    <input
                      type="number"
                      name={`force[${unit.type}]`}
                      min={0}
                      max={unit.count}
                      value={force[unit.type] ?? 0}
                      onChange={e => {
                        const val = Math.min(parseInt(e.target.value) || 0, unit.count)
                        setForce(prev => ({ ...prev, [unit.type]: val }))
                      }}
                      style={{
                        width: '72px', padding: '6px 8px',
                        background: 'var(--color-bg)', border: '1px solid var(--color-border)',
                        borderRadius: '4px', color: 'var(--color-text)',
                        fontSize: '12px', fontFamily: 'Courier New, monospace',
                        textAlign: 'right',
                      }}
                    />
                  </div>
                ))}

                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', paddingTop: '4px' }}>
                  <span style={{ fontSize: '11px', color: 'var(--color-text-muted)', fontFamily: 'Courier New, monospace' }}>
                    Durée estimée : ~{durationMin} min
                  </span>
                  <button
                    type="submit"
                    disabled={!canSubmit}
                    style={{
                      padding: '8px 16px',
                      border: `1px solid ${canSubmit ? 'var(--color-quantum)' : 'var(--color-border)'}`,
                      borderRadius: '4px',
                      background: 'none',
                      color: canSubmit ? 'var(--color-quantum)' : 'var(--color-text-subtle)',
                      fontSize: '12px', fontFamily: 'Courier New, monospace',
                      cursor: canSubmit ? 'pointer' : 'not-allowed',
                      letterSpacing: '0.05em',
                    }}
                  >
                    Lancer l'expédition
                  </button>
                </div>
              </form>
            )}
          </>
        )}
      </div>
    </div>
  )
}

// ── InfoPanel ─────────────────────────────────────────────────────────────────

function InfoPanel({ planet, currentUserId, onClose, isMobile, sourcePlanetId, hasQuantumPortal, onExplore }) {
  const open = planet !== null

  const desktopStyle = {
    width: open ? '280px' : '0',
    overflowX: 'hidden',
    overflowY: 'hidden',
    transition: 'width 0.2s ease',
    flexShrink: 0,
    background: 'var(--color-surface)',
    borderLeft: '1px solid var(--color-border)',
  }

  const mobileStyle = {
    position: 'absolute',
    bottom: 0, left: 0, right: 0,
    maxHeight: open ? '50vh' : '0',
    overflowX: 'hidden',
    overflowY: 'hidden',
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

  const toCSS = n => '#' + n.toString(16).padStart(6, '0')
  const nameColor = isempty
    ? toCSS(HUD.LABEL_EMPTY_FILL)
    : ismine
      ? toCSS(PLANET_COLORS.player_mine.color)
      : toCSS(PLANET_COLORS.player_other.color)

  const statusColor = isempty ? 'var(--color-text-subtle)' : ismine ? 'var(--color-quantum)' : 'var(--color-secondary)'
  const statusLabel = isempty ? 'Non colonisée' : ismine ? 'Colonisée — vous' : 'Colonisée'

  return (
    <div style={{ ...panelStyle, padding: '16px', overflowY: 'auto', display: 'flex', flexDirection: 'column', gap: '12px', color: 'var(--color-text)' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
        <div>
          <div style={{ fontFamily: 'Orbitron, sans-serif', fontSize: '13px', fontWeight: 700, color: nameColor, letterSpacing: '0.05em' }}>
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
          {hasQuantumPortal && planet.has_quantum_portal && sourcePlanetId
            ? (
              <a
                href={`/planets/${sourcePlanetId}/combats?target_planet_id=${planet.id}`}
                style={{
                  display: 'block', width: '100%', textAlign: 'center', padding: '8px 12px',
                  border: '1px solid var(--color-military)', borderRadius: '4px',
                  background: 'none', color: 'var(--color-military)', fontSize: '12px',
                  fontFamily: 'Courier New, monospace', textDecoration: 'none', letterSpacing: '0.05em',
                  boxSizing: 'border-box',
                }}
              >
                Attaquer
              </a>
            )
            : <DisabledButton label="Attaquer" />
          }
          <DisabledButton label="Envoyer une flotte" />
          <DisabledButton label="Espionner" />
        </>
      )}

      {isempty && (
        <>
          <div style={{ fontSize: '11px', color: 'var(--color-text-subtle)' }}>Planète non colonisée</div>
          {hasQuantumPortal && sourcePlanetId
            ? (
              <button
                onClick={() => onExplore(planet)}
                style={{
                  display: 'block', width: '100%', textAlign: 'center', padding: '8px 12px',
                  border: '1px solid var(--color-quantum)', borderRadius: '4px',
                  background: 'none', color: 'var(--color-quantum)', fontSize: '12px',
                  fontFamily: 'Courier New, monospace', cursor: 'pointer', letterSpacing: '0.05em',
                }}
              >
                Explorer
              </button>
            )
            : <DisabledButton label="Explorer" />
          }
        </>
      )}
    </div>
  )
}

// ── MapLegend ─────────────────────────────────────────────────────────────────

function MapLegend() {
  const items = [
    { color: '#E8E4D8', alpha: 0.5, label: 'Libre' },
    { color: '#4CAF7A', alpha: 1.0, label: 'Ma planète' },
    { color: '#7A9EC4', alpha: 1.0, label: 'Autre joueur' },
  ]
  return (
    <div style={{
      position: 'absolute', bottom: 12, right: 12, zIndex: 10,
      background: 'rgba(20,21,28,0.75)',
      border: '0.5px solid var(--color-border)',
      borderRadius: 8,
      padding: '8px 10px',
      display: 'flex', flexDirection: 'column', gap: 6,
      pointerEvents: 'none',
      backdropFilter: 'blur(4px)',
    }}>
      {items.map(({ color, alpha, label }) => (
        <div key={label} style={{ display: 'flex', alignItems: 'center', gap: 7 }}>
          <span style={{
            width: 8, height: 8, borderRadius: '50%', flexShrink: 0,
            background: color,
            opacity: alpha,
            boxShadow: alpha === 1.0 ? `0 0 4px ${color}88` : 'none',
          }} />
          <span style={{
            fontSize: 11, color: 'var(--color-text-muted)',
            fontFamily: 'Courier New, monospace', letterSpacing: '0.04em',
            userSelect: 'none',
          }}>
            {label}
          </span>
        </div>
      ))}
    </div>
  )
}

// ── GalaxyMap ─────────────────────────────────────────────────────────────────

export default function GalaxyMap({ sourcePlanetId = null, hasQuantumPortal = false }) {
  const isMobile          = useIsMobile()
  const containerRef      = useRef(null)
  const [explorationTarget, setExplorationTarget] = useState(null)
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

        <MapLegend />

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
          width={250}
          height={250}
          style={{
            position: 'absolute', bottom: 12, left: 12, zIndex: 10,
            border: '0.5px solid var(--color-border)', borderRadius: 8, opacity: 0.85,
            cursor: 'crosshair',
          }}
          onClick={e => {
            const mc = minimapCanvasRef.current
            if (!mc || !controlsRef.current?.centerOnWorld) return
            const rect = mc.getBoundingClientRect()
            const mx = e.clientX - rect.left
            const my = e.clientY - rect.top
            controlsRef.current.centerOnWorld(
              (mx / mc.width)  * WORLD_SIZE,
              (my / mc.height) * WORLD_SIZE,
            )
          }}
        />
      </div>

      <InfoPanel
        planet={selectedPlanet}
        currentUserId={currentUserId}
        isMobile={isMobile}
        onClose={() => setSelectedPlanet(null)}
        sourcePlanetId={sourcePlanetId}
        hasQuantumPortal={hasQuantumPortal}
        onExplore={setExplorationTarget}
      />

      {explorationTarget && (
        <ExplorationModal
          sourcePlanetId={sourcePlanetId}
          targetPlanet={explorationTarget}
          onClose={() => setExplorationTarget(null)}
        />
      )}
    </div>
  )
}
