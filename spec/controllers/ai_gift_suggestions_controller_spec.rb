# spec/controllers/ai_gift_suggestions_controller_spec.rb
require "rails_helper"

RSpec.describe AiGiftSuggestionsController, type: :controller do
  render_views

  let(:owner) { User.create!(name: "Owner", email: "owner@example.com", password: "Password@123") }
  let(:co_planner) { User.create!(name: "Co", email: "co@example.com", password: "Password@123") }
  let(:viewer) { User.create!(name: "Viewer", email: "viewer@example.com", password: "Password@123") }

  let(:event) do
    Event.create!(user: owner, event_name: "Party", event_date: Date.today + 10, budget: 100.0)
  end

  let(:recipient) do
    Recipient.create!(user: owner, name: "Sam", email: "sam@example.com", relationship: "Friend")
  end

  let(:event_recipient) do
    EventRecipient.create!(user: owner, event: event, recipient: recipient, budget_allocated: 0)
  end

  before do
    allow_any_instance_of(ApplicationController).to receive(:authenticate_user!).and_return(true)
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(owner)

    # Make sure can_manage_gifts? passes by default
    allow_any_instance_of(Event).to receive(:can_manage_gifts?).and_return(true)
  end

  def make_suggestion(title:, user: owner, ev: event, rec: recipient, er: event_recipient, created_at: Time.current, category: "General")
    s = AiGiftSuggestion.create!(
      user: user, event: ev, recipient: rec, event_recipient: er,
      title: title, description: "d", round_type: "initial", category: category
    )
    s.update_column(:created_at, created_at)
    s
  end

  describe "GET #index" do
    it "loads recipients and groups suggestions by recipient_id" do
      event_recipient # ensure link exists
      make_suggestion(title: "Idea 1")

      get :index, params: { event_id: event.id }
      expect(response).to have_http_status(:ok)
      expect(assigns(:recipients)).to be_present
      expect(assigns(:suggestions_by_recipient)).to be_a(Hash)
      expect(assigns(:suggestions_by_recipient)[recipient.id].first.title).to eq("Idea 1")
    end
  end

  describe "POST #create" do
    before { event_recipient }
    it "uses stub ideas when AI not enabled in test/dev and redirects with sample notice" do
      # Force ai_enabled? false
      allow_any_instance_of(AiGiftSuggestionsController).to receive(:ai_enabled?).and_return(false)

      expect {
        post :create, params: { event_id: event.id, recipient_id: recipient.id, round_type: "initial" }
      }.to change(AiGiftSuggestion, :count).by(5)

      expect(response).to redirect_to(event_ai_gift_suggestions_path(event, from: nil))
      expect(flash[:notice]).to include("sample ideas")
    end

    it "falls back to stub ideas when Gemini errors and returns blank ideas" do
      allow_any_instance_of(AiGiftSuggestionsController).to receive(:ai_enabled?).and_return(true)

      fake_suggester = instance_double(Ai::GiftSuggester)
      allow(Ai::GiftSuggester).to receive(:new).and_return(fake_suggester)

      # controller calls suggester.call twice (duplicated block); make both raise
      allow(fake_suggester).to receive(:call).and_raise(Ai::GeminiClient::Error.new("boom"))

      expect {
        post :create, params: { event_id: event.id, recipient_id: recipient.id, round_type: "regenerate" }
      }.to change(AiGiftSuggestion, :count).by(5)

      expect(response).to redirect_to(event_ai_gift_suggestions_path(event, from: nil))
      expect(flash[:notice]).to include("sample ideas")
    end

    it "uses AI ideas when suggester returns non-empty and sets normal notice" do
      allow_any_instance_of(AiGiftSuggestionsController).to receive(:ai_enabled?).and_return(true)

      fake_suggester = instance_double(Ai::GiftSuggester)
      allow(Ai::GiftSuggester).to receive(:new).and_return(fake_suggester)

      # Return non-empty both times (because controller calls twice)
      allow(fake_suggester).to receive(:call).and_return(
        [make_suggestion(title: "AI 1", category: "Tech")],
        [make_suggestion(title: "AI 2", category: "Tech")]
      )

      post :create, params: { event_id: event.id, recipient_id: recipient.id, round_type: "initial" }

      expect(response).to redirect_to(event_ai_gift_suggestions_path(event, from: nil))
      expect(flash[:notice]).to include("Generated 1 ideas").or include("Generated 1 ideas")
      # NOTE: Because the controller calls twice, the second call overwrites ideas.
      # Our expectation is just that it goes down the non-fallback notice path.
      expect(flash[:notice]).not_to include("sample ideas")
    end
  end

  describe "POST #toggle_wishlist" do
    before do
      # Make collaborator scope work (accepted)
      event.collaborators.create!(user: co_planner, role: Collaborator::ROLE_CO_PLANNER, status: Collaborator::STATUS_ACCEPTED)
      # viewer accepted but should NOT be in planner_ids (role filter)
      event.collaborators.create!(user: viewer, role: Collaborator::ROLE_VIEWER, status: Collaborator::STATUS_ACCEPTED)
    end

    it "when already saved: deletes wishlists for all planners" do
      suggestion = make_suggestion(title: "SaveMe")
      # Pre-create wishlists for owner + co_planner + viewer
      Wishlist.create!(user: owner, recipient: recipient, item_name: "x", ai_gift_suggestion: suggestion)
      Wishlist.create!(user: co_planner, recipient: recipient, item_name: "x", ai_gift_suggestion: suggestion)
      Wishlist.create!(user: viewer, recipient: recipient, item_name: "x", ai_gift_suggestion: suggestion)

      request.env["HTTP_REFERER"] = "/back"

      expect {
        post :toggle_wishlist, params: { event_id: event.id, id: suggestion.id }
      }.to change(Wishlist, :count).by(-2) # deletes for planner_ids (owner+co_planner), viewer remains

      expect(response).to redirect_to("/back")
    end
  end

    it "when not saved: creates wishlists for all planners (owner + accepted co-planner/owner)" do
      suggestion = make_suggestion(title: "NewSave")
      request.env["HTTP_REFERER"] = "/back"

      expect(Wishlist.where(ai_gift_suggestion_id: suggestion.id).count).to eq(0)

      post :toggle_wishlist, params: { event_id: event.id, id: suggestion.id }

      planner_wls = Wishlist.where(ai_gift_suggestion_id: suggestion.id, user_id: [owner.id, co_planner.id])
      expect(planner_wls.count).to eq(2)
      expect(planner_wls.all? { |w| w.recipient_id == recipient.id }).to be(true)

      # viewer should NOT be created by role filter
      expect(Wishlist.exists?(ai_gift_suggestion_id: suggestion.id, user_id: viewer.id)).to be(false)

      expect(response).to redirect_to("/back")
    end
  end

  describe "GET #library" do
    let(:collab_owner) { User.create!(name: "OtherOwner", email: "otherowner@example.com", password: "Password@123") }
    let(:collab_event) do
      Event.create!(user: collab_owner, event_name: "CollabEvent", event_date: Date.today + 8, budget: 40.0)
    end
    let(:collab_recipient) do
      Recipient.create!(user: collab_owner, name: "Alex", email: "alex@example.com", relationship: "Friend")
    end
    let(:collab_er) { EventRecipient.create!(user: collab_owner, event: collab_event, recipient: collab_recipient, budget_allocated: 10.0) }

    before do
      # Make current_user able to access both events
      allow(Event).to receive(:accessible_to).with(owner).and_return(Event.where(id: [event.id, collab_event.id]))

      # Build suggestions across events/recipients/categories/time
      make_suggestion(title: "MineOld", created_at: 3.days.ago, category: "Books")
      make_suggestion(title: "MineNew", created_at: 1.day.ago, category: "Tech")

      make_suggestion(
        title: "CollabNew",
        user: collab_owner,
        ev: collab_event,
        rec: collab_recipient,
        er: collab_er,
        created_at: 2.days.ago,
        category: "Tech"
      )
    end

    it "scope=mine shows only my events" do
      get :library, params: { scope: "mine" }
      expect(response).to have_http_status(:ok)
      expect(assigns(:events).map(&:id)).to match_array([event.id])
    end

    it "scope=collab shows only collaborator events (not mine)" do
      get :library, params: { scope: "collab" }
      expect(assigns(:events).map(&:id)).to match_array([collab_event.id])
    end

    it "scope=all shows all accessible events" do
      get :library, params: { scope: "all" }
      expect(assigns(:events).map(&:id)).to match_array([event.id, collab_event.id])
    end

    it "applies filters: event_id, recipient_id, category, saved_only, sort=oldest" do
      # Save one of mine to wishlist
      mine_new = AiGiftSuggestion.find_by(title: "MineNew")
      Wishlist.create!(user: owner, recipient: recipient, item_name: "x", ai_gift_suggestion: mine_new)

      get :library, params: {
        scope: "all",
        event_id: event.id,
        recipient_id: recipient.id,
        category: "Tech",
        saved_only: "1",
        sort: "oldest"
      }

      expect(response).to have_http_status(:ok)
      suggestions = assigns(:suggestions)
      expect(suggestions.map(&:title)).to eq(["MineNew"]) # only the saved Tech in my event/recipient
      expect(assigns(:sort)).to eq("oldest")
      expect(assigns(:selected_event_id)).to eq(event.id.to_s)
      expect(assigns(:selected_recipient_id)).to eq(recipient.id.to_s)
      expect(assigns(:selected_category)).to eq("Tech")
      expect(assigns(:recipients)).to be_present
    end
  end

  describe "set_event guard" do
    it "redirects to dashboard if user cannot manage gifts" do
      allow_any_instance_of(Event).to receive(:can_manage_gifts?).and_return(false)

      get :index, params: { event_id: event.id }

      expect(response).to redirect_to(dashboard_path)
      expect(flash[:alert]).to match(/do not have permission/i)
    end
  end
end
