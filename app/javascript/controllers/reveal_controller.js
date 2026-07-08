import { Controller } from "@hotwired/stimulus"

// Swaps a button for a form (e.g. "Add a band" -> text field + submit) on click.
export default class extends Controller {
  static targets = ["button", "form", "input"]

  show() {
    this.buttonTarget.classList.add("hidden")
    this.formTarget.classList.remove("hidden")
    this.inputTarget.focus()
  }
}
