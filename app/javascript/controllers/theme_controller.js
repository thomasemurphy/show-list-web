import { Controller } from "@hotwired/stimulus"

// Cycles light -> dark -> system -> light on click, persisting the choice to
// localStorage and toggling the `.dark` class on <html>. See the inline
// bootstrap script in application.html.erb for the pre-paint FOUC-prevention
// version of this same logic.
const STORAGE_KEY = "theme"
const MODES = ["light", "dark", "system"]
const LABELS = { light: "Light", dark: "Dark", system: "System" }

export default class extends Controller {
  static targets = ["label"]

  connect() {
    this.media = window.matchMedia("(prefers-color-scheme: dark)")
    this.onMediaChange = () => {
      if (this.currentMode() === "system") this.applyDark(this.media.matches)
    }
    this.media.addEventListener("change", this.onMediaChange)
    this.updateLabel()
  }

  disconnect() {
    this.media.removeEventListener("change", this.onMediaChange)
  }

  cycle() {
    const next = MODES[(MODES.indexOf(this.currentMode()) + 1) % MODES.length]
    localStorage.setItem(STORAGE_KEY, next)
    this.applyMode(next)
    this.updateLabel()
  }

  currentMode() {
    return localStorage.getItem(STORAGE_KEY) || "system"
  }

  applyMode(mode) {
    const isDark = mode === "dark" || (mode === "system" && this.media.matches)
    this.applyDark(isDark)
  }

  applyDark(isDark) {
    document.documentElement.classList.toggle("dark", isDark)
  }

  updateLabel() {
    if (this.hasLabelTarget) this.labelTarget.textContent = LABELS[this.currentMode()]
  }
}
