# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Wishlists", type: :request do
  let!(:user) { create(:user) }
  let!(:event) { create(:event, user: user) }
  let!(:recipient) { create(:recipient, user: user) }

  let!(:ai_gift_suggestion) do
    create(
      :ai_gift_suggestion,
      user: user,
      event: event,
      recipient: recipient,
      estimated_price: "$25 - $75"
    )
  end

  let!(:wishlist) do
    create(
      :wishlist,
      user: user,
      ai_gift_suggestion: ai_gift_suggestion,
      recipient: recipient
    )
  end

  # ------------------------------------------------------------
  # AUTH STUB (same pattern used everywhere else)
  # ------------------------------------------------------------
  before do
    allow_any_instance_of(ApplicationController)
      .to receive(:authenticate_user!)
            .and_return(true)

    allow_any_instance_of(ApplicationController)
      .to receive(:current_user)
            .and_return(user)
  end

  # ------------------------------------------------------------
  # INDEX
  # ------------------------------------------------------------
  describe "GET /wishlists" do
    it "loads the wishlist page" do
      get wishlists_path
      expect(response).to have_http_status(:ok)
    end
  end

  # ------------------------------------------------------------
  # MOVE TO CART
  # ------------------------------------------------------------
  describe "POST /wishlists/:id/move_to_cart" do
    it "moves wishlist item to cart and removes it from wishlist" do
      expect do
        post move_to_cart_wishlist_path(wishlist)
      end.to change(Wishlist, :count).by(-1)

      cart = Cart.for(user)
      expect(cart.cart_items.count).to eq(1)

      expect(response).to redirect_to(wishlists_path)
    end
  end
end
