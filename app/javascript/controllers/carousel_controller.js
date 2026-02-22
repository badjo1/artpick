import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["slide", "dot"]
  static values = { interval: { type: Number, default: 4000 } }

  connect() {
    this.currentIndex = 0
    this.showSlide(0)
    this.startAutoAdvance()
  }

  disconnect() {
    this.stopAutoAdvance()
  }

  next() {
    this.goTo((this.currentIndex + 1) % this.slideTargets.length)
  }

  previous() {
    this.goTo((this.currentIndex - 1 + this.slideTargets.length) % this.slideTargets.length)
  }

  goToSlide(event) {
    const index = parseInt(event.currentTarget.dataset.index)
    this.goTo(index)
  }

  goTo(index) {
    this.currentIndex = index
    this.showSlide(index)
    this.restartAutoAdvance()
  }

  showSlide(index) {
    this.slideTargets.forEach((slide, i) => {
      slide.classList.toggle("carousel-slide--active", i === index)
    })
    this.dotTargets.forEach((dot, i) => {
      dot.classList.toggle("carousel-dot--active", i === index)
    })
  }

  startAutoAdvance() {
    this.timer = setInterval(() => this.next(), this.intervalValue)
  }

  stopAutoAdvance() {
    if (this.timer) {
      clearInterval(this.timer)
      this.timer = null
    }
  }

  restartAutoAdvance() {
    this.stopAutoAdvance()
    this.startAutoAdvance()
  }

  pause() {
    this.stopAutoAdvance()
  }

  resume() {
    this.startAutoAdvance()
  }
}
