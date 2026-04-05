import { Controller } from "@hotwired/stimulus"

// Sets the project list link href from localStorage.
// If no list exists yet, clicking creates one via POST.
export default class extends Controller {
  static values = { locale: String }

  connect() {
    const slug = localStorage.getItem("projectListSlug")
    const link = this.element.querySelector("a")

    if (slug) {
      link.href = `/${this.localeValue}/projects/${slug}`
    } else {
      link.addEventListener("click", (e) => this.createAndNavigate(e))
    }
  }

  async createAndNavigate(e) {
    e.preventDefault()
    const csrfToken = document.querySelector("meta[name='csrf-token']")?.content

    const response = await fetch(`/${this.localeValue}/projects.json`, {
      method: "POST",
      headers: { "Content-Type": "application/json", "X-CSRF-Token": csrfToken },
      body: JSON.stringify({})
    })

    if (response.ok) {
      const data = await response.json()
      localStorage.setItem("projectListSlug", data.slug)
      window.location.href = `/${this.localeValue}/projects/${data.slug}`
    }
  }
}
