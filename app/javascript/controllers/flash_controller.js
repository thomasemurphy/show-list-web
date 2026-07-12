import { Controller } from "@hotwired/stimulus"

// Dismisses a flash message on click.
export default class extends Controller {
  dismiss() {
    this.element.remove()
  }
}
