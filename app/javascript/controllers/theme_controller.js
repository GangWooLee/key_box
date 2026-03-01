import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["lightIcon", "darkIcon"]

  connect() {
    this.updateIcons(document.documentElement.getAttribute("data-theme"))
  }

  toggle() {
    const current = document.documentElement.getAttribute("data-theme")
    const next = current === "dark" ? "light" : "dark"
    document.documentElement.setAttribute("data-theme", next)
    localStorage.setItem("theme", next)
    this.updateIcons(next)
  }

  updateIcons(theme) {
    if (this.hasLightIconTarget && this.hasDarkIconTarget) {
      this.lightIconTarget.classList.toggle("hidden", theme !== "dark")
      this.darkIconTarget.classList.toggle("hidden", theme === "dark")
    }
  }
}
