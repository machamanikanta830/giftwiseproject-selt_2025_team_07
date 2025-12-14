FactoryBot.define do
  factory :backup_code do
    association :user
    code_digest { "digest-#{SecureRandom.hex(8)}" }
    used { false }
    used_at { nil }
  end
end
