class Weekend < ApplicationRecord
  has_many :days, dependent: :destroy
  has_many :events, through: :days
  belongs_to :season

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

  def sync_days
    return if first_day.blank? || last_day.blank?

    date_range = (first_day..last_day).to_a

    # Remove days outside the new range
    days.where.not(date: date_range).destroy_all

    # Add new days
    date_range.each do |date|
      days.find_or_create_by(date: date)
    end
  end
end
