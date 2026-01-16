FactoryBot.define do
  factory :series do
    sequence(:name) { |n| "Formula #{n}" }

    trait :f1 do
      name { "Formula 1" }
    end

    trait :f2 do
      name { "Formula 2" }
    end

    trait :f3 do
      name { "Formula 3" }
    end
  end
end
