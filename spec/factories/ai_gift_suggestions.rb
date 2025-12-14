# spec/factories/ai_gift_suggestions.rb
# Add these factories to your existing factory files or create new ones as needed

FactoryBot.define do
  factory :ai_gift_suggestion do
    association :user
    association :event
    association :recipient
    association :event_recipient

    sequence(:title) { |n| "Gift Idea #{n}" }
    description { "A wonderful gift suggestion" }
    category { "General" }
    estimated_price { "$25-$50" }
    round_type { "initial" }
    saved_to_wishlist { false }

    trait :saved do
      saved_to_wishlist { true }
    end

    trait :electronics do
      category { "Electronics" }
      title { "Wireless Headphones" }
      description { "High-quality noise-canceling headphones" }
      estimated_price { "$100-$200" }
    end

    trait :books do
      category { "Books" }
      title { "Bestselling Novel" }
      description { "A captivating fiction book" }
      estimated_price { "$15-$25" }
    end
  end
  #
  # factory :wishlist do
  #   association :user
  #   association :ai_gift_suggestion
  #   association :recipient
  # end

  factory :collaborator do
    association :event
    association :user
    role { Collaborator::ROLE_CO_PLANNER }
    status { "pending" }

    trait :accepted do
      status { "accepted" }
    end

    trait :rejected do
      status { "rejected" }
    end

    trait :co_planner do
      role { Collaborator::ROLE_CO_PLANNER }
    end

    trait :owner do
      role { Collaborator::ROLE_OWNER }
    end

    trait :viewer do
      role { Collaborator::ROLE_VIEWER }
    end
  end
end