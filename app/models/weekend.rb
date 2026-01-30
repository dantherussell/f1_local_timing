class Weekend < ApplicationRecord
  has_many :days, dependent: :destroy
  has_many :events, through: :days
  belongs_to :season

  validate :first_day_before_last_day
  after_save :sync_days

  def timespan
    first_date, last_date = local_date_range

    return nil if first_date.blank? || last_date.blank?

    if first_date.month == last_date.month
      "#{first_date.day}-#{last_date.day} #{first_date.strftime('%B')}"
    else
      "#{first_date.strftime('%-d %B')} - #{last_date.strftime('%-d %B')}"
    end
  end

  def local_date_range
    if events.exists?
      # Use database ordering instead of loading all events into memory
      ordered_events = events.includes(:day).order("days.date, events.start_time")
      first_event = ordered_events.first
      last_event = ordered_events.last

      [ first_event&.track_date, last_event&.track_date ]
    else
      # Fall back to UTC dates
      [ first_day, last_day ]
    end
  end

  def past?
    return false unless events.exists?

    last_event = events.includes(:day).order("days.date DESC, events.start_time DESC").first
    return false unless last_event&.start_datetime.present?

    last_event.start_datetime.to_time < Time.current
  end

  def next_event
    events.includes(:day, :session)
          .order("days.date, events.start_time")
          .find { |e| e.start_datetime && e.start_datetime.to_time > Time.current }
  end

  private

  def first_day_before_last_day
    return if first_day.blank? || last_day.blank?

    if first_day > last_day
      errors.add(:first_day, "must be before or equal to last day")
    end
  end

  def sync_days
    return if first_day.blank? || last_day.blank? || first_day > last_day

    date_range = (first_day..last_day).to_a

    # Remove days outside the new range
    days.where.not(date: date_range).destroy_all

    # Add new days
    date_range.each do |date|
      days.find_or_create_by(date: date)
    end
  end
end
