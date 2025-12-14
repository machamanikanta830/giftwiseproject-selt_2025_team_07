# spec/controllers/chatbots_controller_spec.rb
require "rails_helper"

RSpec.describe ChatbotsController, type: :controller do
  render_views

  let(:user) do
    User.create!(
      name: "Tester",
      email: "tester@example.com",
      password: "Password@123"
    )
  end

  before do
    allow_any_instance_of(ApplicationController).to receive(:authenticate_user!).and_return(true)
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
  end

  def json
    JSON.parse(response.body)
  end

  describe "POST #message" do
    it "handles command reset (sets history + main quick replies)" do
      post :message, params: { command: "reset" }

      expect(response).to have_http_status(:ok)
      expect(json["messages"]).to be_an(Array)
      expect(json["messages"].first["role"]).to eq("bot")
      expect(json["messages"].first["text"]).to include("Conversation restarted")
      expect(json["quick_replies"].map { |x| x["intent"] || x[:intent] }).to include("summary_upcoming_events")
    end

    it "handles command exit (clears history)" do
      session[:chatbot_history] = [{ "role" => "bot", "text" => "hi" }]

      post :message, params: { command: "exit" }

      expect(response).to have_http_status(:ok)
      expect(json["messages"]).to eq([])
      expect(json["quick_replies"].map { |x| x["intent"] || x[:intent] }).to include("summary_upcoming_events")
    end

    it "does nothing when both text and intent are blank (returns existing history + main quick replies)" do
      session[:chatbot_history] = [{ "role" => "bot", "text" => "existing" }]

      post :message, params: { text: "   " }

      expect(response).to have_http_status(:ok)
      expect(json["messages"]).to eq([{ "role" => "bot", "text" => "existing" }])
      expect(json["quick_replies"].map { |x| x["intent"] || x[:intent] }).to include("summary_recipients")
    end

    it "switches to nav mode via intent and returns nav quick replies" do
      post :message, params: { intent: "nav_menu" }

      expect(response).to have_http_status(:ok)
      expect(json["messages"].last["text"]).to include("Navigation help")
      intents = json["quick_replies"].map { |x| x["intent"] || x[:intent] }
      expect(intents).to include("nav_add_event", "nav_view_events", "main_menu")
    end

    it "switches back to main menu via intent and returns main quick replies" do
      session[:chatbot_mode] = "nav"

      post :message, params: { intent: "main_menu" }

      expect(response).to have_http_status(:ok)
      expect(json["messages"].last["text"]).to include("Here’s what I can help with")
      intents = json["quick_replies"].map { |x| x["intent"] || x[:intent] }
      expect(intents).to include("summary_upcoming_events", "summary_wishlist", "nav_menu")
    end

    it "routes free-text 'wishlist' to wishlist_summary (empty case)" do
      post :message, params: { text: "show my wishlist" }

      expect(response).to have_http_status(:ok)
      expect(json["messages"].last["role"]).to eq("bot")
      expect(json["messages"].last["text"]).to include("Your wishlist is empty")
    end

    it "routes free-text unknown text to main menu text" do
      post :message, params: { text: "blabla something random" }

      expect(response).to have_http_status(:ok)
      expect(json["messages"].last["text"]).to include("Tap a suggestion below")
    end

    it "upcoming events summary: empty branch" do
      post :message, params: { intent: "summary_upcoming_events" }

      expect(response).to have_http_status(:ok)
      expect(json["messages"].last["text"]).to include("don’t have any upcoming events")
    end

    it "upcoming events summary: shows first 5 and '...plus N more' branch" do
      # create 6 upcoming events
      6.times do |i|
        Event.create!(
          user: user,
          event_name: "E#{i + 1}",
          event_date: Date.today + (i + 1),
          budget: (i + 1) * 10
        )
      end

      post :message, params: { intent: "summary_upcoming_events" }

      text = json["messages"].last["text"]
      expect(text).to include("Here are your upcoming events")
      expect(text).to include("…plus 1 more event(s).")
    end

    it "recipients summary: empty branch" do
      post :message, params: { intent: "summary_recipients" }
      expect(json["messages"].last["text"]).to include("don’t have any recipients yet")
    end

    it "recipients summary: shows first 8 and '...plus N more' branch" do
      10.times do |i|
        Recipient.create!(
          user: user,
          name: "R#{i + 1}",
          email: "r#{i + 1}@example.com",
          relationship: "Friend"
        )
      end

      post :message, params: { intent: "summary_recipients" }

      text = json["messages"].last["text"]
      expect(text).to include("You currently have 10 recipient(s)")
      expect(text).to include("…plus 2 more recipient(s).")
    end

    it "wishlist summary: grouped branch" do
      r1 = Recipient.create!(user: user, name: "Sam",  email: "sam2@example.com", relationship: "Friend")
      r2 = Recipient.create!(user: user, name: "Alex", email: "alex@example.com", relationship: "Friend")

      e = Event.create!(user: user, event_name: "Party", event_date: Date.today + 7, budget: 50.0)

      er1 = EventRecipient.create!(user: user, event: e, recipient: r1, budget_allocated: 0)
      er2 = EventRecipient.create!(user: user, event: e, recipient: r2, budget_allocated: 0)

      s1 = AiGiftSuggestion.create!(
        user: user, event: e, recipient: r1, event_recipient: er1,
        title: "Idea 1", description: "d", round_type: "initial"
      )
      s2 = AiGiftSuggestion.create!(
        user: user, event: e, recipient: r1, event_recipient: er1,
        title: "Idea 2", description: "d", round_type: "initial"
      )
      s3 = AiGiftSuggestion.create!(
        user: user, event: e, recipient: r2, event_recipient: er2,
        title: "Idea 3", description: "d", round_type: "initial"
      )

      Wishlist.create!(user: user, recipient: r1, item_name: "Item 1", ai_gift_suggestion: s1)
      Wishlist.create!(user: user, recipient: r1, item_name: "Item 2", ai_gift_suggestion: s2)
      Wishlist.create!(user: user, recipient: r2, item_name: "Item 3", ai_gift_suggestion: s3)

      post :message, params: { intent: "summary_wishlist" }

      text = json["messages"].last["text"]
      expect(text).to include("Here’s a quick wishlist overview")
      expect(text).to include("Sam: 2 item(s)")
      expect(text).to include("Alex: 1 item(s)")
    end


    it "budget (all upcoming events): empty branch" do
      post :message, params: { intent: "summary_budgets_per_event" }
      expect(json["messages"].last["text"]).to include("no upcoming budgets")
    end

    it "budget (all upcoming events): normal branch" do
      e1 = Event.create!(user: user, event_name: "Party", event_date: Date.today + 3, budget: 50.0)
      r  = Recipient.create!(user: user, name: "Rec", email: "rec@example.com", relationship: "Friend")
      EventRecipient.create!(user: user, event: e1, recipient: r, budget_allocated: 20.0)

      post :message, params: { intent: "summary_budgets_per_event" }

      text = json["messages"].last["text"]
      expect(text).to include("Here’s the budget for your upcoming events")
      expect(text).to include("Party")
      expect(text).to include("$20.0").or include("$20.00")
    end

    it "budget (all upcoming events): rescue branch" do
      # Force upcoming_events_per_event_budget to raise, hitting safe_upcoming_events_per_event_budget rescue
      allow_any_instance_of(ChatbotsController).to receive(:upcoming_events_per_event_budget).and_raise(StandardError.new("boom"))

      post :message, params: { intent: "summary_budgets_per_event" }

      expect(response).to have_http_status(:ok)
      expect(json["messages"].last["text"]).to include("trouble calculating budgets")
    end

    it "budget single event: prompts custom quick replies" do
      Event.create!(user: user, event_name: "X", event_date: Date.today + 7, budget: 10.0)

      post :message, params: { intent: "budget_single_event" }

      expect(response).to have_http_status(:ok)
      expect(json["messages"].last["text"]).to include("Choose an event below")
      intents = json["quick_replies"].map { |x| x["intent"] || x[:intent] }
      expect(intents.any? { |i| i.to_s.start_with?("budget_event_") }).to be(true)
      expect(intents).to include("main_menu")
    end

    it "budget_event_ intent: event not found branch" do
      post :message, params: { intent: "budget_event_999999" }
      expect(json["messages"].last["text"]).to include("couldn’t find that event anymore")
    end

    it "budget_event_ intent: no linked recipients and has event budget branch" do
      e = Event.create!(user: user, event_name: "NoLinks", event_date: Date.today + 2, budget: 80.0)

      post :message, params: { intent: "budget_event_#{e.id}" }

      expect(json["messages"].last["text"]).to include("no recipient-specific budgets")
      expect(json["messages"].last["text"]).to include("overall event budget is $80")
    end

    it "budget_event_ intent: no linked recipients and no event budget branch" do
      e = Event.create!(user: user, event_name: "NoLinks2", event_date: Date.today + 2, budget: nil)

      post :message, params: { intent: "budget_event_#{e.id}" }

      expect(json["messages"].last["text"]).to include("no recipients linked")
      expect(json["messages"].last["text"]).to include("no overall budget set")
    end

    it "budget_event_ intent: has recipients but none allocated and has event budget branch" do
      e = Event.create!(user: user, event_name: "HasRecs", event_date: Date.today + 4, budget: 60.0)
      r = Recipient.create!(user: user, name: "Sam", email: "sam_budget@example.com", relationship: "Friend")
      EventRecipient.create!(user: user, event: e, recipient: r, budget_allocated: 0)

      post :message, params: { intent: "budget_event_#{e.id}" }

      text = json["messages"].last["text"]
      expect(text).to include("haven’t set budgets per recipient yet")
      expect(text).to include("total budget for this event is $60")
    end

    it "budget_event_ intent: has allocated budgets branch" do
      e = Event.create!(user: user, event_name: "Allocated", event_date: Date.today + 4, budget: 60.0)
      r1 = Recipient.create!(user: user, name: "A", email: "a@example.com", relationship: "Friend")
      r2 = Recipient.create!(user: user, name: "B", email: "b@example.com", relationship: "Friend")

      EventRecipient.create!(user: user, event: e, recipient: r1, budget_allocated: 15.0)
      EventRecipient.create!(user: user, event: e, recipient: r2, budget_allocated: 0)

      post :message, params: { intent: "budget_event_#{e.id}" }

      text = json["messages"].last["text"]
      expect(text).to include("Budget breakdown for Allocated")
      expect(text).to include("• A — $15")
      expect(text).to include("• B — not set")
      expect(text).to include("Total for this event: $15")
    end

    it "free-text routing: navigation phrases map to nav responses (no collisions)" do
      post :message, params: { text: "how do i add an event" }
      expect(json["messages"].last["text"]).to include("To add an event")

      post :message, params: { text: "edit profile" }
      expect(json["messages"].last["text"]).to include("To edit profile")

      post :message, params: { text: "change password" }
      expect(json["messages"].last["text"]).to include("To change password")
    end

    it "intent routing: nav_link_recipients returns instructions" do
      post :message, params: { intent: "nav_link_recipients" }
      expect(json["messages"].last["text"]).to include("To link recipients to an event")
    end


    it "rescues unexpected errors and returns 500 with fallback quick replies" do
      # Force handle_message to raise to hit outer rescue in #message
      allow_any_instance_of(ChatbotsController).to receive(:handle_message).and_raise(StandardError.new("boom"))

      post :message, params: { text: "hi" }

      expect(response).to have_http_status(:internal_server_error)
      expect(json["messages"]).to be_an(Array)
      intents = json["quick_replies"].map { |x| x["intent"] || x[:intent] }
      expect(intents).to include("summary_upcoming_events", "nav_menu")
    end
  end
end
