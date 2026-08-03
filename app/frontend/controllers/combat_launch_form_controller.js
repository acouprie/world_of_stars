import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "submit"]

  connect() {
    this.recompute()
  }

  recompute() {
    const total = this.inputTargets.reduce((sum, input) => sum + (parseInt(input.value, 10) || 0), 0)
    this.submitTarget.disabled = total <= 0
  }
}
