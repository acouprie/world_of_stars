import { useState, useEffect } from 'react'

export function usePlanets() {
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
