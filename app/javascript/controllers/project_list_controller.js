import { Controller } from "@hotwired/stimulus"
import { loadProjectList } from "../lib/project_list_storage"

// Hydrates the project list page from localStorage.
// Project lists are device-local only in the static architecture.
// Sharing or syncing lists is out of scope for this migration.
export default class extends Controller {
  static values = { locale: String }

  connect() {
    const list = loadProjectList()
    this.render(list)
  }

  render(list) {
    if (!list.problemIds.length) {
      this.element.innerHTML = `<p class="text-gray-400">No problems in your project list yet.</p>`
      return
    }

    // Emit a custom event so the page can render the problem cards
    const event = new CustomEvent("projectlist:loaded", {
      detail: { problemIds: list.problemIds }
    })
    window.dispatchEvent(event)
  }
}
