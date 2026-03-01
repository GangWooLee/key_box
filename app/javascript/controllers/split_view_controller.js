import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["list", "detail", "link"]
  static values = { selectedId: String }
  static classes = ["active"]

  connect() {
    this.mediaQuery = window.matchMedia("(min-width: 1024px)")
    this.boundHandleResize = this.handleResize.bind(this)
    this.mediaQuery.addEventListener("change", this.boundHandleResize)
    this.handleResize()
  }

  disconnect() {
    this.mediaQuery.removeEventListener("change", this.boundHandleResize)
  }

  handleResize() {
    const isDesktop = this.mediaQuery.matches
    this.linkTargets.forEach(link => {
      if (isDesktop) {
        link.setAttribute("data-turbo-frame", "secret_detail")
      } else {
        link.setAttribute("data-turbo-frame", "_top")
      }
    })
  }

  select(event) {
    const id = event.currentTarget.dataset.secretId
    this.selectedIdValue = id

    this.linkTargets.forEach(link => {
      const itemEl = link.closest("[data-secret-id]")
      if (itemEl) {
        const isSelected = itemEl.dataset.secretId === id
        if (this.hasActiveClass) {
          itemEl.classList.toggle(this.activeClasses[0], isSelected)
          this.activeClasses.slice(1).forEach(cls => itemEl.classList.toggle(cls, isSelected))
        }
      }
    })
  }
}
