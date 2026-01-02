FactoryBot.define do
  factory :weekend do
    gp_title { "MyString" }
    location { "MyString" }
    timespan { "MyString" }
    local_timezone { "MyString" }
    local_time_offset { "MyString" }
    race_number { 1 }
    season { nil }
  end
end
