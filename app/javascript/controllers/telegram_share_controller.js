import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["frame", "preview", "form", "submitButton"]
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
    if (!this.blob) return

    const formData = new FormData(this.formTarget)
    formData.set("image", this.blob, "schedule.png")

    fetch(this.formTarget.action, {
      method: "POST",
      body: formData,
      headers: { "Accept": "text/vnd.turbo-stream.html, text/html" }
    }).then((response) => {
      if (response.redirected) {
        window.location = response.url
      }
    })
  }
}
