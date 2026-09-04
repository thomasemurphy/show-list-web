import { Controller } from "@hotwired/stimulus"

// Positions its floating box (the band-disambiguation callout) as a
// position:fixed element next to this controller's own element, rather than
// relying on plain CSS absolute positioning — the dashboard table wraps in
// an `overflow-x: auto` div, which would otherwise clip the box whenever it
// lands outside the table's current scroll bounds.
export default class extends Controller {
  static targets = ["box", "input"]

  // "below" (the default) hangs the box under the anchor, flipping above it
  // when there's no room. "right" puts it beside the anchor instead, which is
  // what the short add-a-band outcome message wants: the Add band control is
  // the last row of the table, so anything stacked above it covers the band
  // the user was just looking at, and anything below it runs off the page.
  // Falls back to "below" when the window is too narrow to sit beside it.
  static values = { placement: { type: String, default: "below" } }

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

    let top, left
    if (this.placementValue === "right" &&
        anchor.right + margin + box.width + margin <= window.innerWidth) {
      // Beside the anchor, centered on it.
      top = anchor.top + anchor.height / 2 - box.height / 2
      left = anchor.right + margin
    } else {
      // Below the anchor by preference, above it when that would run off the
      // bottom of the window. The box — which can list four acts with a
      // description each — often doesn't fit under a control this close to
      // the bottom of the page, and a fixed box can't be scrolled to, so the
      // flip is the difference between seeing the choices and not.
      const fitsBelow = anchor.bottom + margin + box.height <= window.innerHeight
      top = fitsBelow ? anchor.bottom + margin : anchor.top - margin - box.height
      left = anchor.left
    }

    // However it was placed, keep it on screen — the box is worth seeing even
    // when its anchor isn't, which happens when the box is taller than the
    // window has room for, when a redirect lands the page back at the top
    // with the Add band control scrolled off the bottom, or when the anchor
    // sits at the far right of a wide, horizontally scrolled table.
    this.boxTarget.style.top = `${clamp(top, margin, window.innerHeight - margin - box.height)}px`
    this.boxTarget.style.left = `${clamp(left, margin, window.innerWidth - margin - box.width)}px`
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

// Keeps value within [min, max], preferring min when the two cross — i.e.
// when the box is bigger than the space it has to fit in.
function clamp(value, min, max) {
  return Math.max(min, Math.min(value, max))
}
