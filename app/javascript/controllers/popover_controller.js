import { Controller } from "@hotwired/stimulus"

// Positions its floating box (the band-disambiguation callout) as a
// position:fixed element next to this controller's own element, rather than
// relying on plain CSS absolute positioning — the dashboard table wraps in
// an `overflow-x: auto` div, which would otherwise clip the box whenever it
// lands outside the table's current scroll bounds.
export default class extends Controller {
  static targets = ["box", "input"]

  connect() {
    this.reposition = this.reposition.bind(this)
    this.reposition()
    this.scrollParent = this.element.closest(".overflow-x-auto")
    window.addEventListener("resize", this.reposition)
    this.scrollParent?.addEventListener("scroll", this.reposition)
  }

  disconnect() {
    window.removeEventListener("resize", this.reposition)
    this.scrollParent?.removeEventListener("scroll", this.reposition)
  }

  reposition() {
    if (!this.hasBoxTarget) return
    // The box itself is already `position: fixed` (a static class in the
    // template, not set here) — it must be out of normal flow *before* this
    // measures the anchor, otherwise the anchor's own rect would include the
    // box's still-in-flow height and this would push the box down by its own
    // height on every reposition.
    const rect = this.element.getBoundingClientRect()
    this.boxTarget.style.top = `${rect.bottom + 8}px`
    this.boxTarget.style.left = `${rect.left}px`
  }

  close() {
    this.boxTarget?.remove()
  }

  // "None of these" — closes the box and clears the band name they typed,
  // since it clearly didn't match what they meant. The "✕" (close) leaves it
  // in place in case they just want to keep looking at their current text.
  clearAndClose() {
    if (this.hasInputTarget) this.inputTarget.value = ""
    this.close()
  }
}
