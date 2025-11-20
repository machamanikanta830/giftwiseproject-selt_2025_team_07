FactoryBot.define do
  factory :password_reset_token do
    association :user
    used { false }

    after(:build) do |token|
      token.token = SecureRandom.urlsafe_base64(32) if token.token.nil?
      token.expires_at = 1.hour.from_now if token.expires_at.nil?
    end

    trait :expired do
      after(:build) do |token|
        token.expires_at = 1.hour.ago
      end
    end

    trait :used do
      used { true }
    end

    trait :expiring_soon do
      after(:build) do |token|
        token.expires_at = 5.minutes.from_now
      end
    end

    trait :just_created do
      after(:build) do |token|
        token.created_at = 1.minute.ago
        token.expires_at = 59.minutes.from_now
      end
    end
  end
end