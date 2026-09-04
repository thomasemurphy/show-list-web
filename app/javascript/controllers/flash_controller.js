import { Controller } from "@hotwired/stimulus"

// Dismisses a flash message on click, or on its own after
// data-flash-dismiss-after-value milliseconds (0, the default, waits for the
// click). Anything the reader needs to act on should wait for the click.
export default class extends Controller {
  static values = { dismissAfter: Number }

  connect() {
    if (this.dismissAfterValue > 0) {
      this.timeout = setTimeout(() => this.dismiss(), this.dismissAfterValue)
    }
  }

  disconnect() {
    clearTimeout(this.timeout)
  }

  dismiss() {
    this.element.remove()
  }
}
