# frozen_string_literal: true

class F1ScheduleImporter
  def initialize(weekend, schedule_data)
    @weekend = weekend
    @schedule_data = schedule_data
  end

  def call
    ActiveRecord::Base.transaction do
      delete_existing_events
      update_weekend_timezone
      import_events
    end

    Result.success(events_created: @events_created)
  rescue ActiveRecord::RecordInvalid => e
    Result.failure("Failed to import: #{e.message}")
  rescue StandardError => e
    Result.failure("Import error: #{e.message}")
  end

  private

  def delete_existing_events
    @weekend.days.each { |day| day.events.destroy_all }
  end

  def update_weekend_timezone
    return unless @schedule_data[:timezone_offset].present?

    @weekend.update!(local_time_offset: @schedule_data[:timezone_offset])
  end

  def import_events
    @events_created = 0

    @schedule_data[:events].each do |event_data|
      # Convert local datetime to UTC datetime (including date shift)
      utc_datetime = convert_to_utc_datetime(
        event_data[:date],
        event_data[:local_time],
        @schedule_data[:timezone_offset]
      )

      # Find the Day that matches the UTC date
      day = find_day_for_date(utc_datetime.to_date)
      next unless day

      session = find_or_create_session(event_data[:series], event_data[:session])

      Event.create!(
        day: day,
        session: session,
        start_time: utc_datetime.strftime("%H:%M"),
        racing_class: event_data[:series],
        name: event_data[:session]
      )

      @events_created += 1
    end
  end

  def find_day_for_date(date)
    @weekend.days.find_by(date: date)
  end

  def find_or_create_session(series_name, session_name)
    series = Series.find_or_create_by!(name: series_name)
    series.sessions.find_or_create_by!(name: session_name)
  end

  def convert_to_utc_datetime(local_date, local_time_str, offset_str)
    hours, minutes = local_time_str.split(":").map(&:to_i)

    # Create a datetime in the local timezone
    local_datetime = DateTime.new(
      local_date.year,
      local_date.month,
      local_date.day,
      hours,
      minutes,
      0,
      offset_str
    )

    # Convert to UTC
    local_datetime.utc
  end
end
