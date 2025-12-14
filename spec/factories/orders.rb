FactoryBot.define do
  factory :order do
    association :user
    status { "placed" }
    placed_at { Time.current }
  end
end
