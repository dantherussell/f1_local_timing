import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["event"]

  connect() {
    this.groupEventsByLocalDate()
    this.applyTimeBasedStyling()
  }

  groupEventsByLocalDate() {
    const events = this.eventTargets
    if (events.length === 0) return

    // Group events by local date
    const groups = new Map()

    events.forEach(row => {
      const utcTime = row.dataset.utcTime
      if (!utcTime) return

      const date = new Date(utcTime)
      const localDateKey = date.toLocaleDateString('en-CA') // YYYY-MM-DD format
      const localDateFormatted = date.toLocaleDateString('en-GB', {
        weekday: 'long',
        day: 'numeric',
        month: 'long'
      })

      if (!groups.has(localDateKey)) {
        groups.set(localDateKey, { formatted: localDateFormatted, rows: [] })
      }
      groups.get(localDateKey).rows.push(row)
    })

    // Sort groups by date
    const sortedGroups = Array.from(groups.entries()).sort((a, b) => a[0].localeCompare(b[0]))

    // Get the table body
    const tbody = this.element.querySelector('tbody')
    if (!tbody) return

    // Clear and rebuild with headers
    tbody.innerHTML = ''

    sortedGroups.forEach(([dateKey, group]) => {
      // Insert day header row
      const headerRow = document.createElement('tr')
      headerRow.className = 'day-header'
      const headerCell = document.createElement('td')
      headerCell.colSpan = 3
      headerCell.innerHTML = `<h4>${group.formatted}</h4>`
      headerRow.appendChild(headerCell)
      tbody.appendChild(headerRow)

      // Insert event rows sorted by time
      group.rows.sort((a, b) => {
        return new Date(a.dataset.utcTime) - new Date(b.dataset.utcTime)
      })

      group.rows.forEach(row => {
        tbody.appendChild(row)
      })
    })
  }

  applyTimeBasedStyling() {
    const now = new Date()
    const events = Array.from(this.element.querySelectorAll('tr[data-utc-time]'))
      .sort((a, b) => new Date(a.dataset.utcTime) - new Date(b.dataset.utcTime))

    let nextFound = false
    events.forEach(row => {
      const eventTime = new Date(row.dataset.utcTime)
      if (eventTime < now) {
        row.classList.add('past-event')
      } else if (!nextFound) {
        row.classList.add('next-event')
        nextFound = true
      }
    })
  }
}
