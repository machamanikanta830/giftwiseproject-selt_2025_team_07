FactoryBot.define do
  factory :message do
    association :sender, factory: :user
    association :receiver, factory: :user

    body { "Hello there!" }
    read { false }
    deleted_by_user_ids { [] }
  end
end
