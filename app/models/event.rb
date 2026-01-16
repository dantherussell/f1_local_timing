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
    start_time.strftime("%H:%M")
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
