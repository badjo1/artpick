import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['winnerInput', 'loserInput', 'form']

  selectWinner(event) {
    const winnerId = event.currentTarget.dataset.winnerId
    const loserId = event.currentTarget.dataset.loserId

    this.winnerInputTarget.value = winnerId
    this.loserInputTarget.value = loserId
    this.formTarget.submit()
  }
}
