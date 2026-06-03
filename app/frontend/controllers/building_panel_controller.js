import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { planetId: Number }

  connect() {
    this.slotHandler     = this.onSlotOpen.bind(this)
    this.buildingHandler = this.onBuildingSelect.bind(this)
    this.frameHandler    = this.open.bind(this)
    this.outsideHandler  = this.onOutsideClick.bind(this)

    document.addEventListener("planet:slot-open",       this.slotHandler)
    document.addEventListener("planet:building-select", this.buildingHandler)
    document.addEventListener("click",                  this.outsideHandler)
    this.frame?.addEventListener("turbo:frame-load",    this.frameHandler)
  }

  disconnect() {
    document.removeEventListener("planet:slot-open",       this.slotHandler)
    document.removeEventListener("planet:building-select", this.buildingHandler)
    document.removeEventListener("click",                  this.outsideHandler)
    this.frame?.removeEventListener("turbo:frame-load",    this.frameHandler)
  }

  get frame() {
    return document.getElementById("building-panel")
  }

  onSlotOpen({ detail: { slot_index } }) {
    if (!this.frame) return
    this.frame.src = `/planets/${this.planetIdValue}/buildings/new?slot_index=${slot_index}`
  }

  onBuildingSelect({ detail: { building_id } }) {
    if (!this.frame) return
    this.frame.src = `/planets/${this.planetIdValue}/buildings/${building_id}`
  }

  open() {
    if (!this.frame?.children.length) {
      this.close()
      return
    }
    this.element.setAttribute("data-open", "")
  }

  onOutsideClick(event) {
    if (!this.element.hasAttribute("data-open")) return
    if (!this.element.contains(event.target)) this.close()
  }

  close() {
    this.element.removeAttribute("data-open")
    if (this.frame) {
      this.frame.innerHTML = ""
      this.frame.removeAttribute("src")
    }
    document.dispatchEvent(new CustomEvent("planet:panel-closed", { bubbles: true }))
  }
}
