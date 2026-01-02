class Event < ApplicationRecord
  before_save :convert_to_datetime

  belongs_to :weekend
  belongs_to :session
  delegate :series, to: :session, allow_nil: true

  def time_offset
    local_time_offset.blank? ? weekend.local_time_offset : local_time_offset
  end

  def circuit_time
    start_time.to_datetime.new_offset(time_offset).strftime("%H:%M")
  end

  def date
    start_time.to_datetime.new_offset(time_offset).strftime("%A %-d %B")
  end

  def start_time_date_field
    start_time.to_date if start_time.present?
  end

  def start_time_time_field
    start_time.to_time if start_time.present?
  end

  def start_time_date_field=(date)
    @start_time_date_field = Date.parse(date).strftime("%Y-%m-%d")
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

  def convert_to_datetime
    return unless @start_time_date_field && @start_time_time_field

    self.start_time = DateTime.parse("#{@start_time_date_field} #{@start_time_time_field}")
  end
end
