class Event < ApplicationRecord
  before_save :convert_to_time

  belongs_to :day
  belongs_to :session
  delegate :weekend, :formatted_date, to: :day
  delegate :series, to: :session, allow_nil: true

  def time_offset
    return local_time_offset if local_time_offset.present?

    day.time_offset
  end

  def circuit_time
    return nil unless track_datetime.present?

    track_datetime.strftime("%H:%M")
  end

  def track_datetime
    return nil unless start_datetime.present?

    # Convert UTC datetime to track-local timezone
    offset = time_offset || "+00:00"
    start_datetime.new_offset(offset)
  end

  def track_date
    return nil unless track_datetime.present?

    track_datetime.to_date
  end

  def formatted_track_date
    track_date&.strftime("%A %-d %B")
  end

  def start_datetime
    return nil unless start_time.present? && day&.date.present?

    # start_time is stored as UTC, combine with day's date as UTC
    DateTime.new(
      day.date.year,
      day.date.month,
      day.date.day,
      start_time.hour,
      start_time.min,
      start_time.sec,
      "+00:00"
    )
  end

  def date
    formatted_date
  end

  def start_time_time_field
    start_time if start_time.present?
  end

  def start_time_time_field=(time)
    @start_time_time_field = Time.parse(time).strftime("%H:%M:%S")
  end

  def series_name
    series&.name || racing_class
  end

  def session_name
    session&.name || name
  end

  private

  def convert_to_time
    return unless @start_time_time_field

    self.start_time = Time.parse(@start_time_time_field)
  end
end
