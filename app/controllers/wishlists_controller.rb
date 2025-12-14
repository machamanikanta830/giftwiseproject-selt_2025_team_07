class WishlistsController < ApplicationController
  before_action :authenticate_user!

  def index
    @wishlist_items =
      AiGiftSuggestion
        .joins(:wishlists)
        .where(wishlists: { user_id: current_user.id })
        .select("ai_gift_suggestions.*, wishlists.id AS wishlist_id, wishlists.created_at AS wishlist_created_at")
        .includes(:event, :recipient)
        .order("wishlists.created_at DESC")
        .distinct
  end

  def move_to_cart
    wishlist = current_user.wishlists.find(params[:id])
    idea = wishlist.ai_gift_suggestion
    cart = Cart.for(current_user)

    avg_price = idea.average_estimated_price

    item = CartItem.find_or_create_by!(
      cart: cart,
      ai_gift_suggestion: idea
    ) do |ci|
      ci.event_id = idea.event_id
      ci.recipient_id = idea.recipient_id
      ci.quantity = 1
      ci.unit_price = avg_price
    end

    if item.unit_price.nil? && avg_price.present?
      item.update!(unit_price: avg_price)
    end

    wishlist.destroy!

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to wishlists_path, notice: "Moved to cart." }
    end
  end
end
