# spec/controllers/cart_items_controller_spec.rb
require "rails_helper"

RSpec.describe CartItemsController, type: :controller do
  let(:user) { User.create!(name: "Tester", email: "tester@example.com", password: "Password@123") }

  let(:event) do
    Event.create!(user: user, event_name: "Party", event_date: Date.today + 5, budget: 100.0)
  end

  let(:recipient) do
    Recipient.create!(user: user, name: "Sam", email: "sam@example.com", relationship: "Friend")
  end

  let(:event_recipient) do
    EventRecipient.create!(user: user, event: event, recipient: recipient, budget_allocated: 0)
  end

  let(:suggestion) do
    AiGiftSuggestion.create!(
      user: user,
      event: event,
      recipient: recipient,
      event_recipient: event_recipient,
      title: "Idea 1",
      description: "d",
      round_type: "initial",
      category: "General"
    )
  end

  # We stub Cart.for so this spec is deterministic even if Cart.for has extra logic/validations.
  let!(:cart) { Cart.create!(user: user) }

  before do
    allow_any_instance_of(ApplicationController).to receive(:authenticate_user!).and_return(true)
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)

    allow(Cart).to receive(:for).with(user).and_return(cart)

    # Default: event is accessible
    allow(Event).to receive(:accessible_to).with(user).and_return(Event.where(id: event.id))
  end

  describe "POST #create" do
    it "creates a cart item and redirects back with notice" do
      request.env["HTTP_REFERER"] = "/somewhere"

      expect {
        post :create, params: { ai_gift_suggestion_id: suggestion.id }
      }.to change(CartItem, :count).by(1)

      item = CartItem.last
      expect(item.cart_id).to eq(cart.id)
      expect(item.ai_gift_suggestion_id).to eq(suggestion.id)
      expect(item.recipient_id).to eq(recipient.id)
      expect(item.event_id).to eq(event.id)
      expect(item.quantity).to eq(1)

      expect(response).to redirect_to("/somewhere")
      expect(flash[:notice]).to eq("Added to cart.")
    end

    it "does not duplicate cart items (find_or_create_by path)" do
      request.env["HTTP_REFERER"] = "/somewhere"

      post :create, params: { ai_gift_suggestion_id: suggestion.id }

      expect {
        post :create, params: { ai_gift_suggestion_id: suggestion.id }
      }.not_to change(CartItem, :count)

      expect(response).to redirect_to("/somewhere")
      expect(flash[:notice]).to eq("Added to cart.")
    end

    it "raises RecordNotFound when event is not accessible" do
      allow(Event).to receive(:accessible_to).with(user).and_return(Event.none)

      expect {
        post :create, params: { ai_gift_suggestion_id: suggestion.id }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "POST #bulk_create_from_wishlist" do
    let(:recipient2) do
      Recipient.create!(user: user, name: "Alex", email: "alex@example.com", relationship: "Friend")
    end

    let(:event2) do
      Event.create!(user: user, event_name: "Xmas", event_date: Date.today + 10, budget: 50.0)
    end

    let(:er2) { EventRecipient.create!(user: user, event: event2, recipient: recipient2, budget_allocated: 0) }

    let(:suggestion2) do
      AiGiftSuggestion.create!(
        user: user, event: event2, recipient: recipient2, event_recipient: er2,
        title: "Idea 2", description: "d", round_type: "initial", category: "Tech"
      )
    end

    let(:other_user) { User.create!(name: "Other", email: "other@example.com", password: "Password@123") }

    it "adds only suggestions that are on current_user wishlist and returns created count" do
      # Your Wishlist model requires ai_gift_suggestion (as seen earlier)
      Wishlist.create!(user: user, recipient: recipient, item_name: "W1", ai_gift_suggestion: suggestion)
      Wishlist.create!(user: user, recipient: recipient2, item_name: "W2", ai_gift_suggestion: suggestion2)

      # Not counted: wishlist belongs to someone else
      Wishlist.create!(user: other_user, recipient: recipient, item_name: "W3", ai_gift_suggestion: suggestion)

      bogus = 999_999

      expect {
        post :bulk_create_from_wishlist, params: { ai_gift_suggestion_ids: [suggestion.id, suggestion.id, suggestion2.id, bogus] }
      }.to change(CartItem, :count).by(2)

      expect(response).to redirect_to(cart_path)
      expect(flash[:notice]).to match(/Added 2 item\(s\) to cart\./)
    end

    it "second run does not create duplicates but still counts persisted items" do
      Wishlist.create!(user: user, recipient: recipient, item_name: "W1", ai_gift_suggestion: suggestion)

      post :bulk_create_from_wishlist, params: { ai_gift_suggestion_ids: [suggestion.id] }

      expect {
        post :bulk_create_from_wishlist, params: { ai_gift_suggestion_ids: [suggestion.id] }
      }.not_to change(CartItem, :count)

      # controller increments 'created' if item.persisted? (true for found items too)
      expect(flash[:notice]).to match(/Added 1 item\(s\) to cart\./)
    end
  end

  describe "DELETE #destroy" do
    it "destroys an item from the current_user cart and redirects with notice" do
      request.env["HTTP_REFERER"] = "/somewhere"
      post :create, params: { ai_gift_suggestion_id: suggestion.id }
      item = cart.cart_items.first

      expect {
        delete :destroy, params: { id: item.id }
      }.to change(CartItem, :count).by(-1)

      expect(response).to redirect_to(cart_path)
      expect(flash[:notice]).to eq("Removed from cart.")
    end
  end

  describe "POST #clear" do
    it "clears all items from cart and redirects with notice" do
      request.env["HTTP_REFERER"] = "/somewhere"
      post :create, params: { ai_gift_suggestion_id: suggestion.id }
      expect(cart.cart_items.count).to eq(1)

      post :clear

      expect(response).to redirect_to(cart_path)
      expect(flash[:notice]).to eq("Cart cleared.")
      expect(cart.cart_items.reload.count).to eq(0)
    end
  end
end
