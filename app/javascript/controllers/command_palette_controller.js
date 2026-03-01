import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["overlay", "input", "results", "item"]
  static values = { open: Boolean }

  connect() {
    this.boundKeydown = this.handleKeydown.bind(this)
    document.addEventListener("keydown", this.boundKeydown)
    this.selectedIndex = -1
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundKeydown)
  }

  handleKeydown(event) {
    // Cmd+K (Mac) / Ctrl+K (Windows)
    if ((event.metaKey || event.ctrlKey) && event.key === "k") {
      event.preventDefault()
      this.toggle()
      return
    }

    if (!this.openValue) return

    if (event.key === "Escape") {
      event.preventDefault()
      this.close()
    } else if (event.key === "ArrowDown") {
      event.preventDefault()
      this.moveSelection(1)
    } else if (event.key === "ArrowUp") {
      event.preventDefault()
      this.moveSelection(-1)
    } else if (event.key === "Enter") {
      event.preventDefault()
      this.selectCurrent()
    }
  }

  toggle() {
    if (this.openValue) {
      this.close()
    } else {
      this.open()
    }
  }

  open() {
    this.openValue = true
    this.overlayTarget.classList.remove("hidden")
    this.inputTarget.value = ""
    this.inputTarget.focus()
    this.selectedIndex = -1
    this.search()
  }

  close() {
    this.openValue = false
    this.overlayTarget.classList.add("hidden")
    this.inputTarget.value = ""
  }

  closeBackground(event) {
    if (event.target === this.overlayTarget) {
      this.close()
    }
  }

  search() {
    clearTimeout(this.debounceTimer)
    this.debounceTimer = setTimeout(() => {
      this.filterResults()
    }, 150)
  }

  filterResults() {
    const query = this.inputTarget.value.toLowerCase().trim()
    let visibleCount = 0

    this.itemTargets.forEach(item => {
      const name = (item.dataset.name || "").toLowerCase()
      const service = (item.dataset.service || "").toLowerCase()
      const tags = (item.dataset.tags || "").toLowerCase()
      const matches = !query || name.includes(query) || service.includes(query) || tags.includes(query)

      item.classList.toggle("hidden", !matches)
      if (matches) visibleCount++
    })

    this.selectedIndex = visibleCount > 0 ? 0 : -1
    this.updateSelectionHighlight()
  }

  moveSelection(direction) {
    const visibleItems = this.itemTargets.filter(item => !item.classList.contains("hidden"))
    if (visibleItems.length === 0) return

    this.selectedIndex = Math.max(0, Math.min(this.selectedIndex + direction, visibleItems.length - 1))
    this.updateSelectionHighlight()
    visibleItems[this.selectedIndex]?.scrollIntoView({ block: "nearest" })
  }

  updateSelectionHighlight() {
    const visibleItems = this.itemTargets.filter(item => !item.classList.contains("hidden"))
    visibleItems.forEach((item, index) => {
      item.classList.toggle("bg-brand-50", index === this.selectedIndex)
      item.classList.toggle("dark:bg-brand-950", index === this.selectedIndex)
    })
  }

  selectCurrent() {
    const visibleItems = this.itemTargets.filter(item => !item.classList.contains("hidden"))
    const selected = visibleItems[this.selectedIndex]
    if (selected) {
      const link = selected.querySelector("a")
      if (link) {
        this.close()
        link.click()
      }
    }
  }

  selectResult(event) {
    this.close()
  }
}
