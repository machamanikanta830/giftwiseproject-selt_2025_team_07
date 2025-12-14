FactoryBot.define do
  factory :cart_item do
    association :cart
    association :ai_gift_suggestion
    association :recipient
    association :event

    quantity { 1 }
  end
end
