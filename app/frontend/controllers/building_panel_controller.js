import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { planetId: Number }

  connect() {
    this.handler = this.onSlotOpen.bind(this)
    document.addEventListener("planet:slot-open", this.handler)
  }

  disconnect() {
    document.removeEventListener("planet:slot-open", this.handler)
  }

  onSlotOpen({ detail: { slot_index } }) {
    const frame = document.getElementById("building-panel")
    if (!frame) return
    frame.src = `/planets/${this.planetIdValue}/buildings/new?slot_index=${slot_index}`
  }
}
