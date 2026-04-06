import { Controller } from "@hotwired/stimulus"
import { addProblem, hasProblem } from "../lib/project_list_storage"

// Renders an "Add to project list" button on problem pages.
// Stores the problem in localStorage without any server request.
export default class extends Controller {
  static values = { problemId: Number, locale: String }

  connect() {
    this.renderButton()
  }

  renderButton() {
    if (hasProblem(this.problemIdValue)) {
      this.renderConfirmation()
      return
    }

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

  addProblem(button) {
    addProblem(this.problemIdValue)
    this.renderConfirmation()
  }

  renderConfirmation() {
    this.element.innerHTML = `
      <div class="flex items-center space-x-2 text-emerald-600 mt-2">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
        </svg>
        <span>${this.element.dataset.addedLabel}</span>
      </div>
    `
  }
}
