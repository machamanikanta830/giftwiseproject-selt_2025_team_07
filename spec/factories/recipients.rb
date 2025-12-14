FactoryBot.define do
  factory :recipient do
    association :user
    name { "Sam" }
    sequence(:email) { |n| "recipient#{n}@example.com" }
    relationship { "Friend" }
    age { 25 }
    gender { "Other" }
    budget { 50 }
  end
end
