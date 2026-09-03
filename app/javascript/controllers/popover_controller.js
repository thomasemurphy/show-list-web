import { Controller } from "@hotwired/stimulus"

// Positions its floating box (the band-disambiguation callout) as a
// position:fixed element next to this controller's own element, rather than
// relying on plain CSS absolute positioning — the dashboard table wraps in
// an `overflow-x: auto` div, which would otherwise clip the box whenever it
// lands outside the table's current scroll bounds.
export default class extends Controller {
  static targets = ["box", "input"]

  // Gap between the box and its anchor, and the smallest gap it will leave
  // against the edge of the viewport.
  static MARGIN = 8

  connect() {
    this.reposition = this.reposition.bind(this)
    this.reposition()
    window.addEventListener("resize", this.reposition)
    // Capture phase, so this also catches scrolling inside the table's
    // overflow-x container — a fixed box doesn't move with either, so it has
    // to be re-anchored by hand on both.
    window.addEventListener("scroll", this.reposition, true)
  }

  disconnect() {
    window.removeEventListener("resize", this.reposition)
    window.removeEventListener("scroll", this.reposition, true)
  }

  reposition() {
    if (!this.hasBoxTarget) return
    // The box itself is already `position: fixed` (a static class in the
    // template, not set here) — it must be out of normal flow *before* this
    // measures the anchor, otherwise the anchor's own rect would include the
    // box's still-in-flow height and this would push the box down by its own
    // height on every reposition.
    const anchor = this.element.getBoundingClientRect()
    const box = this.boxTarget.getBoundingClientRect()
    const margin = this.constructor.MARGIN

    // Below the anchor by preference, above it when that would run off the
    // bottom of the window. The Add band control is the last row of the
    // dashboard table, so it's usually near the bottom of the page and the
    // box — which can list four acts with a description each — usually
    // doesn't fit under it. A fixed box can't be scrolled to, so this is the
    // difference between seeing the choices and not.
    const fitsBelow = anchor.bottom + margin + box.height <= window.innerHeight
    const fitsAbove = anchor.top - margin - box.height >= 0
    let top
    if (fitsBelow) {
      top = anchor.bottom + margin
    } else if (fitsAbove) {
      top = anchor.top - margin - box.height
    } else {
      // Taller than the window has room for either way (a short window, or a
      // zoomed-in phone): sit as low as it can while staying fully visible.
      top = Math.max(margin, window.innerHeight - margin - box.height)
    }

    // Left-aligned with the anchor, nudged back inside if that would hang the
    // box off either edge — the anchor can sit at the far right of a wide,
    // horizontally scrolled table.
    const left = Math.min(
      Math.max(margin, anchor.left),
      Math.max(margin, window.innerWidth - margin - box.width)
    )

    this.boxTarget.style.top = `${top}px`
    this.boxTarget.style.left = `${left}px`
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
