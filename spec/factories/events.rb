FactoryBot.define do
  factory :event do
    racing_class { "Formula 1" }
    name { "Race" }
    start_time { Time.parse("14:00") }
    local_time_offset { nil }
    day
    session

    trait :with_local_offset do
      local_time_offset { "+02:00" }
    end

    trait :practice do
      name { "Practice 1" }
      start_time { Time.parse("13:30") }
    end

    trait :qualifying do
      name { "Qualifying" }
      start_time { Time.parse("15:00") }
    end

    trait :race do
      name { "Race" }
      start_time { Time.parse("14:00") }
    end
  end
end
