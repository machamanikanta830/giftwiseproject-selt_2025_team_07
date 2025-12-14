FactoryBot.define do
  factory :recipient do
    association :user
    name { "Sam" }
    email { "sam@example.com" }
    relationship { "Friend" }
    age { 25 }
    gender { "Other" }
    budget { 50 }
  end
end
