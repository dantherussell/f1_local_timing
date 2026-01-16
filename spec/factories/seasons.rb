FactoryBot.define do
  factory :season do
    sequence(:name) { |n| "#{2024 + n} F1 Season" }
  end
end
