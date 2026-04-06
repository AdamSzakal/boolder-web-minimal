import { Controller } from "@hotwired/stimulus"
import { addProblem, hasProblem } from "../lib/project_list_storage"

// Renders an "Add to project list" button on problem pages.
// Stores problems in localStorage — no server calls.
export default class extends Controller {
  static values = { problemId: Number, locale: String }

  connect() {
    if (hasProblem(this.problemIdValue)) {
      this.renderConfirmation()
    } else {
      this.renderButton()
    }
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
    button.addEventListener("click", () => {
      addProblem(this.problemIdValue)
      this.element.innerHTML = ""
      this.renderConfirmation()
    })
    this.element.appendChild(button)
  }

  renderConfirmation() {
    const el = document.createElement("div")
    el.className = "flex items-center space-x-2 text-emerald-600 mt-2"
    el.innerHTML = `
      <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
      </svg>
      <span>${this.element.dataset.addedLabel}</span>
    `
    this.element.appendChild(el)
  }
}
