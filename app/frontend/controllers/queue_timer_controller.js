import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display", "bar"]
  static values  = { completesAt: String, startedAt: String }

  initialize() {
    this.mode = "remaining" // "remaining" | "elapsed"
  }

  connect() {
    this.tick()
    this.interval = setInterval(() => this.tick(), 1000)
  }

  disconnect() { clearInterval(this.interval) }

  toggle() {
    this.mode = this.mode === "remaining" ? "elapsed" : "remaining"
    this.tick()
  }

  tick() {
    const now   = Date.now()
    const end   = new Date(this.completesAtValue).getTime()
    const start = new Date(this.startedAtValue).getTime()

    const remaining = Math.max(0, end - now)
    const elapsed   = Math.max(0, now - start)
    const total     = end - start

    if (this.mode === "remaining") {
      this.displayTarget.textContent = `-${this.formatDuration(remaining)}`
    } else {
      this.displayTarget.textContent = `${this.formatDuration(elapsed)} / ${this.formatDuration(total)}`
    }

    if (this.hasBarTarget) {
      const pct = total > 0 ? Math.min(100, (elapsed / total) * 100) : 0
      this.barTarget.style.width = `${pct}%`
    }

    if (remaining === 0) clearInterval(this.interval)
  }

  formatDuration(ms) {
    const t = Math.floor(ms / 1000)
    const d = Math.floor(t / 86400)
    const h = Math.floor((t % 86400) / 3600)
    const m = Math.floor((t % 3600) / 60)
    const s = t % 60
    const parts = []
    if (d > 0)              parts.push(`${d}j`)
    if (d > 0 || h > 0)    parts.push(`${h}h`)
    if (d > 0 || h > 0 || m > 0) parts.push(`${m}m`)
    parts.push(`${s}s`)
    return parts.join(" ")
  }
}
