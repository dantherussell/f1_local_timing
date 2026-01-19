FactoryBot.define do
  factory :weekend do
    sequence(:gp_title) { |n| "Grand Prix #{n}" }
    location { "Monaco" }
    first_day { Date.new(2024, 5, 24) }
    last_day { Date.new(2024, 5, 26) }
    local_timezone { "Europe/Monaco" }
    local_time_offset { "+02:00" }
    sequence(:race_number) { |n| n }
    season

    trait :monaco do
      gp_title { "Monaco Grand Prix" }
      location { "Monte Carlo" }
      local_timezone { "Europe/Monaco" }
      local_time_offset { "+02:00" }
    end

    trait :silverstone do
      gp_title { "British Grand Prix" }
      location { "Silverstone" }
      local_timezone { "Europe/London" }
      local_time_offset { "+01:00" }
    end

    trait :suzuka do
      gp_title { "Japanese Grand Prix" }
      location { "Suzuka" }
      local_timezone { "Asia/Tokyo" }
      local_time_offset { "+09:00" }
    end
  end
end
