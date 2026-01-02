class Weekend < ApplicationRecord
  has_many :events, dependent: :destroy
  belongs_to :season
end
