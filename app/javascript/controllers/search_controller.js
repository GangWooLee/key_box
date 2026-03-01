import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "input"]
  static values = { debounce: { type: Number, default: 300 } }

  connect() {
    this.#timeout = null
  }

  disconnect() {
    if (this.#timeout) clearTimeout(this.#timeout)
  }

  submit() {
    if (this.#timeout) clearTimeout(this.#timeout)

    this.#timeout = setTimeout(() => {
      if (this.hasFormTarget) {
        this.formTarget.requestSubmit()
      }
    }, this.debounceValue)
  }

  #timeout = null
}
