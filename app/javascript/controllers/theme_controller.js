import { Controller } from "@hotwired/stimulus"

// Cycles light -> dark -> system -> light on click, persisting the choice to
// localStorage and toggling the `.dark` class on <html>. See the inline
// bootstrap script in application.html.erb for the pre-paint FOUC-prevention
// version of this same logic.
const STORAGE_KEY = "theme"
const MODES = ["light", "dark", "system"]

export default class extends Controller {
  static targets = ["lightIcon", "darkIcon", "systemIcon"]

  connect() {
    this.media = window.matchMedia("(prefers-color-scheme: dark)")
    this.onMediaChange = () => {
      if (this.currentMode() === "system") this.applyDark(this.media.matches)
    }
    this.media.addEventListener("change", this.onMediaChange)
    this.updateIcon()
  }

  disconnect() {
    this.media.removeEventListener("change", this.onMediaChange)
  }

  cycle() {
    const next = MODES[(MODES.indexOf(this.currentMode()) + 1) % MODES.length]
    localStorage.setItem(STORAGE_KEY, next)
    this.applyMode(next)
    this.updateIcon()
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

  updateIcon() {
    const mode = this.currentMode()
    this.lightIconTargets.forEach((el) => el.classList.toggle("hidden", mode !== "light"))
    this.darkIconTargets.forEach((el) => el.classList.toggle("hidden", mode !== "dark"))
    this.systemIconTargets.forEach((el) => el.classList.toggle("hidden", mode !== "system"))
  }
}
