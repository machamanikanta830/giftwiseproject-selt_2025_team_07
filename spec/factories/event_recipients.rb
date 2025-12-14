FactoryBot.define do
  factory :event_recipient do
    association :user
    association :event
    association :recipient
    budget_allocated { 0 }
    gift_status { "planning" }
  end
end
