class Series < ApplicationRecord
  has_many :sessions, dependent: :destroy
end
