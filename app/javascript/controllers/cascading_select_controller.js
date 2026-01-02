import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["series", "session"]
  static values = { selectedSession: Number }

  connect() {
    if (this.seriesTarget.value) {
      this.loadSessions(this.seriesTarget.value, this.selectedSessionValue)
    }
  }

  seriesChanged() {
    this.loadSessions(this.seriesTarget.value, null)
  }

  async loadSessions(seriesId, selectedId) {
    this.sessionTarget.innerHTML = '<option value="">Select a session...</option>'

    if (!seriesId) return

    const response = await fetch(`/series/${seriesId}/sessions`)
    const sessions = await response.json()

    sessions.forEach(session => {
      const option = document.createElement("option")
      option.value = session.id
      option.textContent = session.name
      if (session.id === selectedId) option.selected = true
      this.sessionTarget.appendChild(option)
    })
  }
}
