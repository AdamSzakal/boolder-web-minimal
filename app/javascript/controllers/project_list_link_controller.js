import { Controller } from "@hotwired/stimulus"
import { loadProjectList } from "../lib/project_list_storage"

// Sets the project list link href to the local projects page.
export default class extends Controller {
  static values = { locale: String }

  connect() {
    const link = this.element.querySelector("a")
    link.href = `/${this.localeValue}/projects`
  }
}
