module WeekendsHelper
  def event_row_classes(event, next_event)
    classes = []
    classes << "f1" if event.series_name == "Formula 1"
    classes << "past-event" if event.past?
    classes << "next-event" if next_event && event.id == next_event.id
    classes.join(" ")
  end
end
