# spec/services/ai/gift_suggester_spec.rb
require "rails_helper"

RSpec.describe Ai::GiftSuggester, type: :service do
  let(:user) { create(:user, name: "User One", likes: "Books", dislikes: "Perfume") }

  let(:event) do
    create(:event,
           user: user,
           event_name: "Birthday",
           event_date: Date.today + 10,
           budget: event_budget)
  end

  let(:recipient) do
    create(:recipient,
           user: user,
           name: "Sam",
           email: "sam@example.com",
           relationship: "Friend",
           budget: recipient_budget)
  end

  let(:event_recipient) do
    create(:event_recipient,
           user: user,
           event: event,
           recipient: recipient,
           budget_allocated: budget_allocated)
  end

  # IMPORTANT: deterministic, no real network
  let(:gemini_client) { instance_double(Ai::GeminiClient) }
  let(:unsplash_client) { instance_double(UnsplashClient) }

  let(:event_budget) { 100.00 }
  let(:recipient_budget) { nil }
  let(:budget_allocated) { nil }

  subject(:service) do
    described_class.new(
      user: user,
      event_recipient: event_recipient,
      gemini_client: gemini_client,
      unsplash_client: unsplash_client
    )
  end

  before do
    # Avoid touching PromptBuilder internals (not needed for GiftSuggester coverage)
    allow(Ai::PromptBuilder).to receive(:new).and_return(instance_double(Ai::PromptBuilder, build: "PROMPT"))
  end

  describe "#call" do
    it "creates only unique, non-blank suggestions and returns created records" do
      # Existing previous AI title for this same event_recipient
      create(:ai_gift_suggestion,
             user: user,
             event: event,
             recipient: recipient,
             event_recipient: event_recipient,
             title: "Coffee Mug",
             round_type: "initial")

      # Past gifts (queried but mainly for prompt context)
      GiftGivenBacklog.create!(
        user: user,
        recipient: recipient,
        gift_name: "Old Gift",
        category: "General",
        given_on: Date.today - 10,
        price: 20.00
      )

      # Gemini returns mixed quality ideas: blank, duplicates vs previous, duplicates in same batch
      idea_hashes = [
        { "title" => "   " , "description" => "blank title should be skipped", "category" => "General" },
        { "title" => "Coffee Mug", "description" => "duplicate of previous should be skipped", "category" => "Home" },
        { "title" => " coffee mug ", "description" => "case-insensitive dup of previous", "category" => "Home" },
        { "title" => "Book Light", "description" => "good", "category" => "Books", "estimated_price" => "$10-$20" },
        { "title" => "book light", "description" => "dup within same batch", "category" => "Books" },
        { "title" => "Cooking Class", "description" => "good", "category" => "Experience", "special_notes" => "local class" }
      ]

      allow(gemini_client).to receive(:generate_gift_ideas).with("PROMPT").and_return(idea_hashes)

      # Image fetch is called per kept idea
      allow(unsplash_client).to receive(:search_image).and_return("http://example.com/img.jpg")

      expect do
        results = service.call(round_type: "regenerate")

        # Only 2 new unique non-blank titles should be created: "Book Light", "Cooking Class"
        expect(results.map(&:title)).to match_array(["Book Light", "Cooking Class"])
        expect(results.all? { |r| r.round_type == "regenerate" }).to be(true)
        expect(results.all? { |r| r.image_url == "http://example.com/img.jpg" }).to be(true)
      end.to change(AiGiftSuggestion, :count).by(2)
    end
  end

  describe "budget calculation branches (private)" do
    it "uses recipient budget when present" do
      recipient.update!(budget: 50.00)
      event_recipient.update!(budget_allocated: 12.00)

      cents = service.send(:compute_effective_budget_cents)
      expect(cents).to eq(5000)
    end

    it "uses event_recipient budget_allocated when recipient budget is nil" do
      recipient.update!(budget: nil)
      event_recipient.update!(budget_allocated: 12.34)

      cents = service.send(:compute_effective_budget_cents)
      expect(cents).to eq(1234)
    end

    it "splits event budget across recipients when both recipient and allocated budgets are nil" do
      # Ensure event has exactly 1 recipient through event_recipient
      recipient.update!(budget: nil)
      event_recipient.update!(budget_allocated: nil)
      event.update!(budget: 100.00)

      cents = service.send(:compute_effective_budget_cents)
      # 100.00 / 1 recipient = 100.00 => 10000 cents
      expect(cents).to eq(10_000)
    end

    it "returns nil when event has budget but recipient count is zero (edge branch)" do
      # To hit count.zero? we must avoid any persisted recipients for the event.
      # We'll test the private method on a service built with a non-persisted event_recipient.
      empty_event = create(:event, user: user, budget: 99.00)
      unsaved_recipient = build(:recipient, user: user, budget: nil)
      unsaved_er = build(:event_recipient, user: user, event: empty_event, recipient: unsaved_recipient, budget_allocated: nil)

      s = described_class.new(user: user, event_recipient: unsaved_er, gemini_client: gemini_client, unsplash_client: unsplash_client)
      cents = s.send(:compute_effective_budget_cents)

      expect(cents).to be_nil
    end

    it "returns nil when no budgets exist anywhere" do
      recipient.update!(budget: nil)
      event_recipient.update!(budget_allocated: nil)
      event.update!(budget: nil)

      cents = service.send(:compute_effective_budget_cents)
      expect(cents).to be_nil
    end
  end

  describe "image fetching rescue branches (private)" do
    it "returns nil and logs when UnsplashClient::Error occurs" do
      allow(unsplash_client).to receive(:search_image).and_raise(UnsplashClient::Error.new("nope"))
      allow(Rails.logger).to receive(:warn)

      url = service.send(:safe_fetch_image_url, "query")
      expect(url).to be_nil
      expect(Rails.logger).to have_received(:warn).with(/\[Unsplash\] UnsplashClient::Error: nope/)
    end

    it "returns nil and logs when an unexpected error occurs" do
      allow(unsplash_client).to receive(:search_image).and_raise(StandardError.new("boom"))
      allow(Rails.logger).to receive(:warn)

      url = service.send(:safe_fetch_image_url, "query")
      expect(url).to be_nil
      expect(Rails.logger).to have_received(:warn).with(/\[Unsplash\] unexpected error: StandardError boom/)
    end
  end
end
