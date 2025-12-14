class WishlistsController < ApplicationController
  before_action :authenticate_user!

  def index
    # AI gift suggestions saved by the current user
    @wishlist_items = AiGiftSuggestion
                        .joins(:wishlists)
                        .where(wishlists: { user_id: current_user.id })
                        .includes(:event, :recipient)
                        .order("wishlists.created_at DESC")
                        .distinct
  end

  def move_to_cart
    wishlist = current_user.wishlists.find(params[:id])
    idea = wishlist.ai_gift_suggestion

    CartItem.find_or_create_by!(
      cart: Cart.for(current_user),
      ai_gift_suggestion: idea
    ) do |ci|
      ci.event_id = idea.event_id
      ci.recipient_id = idea.recipient_id
      ci.quantity = 1
    end

    wishlist.destroy!

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to wishlists_path, notice: "Moved to cart." }
    end
  end
end