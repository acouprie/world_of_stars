import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]

  toggle() {
    this.menuTarget.toggleAttribute("data-open")
  }

  closeOnOutside(event) {
    if (!this.element.contains(event.target)) {
      this.menuTarget.removeAttribute("data-open")
    }
  }
}
