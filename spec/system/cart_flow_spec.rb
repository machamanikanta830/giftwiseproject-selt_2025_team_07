require "rails_helper"

RSpec.describe "Cart flow", type: :system do
  let!(:user) do
    User.create!(
      name: "Test User",
      email: "test-#{SecureRandom.hex(6)}@example.com",
      password: "Password@1",
      password_confirmation: "Password@1"
    )
  end

  let!(:event) do
    Event.create!(
      user: user,
      event_name: "Birthday",
      event_date: Date.today + 5,
      budget: 100
    )
  end

  let!(:recipient) do
    Recipient.create!(
      user: user,
      name: "Alex",
      relationship: "Friend",
      email: "alex-#{SecureRandom.hex(6)}@example.com"
    )
  end

  let!(:event_recipient) do
    EventRecipient.create!(event: event, recipient: recipient)
  end

  let!(:idea) do
    AiGiftSuggestion.create!(
      user: user,
      event: event,
      recipient: recipient,
      event_recipient: event_recipient,
      title: "Headphones",
      description: "Nice wireless headphones",
      category: "Electronics",
      estimated_price: "$50"
    )
  end
end
