import { Controller } from "@hotwired/stimulus"
import TomSelect from "tom-select"

export default class extends Controller {
  static targets = ["series", "session"]
  static values = { selectedSession: Number }

  connect() {
    this.seriesSelect = new TomSelect(this.seriesTarget, {
      allowEmptyOption: true,
      onChange: (value) => this.loadSessions(value, null)
    })

    this.sessionSelect = new TomSelect(this.sessionTarget, {
      allowEmptyOption: true
    })

    if (this.seriesTarget.value) {
      this.loadSessions(this.seriesTarget.value, this.selectedSessionValue)
    }
  }

  disconnect() {
    if (this.seriesSelect) this.seriesSelect.destroy()
    if (this.sessionSelect) this.sessionSelect.destroy()
  }

  async loadSessions(seriesId, selectedId) {
    this.sessionSelect.clear()
    this.sessionSelect.clearOptions()
    this.sessionSelect.addOption({ value: "", text: "Select a session..." })

    if (!seriesId) return

    const response = await fetch(`/series/${seriesId}/sessions`)
    const sessions = await response.json()

    sessions.forEach(session => {
      this.sessionSelect.addOption({ value: session.id, text: session.name })
    })

    if (selectedId) {
      this.sessionSelect.setValue(selectedId)
    }
  }
}
