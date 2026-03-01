import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "revealed", "input", "eyeOpen", "eyeClosed"]
  static values = { visible: { type: Boolean, default: false } }

  toggle() {
    this.visibleValue = !this.visibleValue
  }

  visibleValueChanged() {
    if (this.hasContentTarget && this.hasRevealedTarget) {
      this.contentTarget.classList.toggle("hidden", this.visibleValue)
      this.revealedTarget.classList.toggle("hidden", !this.visibleValue)
    }

    if (this.hasInputTarget) {
      this.inputTarget.type = this.visibleValue ? "text" : "password"
    }

    if (this.hasEyeOpenTarget && this.hasEyeClosedTarget) {
      this.eyeOpenTarget.classList.toggle("hidden", this.visibleValue)
      this.eyeClosedTarget.classList.toggle("hidden", !this.visibleValue)
    }
  }
}
