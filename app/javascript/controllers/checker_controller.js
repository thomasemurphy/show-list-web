import { Controller } from "@hotwired/stimulus"

// Walks the dashboard's not-yet-checked cells (see shows/_cell.html.erb) one
// at a time in DOM order, instead of firing every SeatGeek lookup at once.
// For a newly added zip, that order is band-by-band down the new column,
// since every other cell is already checked and never joins the queue.
export default class extends Controller {
  static targets = ["cell"]

  connect() {
    // Snapshot now: each loaded cell drops its checker-target attribute,
    // which would otherwise shift live target indices mid-walk.
    this.cells = [...this.cellTargets]
    this.checkNext(0)
  }

  checkNext(index) {
    const frame = this.cells[index]
    if (!frame) return

    // Reuses refresh-spinner's start/finish (and its MIN_DURATION_MS) so an
    // automatic check spins the same wheel a manual refresh does.
    this.application.getControllerForElementAndIdentifier(frame, "refresh-spinner")?.start()

    const advance = () => this.checkNext(index + 1)
    frame.addEventListener("turbo:frame-load", advance, { once: true })
    frame.addEventListener("turbo:fetch-request-error", advance, { once: true })
    frame.src = frame.dataset.checkerUrl
  }
}
