import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }

  toggle(event) {
    fetch(this.urlValue, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
        Accept: "application/json",
      },
      body: JSON.stringify({ enabled: event.target.checked }),
    })
  }
}
