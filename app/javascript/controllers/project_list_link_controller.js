import { Controller } from "@hotwired/stimulus"

// Sets the project list link to the static projects page.
// Project lists are device-local only in the static architecture.
export default class extends Controller {
  static values = { locale: String }

  connect() {
    const link = this.element.querySelector("a")
    if (link) {
      link.href = "/en/projects"
    }
  }
}
