import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['container', 'title', 'body', 'form']
  static values = {
    title: String,
    body: String,
    url: String,
    method: String
  }

  open(event) {
    // If opened from a trigger button, get data attributes
    if (event && event.currentTarget) {
      const trigger = event.currentTarget
      const title = trigger.dataset.modalTitle || 'Confirm Deletion'
      const body = trigger.dataset.modalBody || 'Are you sure you want to delete this item?'
      const url = trigger.dataset.modalUrl

      // Update modal content
      if (this.hasTitleTarget) {
        this.titleTarget.textContent = title
      }
      if (this.hasBodyTarget) {
        this.bodyTarget.innerHTML = body
      }

      // Update form action URL
      if (this.hasFormTarget && url) {
        this.formTarget.action = url
      }
    }

    this.containerTarget.classList.remove('hidden')
    document.body.style.overflow = 'hidden'
  }

  close(event) {
    // Prevent closing if clicking inside the modal content
    if (event && event.target.closest('.modal-content') && !event.target.closest('[data-action*="modal#close"]')) {
      return
    }

    this.containerTarget.classList.add('hidden')
    document.body.style.overflow = 'auto'
  }

  // Close modal on ESC key
  handleKeyup(event) {
    if (event.key === 'Escape') {
      this.close()
    }
  }

  connect() {
    // Listen for ESC key globally when modal controller is connected
    this.handleKeyupBound = this.handleKeyup.bind(this)
    document.addEventListener('keyup', this.handleKeyupBound)
  }

  disconnect() {
    // Clean up event listener when controller is disconnected
    document.removeEventListener('keyup', this.handleKeyupBound)
    document.body.style.overflow = 'auto'
  }
}
