class Session < ApplicationRecord
  belongs_to :series
  has_many :events, dependent: :destroy
end
