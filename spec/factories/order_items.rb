FactoryBot.define do
  factory :order_item do
    association :order
    association :recipient
    association :event
    association :ai_gift_suggestion

    title { "Sample Gift" }
    description { "Gift description" }
    estimated_price { "$20" }
    category { "General" }
    quantity { 1 }
  end
end
