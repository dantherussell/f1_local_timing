class Season < ApplicationRecord
  has_many :weekends, dependent: :destroy
end
