FactoryBot.define do
  factory :event do
    racing_class { "MyString" }
    name { "MyString" }
    start_time { "2026-01-02 13:34:40" }
    local_time_offset { "MyString" }
    weekend { nil }
    session { nil }
  end
end
