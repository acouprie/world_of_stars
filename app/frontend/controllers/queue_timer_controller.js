import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display", "bar"]
  static values  = { completesAt: String, startedAt: String }

  connect() {
    this.tick()
    this.interval = setInterval(() => this.tick(), 1000)
  }

  disconnect() { clearInterval(this.interval) }

  tick() {
    const now   = Date.now()
    const end   = new Date(this.completesAtValue).getTime()
    const start = new Date(this.startedAtValue).getTime()

    const remaining = Math.max(0, end - now)
    const m = Math.floor(remaining / 60000)
    const s = Math.floor((remaining % 60000) / 1000)
    this.displayTarget.textContent =
      `${String(m).padStart(2, "0")}:${String(s).padStart(2, "0")}`

    if (this.hasBarTarget) {
      const total = end - start
      const pct   = total > 0 ? Math.min(100, ((now - start) / total) * 100) : 0
      this.barTarget.style.width = `${pct}%`
    }

    if (remaining === 0) clearInterval(this.interval)
  }
}
