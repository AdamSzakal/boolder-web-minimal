import { Controller } from "@hotwired/stimulus"

// Renders an "Add to project list" button on problem pages.
// Uses fetch to add the problem without navigating away, then shows a ✓ confirmation.
export default class extends Controller {
  static values = { problemId: Number, locale: String }

  connect() {
    this.renderButton()
  }

  renderButton() {
    const button = document.createElement("button")
    button.type = "button"
    button.className = "flex items-center space-x-2 text-emerald-600 mt-2"
    button.innerHTML = `
      <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
      </svg>
      <span>${this.element.dataset.addLabel}</span>
    `
    button.addEventListener("click", () => this.addProblem(button))
    this.element.appendChild(button)
  }

  async addProblem(button) {
    button.disabled = true
    const csrfToken = document.querySelector("meta[name='csrf-token']")?.content
    const slug = localStorage.getItem("projectListSlug")

    try {
      let resultSlug

      if (slug) {
        // Add to existing list
        const response = await fetch(`/${this.localeValue}/projects/${slug}.json`, {
          method: "PATCH",
          headers: { "Content-Type": "application/json", "X-CSRF-Token": csrfToken },
          body: JSON.stringify({ add_problem_id: this.problemIdValue })
        })
        if (!response.ok) throw new Error("Failed to add")
        const data = await response.json()
        resultSlug = data.slug
      } else {
        // Create a new list with this problem
        const response = await fetch(`/${this.localeValue}/projects.json`, {
          method: "POST",
          headers: { "Content-Type": "application/json", "X-CSRF-Token": csrfToken },
          body: JSON.stringify({ problem_id: this.problemIdValue })
        })
        if (!response.ok) throw new Error("Failed to create")
        const data = await response.json()
        resultSlug = data.slug
        localStorage.setItem("projectListSlug", resultSlug)
      }

      // Show confirmation
      button.className = "flex items-center space-x-2 text-emerald-600 mt-2"
      button.innerHTML = `
        <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
        </svg>
        <span>${this.element.dataset.addedLabel}</span>
      `
    } catch (_error) {
      button.disabled = false
    }
  }
}
