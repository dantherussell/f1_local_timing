import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["frame", "preview", "form", "submitButton", "error"]
  static values = { printUrl: String }

  connect() {
    this.blob = null
    this.onMessage = this.onMessage.bind(this)
    window.addEventListener("message", this.onMessage)
    this.frameTarget.src = `${this.printUrlValue}?capture=1`
  }

  disconnect() {
    window.removeEventListener("message", this.onMessage)
  }

  async onMessage(event) {
    if (event.origin !== window.location.origin) return
    if (!event.data || event.data.type !== "schedule-capture") return

    const response = await fetch(event.data.dataUrl)
    this.blob = await response.blob()
    this.previewTarget.src = event.data.dataUrl
    this.submitButtonTarget.disabled = false
  }

  submit(event) {
    event.preventDefault()
    if (!this.blob || this.submitButtonTarget.disabled) return

    this.hideError()
    this.submitButtonTarget.disabled = true

    const formData = new FormData(this.formTarget)
    formData.set("image", this.blob, "schedule.png")

    fetch(this.formTarget.action, {
      method: "POST",
      body: formData,
      headers: { "Accept": "text/vnd.turbo-stream.html, text/html" }
    }).then(async (response) => {
      if (response.redirected) {
        window.location = response.url
        return
      }

      this.showError(await response.text())
      this.submitButtonTarget.disabled = false
    }).catch((error) => {
      this.showError(error.message)
      this.submitButtonTarget.disabled = false
    })
  }

  showError(message) {
    this.errorTarget.textContent = message
    this.errorTarget.hidden = false
  }

  hideError() {
    this.errorTarget.hidden = true
  }
}
