FactoryBot.define do
  factory :day do
    sequence(:date) { |n| Date.new(2024, 1, 1) + n.days }
    local_time_offset { nil }
    weekend { association :weekend, first_day: nil, last_day: nil }

    trait :with_local_offset do
      local_time_offset { "+02:00" }
    end

    trait :friday do
      date { Date.new(2024, 5, 24) }
    end

    trait :saturday do
      date { Date.new(2024, 5, 25) }
    end

    trait :sunday do
      date { Date.new(2024, 5, 26) }
    end
  end
end
