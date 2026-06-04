import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog", "title", "message", "form"]

  open({ params }) {
    if (this.hasTitleTarget)   this.titleTarget.textContent   = params.title   || ""
    if (this.hasMessageTarget) this.messageTarget.textContent = params.message || ""
    if (this.hasFormTarget)    this.formTarget.action         = params.url     || "#"
    this.dialogTarget.showModal()
  }

  cancel() {
    this.dialogTarget.close()
  }

  confirm() {
    this.formTarget.requestSubmit()
    this.dialogTarget.close()
  }

  clickOutside(event) {
    if (event.target === this.dialogTarget) {
      this.dialogTarget.close()
    }
  }
}
