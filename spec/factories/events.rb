FactoryBot.define do
  factory :event do
    association :user
    event_name { "Test Event" }
    event_date { Date.today + 5 }
    budget { 100 }
  end
end
