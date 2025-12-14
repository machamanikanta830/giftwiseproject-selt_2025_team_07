require "rails_helper"

RSpec.describe AiGiftSuggestion, type: :model do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  let(:event) do
    create(
      :event,
      user: user,
      event_name: "Birthday",
      event_date: Date.today + 5
    )
  end

  let(:recipient) do
    create(
      :recipient,
      user: user,
      email: "sam@example.com"
    )
  end

  let(:event_recipient) do
    create(
      :event_recipient,
      user: user,
      event: event,
      recipient: recipient
    )
  end

  let(:suggestion) do
    create(
      :ai_gift_suggestion,
      user: user,
      event: event,
      recipient: recipient,
      event_recipient: event_recipient,
      title: "Test Gift"
    )
  end

  describe "saved_for_user?" do
    it "returns false when user is nil" do
      expect(suggestion.saved_for_user?(nil)).to eq(false)
    end

    it "returns false when suggestion is not saved by user" do
      expect(suggestion.saved_for_user?(other_user)).to eq(false)
    end

    it "returns true when suggestion is saved by user" do
      create(
        :wishlist,
        user: user,
        recipient: recipient,
        ai_gift_suggestion: suggestion
      )

      expect(suggestion.saved_for_user?(user)).to eq(true)
    end
  end
end
