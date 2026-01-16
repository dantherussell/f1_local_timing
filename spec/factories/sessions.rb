FactoryBot.define do
  factory :session do
    sequence(:name) { |n| "Session #{n}" }
    series

    trait :practice do
      name { "Practice 1" }
    end

    trait :qualifying do
      name { "Qualifying" }
    end

    trait :race do
      name { "Race" }
    end
  end
end
