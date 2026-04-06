import { Controller } from "@hotwired/stimulus"
import { loadProjectList } from "../lib/project_list_storage"

// Hydrates the project list page from localStorage.
// Dispatches a "projectlist:loaded" event with the list data.
export default class extends Controller {
  static values = { locale: String }

  connect() {
    const list = loadProjectList()
    this.dispatch("loaded", { detail: list })
  }
}
