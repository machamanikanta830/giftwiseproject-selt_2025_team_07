FactoryBot.define do
  factory :mfa_credential do
    association :user
    secret_key { "JBSWY3DPEHPK3PXP" }
    enabled { false }
    enabled_at { nil }
  end
end