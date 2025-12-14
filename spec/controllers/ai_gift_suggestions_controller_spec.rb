require "rails_helper"

RSpec.describe AiGiftSuggestionsController, type: :controller do
  let(:user) { create(:user) }

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

  before do
    allow(controller).to receive(:authenticate_user!).and_return(true)
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe "GET index" do
    it "loads AI gift suggestions index" do
      suggestion

      get :index, params: { event_id: event.id }

      expect(response).to have_http_status(:success)
      expect(assigns(:recipients)).to include(recipient)
      expect(assigns(:suggestions_by_recipient)).to be_present
    end
  end

  describe "POST create" do
    before do
      allow(controller).to receive(:ai_enabled?).and_return(false)
    end

    it "generates fallback AI gift suggestions" do
      post :create, params: {
        event_id: event.id,
        recipient_id: recipient.id
      }

      expect(response).to redirect_to(
                            event_ai_gift_suggestions_path(event)
                          )

      expect(AiGiftSuggestion.count).to be > 0
    end
  end

  describe "POST toggle_wishlist" do
    it "adds suggestion to wishlist" do
      post :toggle_wishlist, params: {
        event_id: event.id,
        id: suggestion.id
      }

      expect(response).to redirect_to(
                            event_ai_gift_suggestions_path(event)
                          )

      expect(
        Wishlist.exists?(
          user_id: user.id,
          ai_gift_suggestion_id: suggestion.id
        )
      ).to eq(true)
    end
  end

  describe "GET library" do
    it "loads AI gift library" do
      get :library

      expect(response).to have_http_status(:success)
      expect(assigns(:events)).to be_present
    end
  end
end
