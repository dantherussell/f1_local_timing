FactoryBot.define do
  factory :event do
    racing_class { "Formula 1" }
    name { "Race" }
    start_time { DateTime.new(2024, 5, 26, 14, 0, 0) }
    local_time_offset { nil }
    weekend
    session

    trait :with_local_offset do
      local_time_offset { "+02:00" }
    end

    trait :practice do
      name { "Practice 1" }
      start_time { DateTime.new(2024, 5, 24, 13, 30, 0) }
    end

    trait :qualifying do
      name { "Qualifying" }
      start_time { DateTime.new(2024, 5, 25, 15, 0, 0) }
    end

    trait :race do
      name { "Race" }
      start_time { DateTime.new(2024, 5, 26, 14, 0, 0) }
    end
  end
end
