import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['count', 'submitBtn', 'checkbox']

  connect() {
    this.updateSelectionCount()
  }

  updateSelectionCount() {
    const checkedBoxes = this.checkboxTargets.filter(cb => cb.checked)
    const count = checkedBoxes.length

    // Update counter
    this.countTarget.textContent = count

    // Enable/disable submit button
    if (count === 5) {
      this.submitBtnTarget.disabled = false
      this.submitBtnTarget.style.opacity = '1'
    } else {
      this.submitBtnTarget.disabled = true
      this.submitBtnTarget.style.opacity = '0.5'
    }

    // Disable unchecked boxes if 5 are selected
    this.checkboxTargets.forEach(checkbox => {
      const card = checkbox.closest('.artwork-card')

      if (!checkbox.checked && count >= 5) {
        checkbox.disabled = true
        card.style.opacity = '0.3'
        card.style.cursor = 'not-allowed'
      } else {
        checkbox.disabled = false
        card.style.opacity = '1'
        card.style.cursor = 'pointer'
      }
    })
  }
}
