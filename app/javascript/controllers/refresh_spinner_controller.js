import { Controller } from "@hotwired/stimulus"

// Spins the refresh icon for at least MIN_DURATION_MS, even if the frame's
// fetch resolves faster than that (busy-attribute-driven CSS alone wouldn't
// render a visible spin for near-instant responses).
const MIN_DURATION_MS = 400

export default class extends Controller {
  start() {
    this.startedAt = performance.now()
    this.element.classList.add("is-refreshing")
  }

  finish() {
    const remaining = MIN_DURATION_MS - (performance.now() - this.startedAt)
    if (remaining > 0) {
      setTimeout(() => this.element.classList.remove("is-refreshing"), remaining)
    } else {
      this.element.classList.remove("is-refreshing")
    }
  }
}
