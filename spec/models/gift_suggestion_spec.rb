# frozen_string_literal: true

require "rails_helper"

RSpec.describe GiftSuggestion, type: :model do
  it "is valid with required associations" do
    user      = create(:user)
    event     = create(:event, user: user)
    recipient = create(:recipient)

    event_recipient = create(
      :event_recipient,
      event: event,
      recipient: recipient
    )

    gift_suggestion = GiftSuggestion.new(
      user: user,
      event: event,
      recipient: recipient,
      event_recipient: event_recipient
    )

    expect(gift_suggestion).to be_valid
  end
end
