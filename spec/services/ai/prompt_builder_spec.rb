require "rails_helper"

RSpec.describe Ai::PromptBuilder do
  let(:user) do
    double(
      name: "Alex",
      likes: "Tech",
      dislikes: "Perfume"
    )
  end

  let(:event) do
    double(
      event_name: "Birthday",
      description: "Birthday celebration",
      event_date: Date.new(2025, 5, 10),
      location: "New York",
      budget: 100
    )
  end

  let(:recipient) do
    double(
      name: "Sam",
      relationship: "Friend",
      age: 25,
      gender: "Male",
      occupation: "Engineer",
      bio: "Loves gadgets",
      hobbies: "Gaming",
      likes: "Electronics",
      favorite_categories: "Tech",
      dislikes: "Books",
      budget: 50
    )
  end

  let(:event_recipient) do
    double(
      budget_allocated: 40
    )
  end

  let(:past_gift) do
    double(
      gift_name: "Headphones",
      price: 30,
      given_on: Date.new(2024, 5, 10),
      category: "Tech"
    )
  end

  describe "build" do
    it "returns a full prompt string with core sections" do
      builder = described_class.new(
        user: user,
        event: event,
        recipient: recipient,
        event_recipient: event_recipient,
        past_gifts: [],
        budget_cents: nil,
        previous_ai_titles: []
      )

      prompt = builder.build

      expect(prompt).to be_a(String)
      expect(prompt).to include("GiftWise")
      expect(prompt).to include("EVENT CONTEXT")
      expect(prompt).to include("RECIPIENT PROFILE")
      expect(prompt).to include("Please now return 5 gift ideas")
    end

    it "includes effective budget text when budget is present" do
      builder = described_class.new(
        user: user,
        event: event,
        recipient: recipient,
        event_recipient: event_recipient,
        past_gifts: [],
        budget_cents: 2500,
        previous_ai_titles: []
      )

      prompt = builder.build

      expect(prompt).to include("Try to keep each gift roughly within $25.00")
    end

    it "handles nil budget correctly" do
      builder = described_class.new(
        user: user,
        event: event,
        recipient: recipient,
        event_recipient: event_recipient,
        past_gifts: [],
        budget_cents: nil,
        previous_ai_titles: []
      )

      prompt = builder.build

      expect(prompt).to include("No strict budget")
    end

    it "lists past gifts when present" do
      builder = described_class.new(
        user: user,
        event: event,
        recipient: recipient,
        event_recipient: event_recipient,
        past_gifts: [past_gift],
        budget_cents: nil,
        previous_ai_titles: []
      )

      prompt = builder.build

      expect(prompt).to include("PAST GIFTS TO AVOID REPEATING")
      expect(prompt).to include("Headphones")
      expect(prompt).to include("Tech")
    end

    it "shows message when no past gifts exist" do
      builder = described_class.new(
        user: user,
        event: event,
        recipient: recipient,
        event_recipient: event_recipient,
        past_gifts: [],
        budget_cents: nil,
        previous_ai_titles: []
      )

      prompt = builder.build

      expect(prompt).to include("No past gifts recorded for this recipient")
    end

    it "lists previous AI titles when present" do
      builder = described_class.new(
        user: user,
        event: event,
        recipient: recipient,
        event_recipient: event_recipient,
        past_gifts: [],
        budget_cents: nil,
        previous_ai_titles: ["Smart Watch", "Bluetooth Speaker"]
      )

      prompt = builder.build

      expect(prompt).to include("AI GIFT IDEAS ALREADY SUGGESTED")
      expect(prompt).to include("Smart Watch")
      expect(prompt).to include("Bluetooth Speaker")
    end

    it "shows message when no previous AI titles exist" do
      builder = described_class.new(
        user: user,
        event: event,
        recipient: recipient,
        event_recipient: event_recipient,
        past_gifts: [],
        budget_cents: nil,
        previous_ai_titles: []
      )

      prompt = builder.build

      expect(prompt).to include("No previous AI suggestions for this recipient")
    end
  end
end
