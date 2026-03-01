import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "icon"]
  static values = { secretId: Number }

  async copy() {
    try {
      const response = await fetch(`/secrets/${this.secretIdValue}/copy`, {
        method: "POST",
        headers: {
          "X-CSRF-Token": this.#csrfToken,
          "Accept": "application/json"
        }
      })

      if (!response.ok) throw new Error("Copy failed")

      const data = await response.json()
      await navigator.clipboard.writeText(data.value)

      // Clear any existing clear timer
      if (this.clearTimer) clearTimeout(this.clearTimer)

      // Auto-clear clipboard after 30 seconds
      this.clearTimer = setTimeout(() => {
        navigator.clipboard.writeText("").catch(() => {})
      }, 30000)

      this.#showCopiedFeedback()
    } catch (error) {
      this.#showErrorFeedback()
    }
  }

  disconnect() {
    if (this.clearTimer) {
      clearTimeout(this.clearTimer)
    }
  }

  #showCopiedFeedback() {
    if (!this.hasButtonTarget) return

    const original = this.buttonTarget.getAttribute("aria-label")
    this.buttonTarget.setAttribute("aria-label", "Copied!")
    this.buttonTarget.classList.add("text-green-600")

    setTimeout(() => {
      this.buttonTarget.setAttribute("aria-label", original)
      this.buttonTarget.classList.remove("text-green-600")
    }, 2000)
  }

  #showErrorFeedback() {
    if (!this.hasButtonTarget) return

    this.buttonTarget.setAttribute("aria-label", "Copy failed")
    this.buttonTarget.classList.add("text-red-600")

    setTimeout(() => {
      this.buttonTarget.setAttribute("aria-label", "Copy secret value")
      this.buttonTarget.classList.remove("text-red-600")
    }, 2000)
  }

  get #csrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content || ""
  }
}
