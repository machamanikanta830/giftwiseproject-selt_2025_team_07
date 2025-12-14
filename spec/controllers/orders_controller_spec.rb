require "rails_helper"

RSpec.describe OrdersController, type: :controller do
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

  let(:ai_gift_suggestion) do
    create(
      :ai_gift_suggestion,
      user: user,
      event: event,
      recipient: recipient,
      title: "Watch"
    )
  end

  let(:cart) { Cart.for(user) }

  let(:cart_item) do
    create(
      :cart_item,
      cart: cart,
      ai_gift_suggestion: ai_gift_suggestion,
      recipient: recipient,
      event: event,
      quantity: 1
    )
  end

  let(:order) do
    create(
      :order,
      user: user,
      status: "placed",
      placed_at: Time.current
    )
  end

  let!(:order_item) do
    create(
      :order_item,
      order: order,
      ai_gift_suggestion: ai_gift_suggestion,
      recipient: recipient,
      event: event,
      title: "Watch"
    )
  end

  before do
    allow(controller).to receive(:authenticate_user!).and_return(true)
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe "GET index" do
    it "loads orders index" do
      order

      get :index

      expect(response).to have_http_status(:success)
      expect(assigns(:orders)).to include(order)
    end
  end

  describe "GET show" do
    it "shows order details" do
      get :show, params: { id: order.id }

      expect(response).to have_http_status(:success)
      expect(assigns(:items)).to be_present
    end
  end

  describe "POST create" do
    context "when cart is empty" do
      it "redirects with alert" do
        cart.cart_items.delete_all

        post :create

        expect(response).to redirect_to(cart_path)
        expect(flash[:alert]).to eq("Your cart is empty.")
      end
    end

    context "when cart has items" do
      it "creates order and order items" do
        cart_item

        expect {
          post :create, params: {
            delivery_address: "123 Street",
            delivery_phone: "1234567890"
          }
        }.to change(Order, :count).by(1)

        expect(response).to redirect_to(Order.last)
        expect(cart.cart_items.count).to eq(0)
      end
    end
  end

  describe "POST cancel" do
    it "cancels placed order" do
      post :cancel, params: { id: order.id }

      expect(response).to redirect_to(order_path(order))
      expect(order.reload.status).to eq("cancelled")
    end

    it "does not cancel non placed order" do
      order.update!(status: "delivered")

      post :cancel, params: { id: order.id }

      expect(response).to redirect_to(order_path(order))
      expect(flash[:alert]).to eq("This order cannot be cancelled.")
    end
  end

  describe "POST deliver" do
    it "marks order delivered and creates gift backlog" do
      expect {
        post :deliver, params: { id: order.id }
      }.to change(GiftGivenBacklog, :count).by(1)

      expect(order.reload.status).to eq("delivered")
      expect(response).to redirect_to(order_path(order))
    end

    it "does not deliver non placed order" do
      order.update!(status: "cancelled")

      post :deliver, params: { id: order.id }

      expect(response).to redirect_to(order_path(order))
      expect(flash[:alert]).to eq("This order cannot be marked delivered.")
    end
  end
end
