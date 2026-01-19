class Weekend < ApplicationRecord
  has_many :days, dependent: :destroy
  has_many :events, through: :days
  belongs_to :season

  validate :first_day_before_last_day
  after_save :sync_days

  def timespan
    return nil if first_day.blank? || last_day.blank?

    if first_day.month == last_day.month
      "#{first_day.day}-#{last_day.day} #{first_day.strftime('%B')}"
    else
      "#{first_day.strftime('%-d %B')} - #{last_day.strftime('%-d %B')}"
    end
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
