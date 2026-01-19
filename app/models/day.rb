class Day < ApplicationRecord
  belongs_to :weekend
  has_many :events, dependent: :destroy

  validates :date, presence: true
  validates :date, uniqueness: { scope: :weekend_id }

  delegate :season, to: :weekend

  def time_offset
    local_time_offset.presence || weekend.local_time_offset
  end

  def formatted_date
    date.strftime("%A %-d %B")
  end
end
