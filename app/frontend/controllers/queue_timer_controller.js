import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display"]
  static values  = { completesAt: String }

  connect() {
    this.tick()
    this.interval = setInterval(() => this.tick(), 1000)
  }

  disconnect() { clearInterval(this.interval) }

  tick() {
    const diff = Math.max(0, new Date(this.completesAtValue) - Date.now())
    const m = Math.floor(diff / 60000)
    const s = Math.floor((diff % 60000) / 1000)
    this.displayTarget.textContent =
      `${String(m).padStart(2, "0")}:${String(s).padStart(2, "0")}`
    if (diff === 0) clearInterval(this.interval)
  }
}
