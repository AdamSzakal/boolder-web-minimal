import { Controller } from "@hotwired/stimulus"

// Stores the current project list slug in localStorage so the "Add to project list"
// button on problem pages knows which list to add to.
export default class extends Controller {
  static values = { slug: String, addUrl: String, locale: String }

  connect() {
    localStorage.setItem("projectListSlug", this.slugValue)
  }
}
