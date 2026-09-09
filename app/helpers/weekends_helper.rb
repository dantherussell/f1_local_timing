module WeekendsHelper
  def event_row_classes(event, next_event)
    classes = []
    classes << "f1" if event.series_name == "Formula 1"
    classes << "past-event" if event.past?
    classes << "next-event" if next_event && event.id == next_event.id
    classes.join(" ")
  end

  def formatted_utc_offset(offset)
    match = offset&.match(/\A([+-])(\d{2}):(\d{2})\z/)
    return offset unless match

    sign, hours, minutes = match.captures
    formatted = "UTC#{sign}#{hours.to_i}"
    formatted += ":#{minutes}" unless minutes == "00"
    formatted
  end
end
