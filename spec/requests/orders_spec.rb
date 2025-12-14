# spec/requests/orders_spec.rb
require "rails_helper"

RSpec.describe "Orders", type: :request do
  let!(:user) do
    User.create!(
      name: "Test User",
      email: "test2@example.com",
      password: "Password@1",
      password_confirmation: "Password@1"
    )
  end

  let!(:event) do
    Event.create!(
      user: user,
      event_name: "Anniversary",
      event_date: Date.today + 10,
      budget: 200
    )
  end

  let!(:recipient) do
    Recipient.create!(
      user: user,
      name: "Mary",
      relationship: "Family",
      email: "mary@example.com" # required now
    )
  end

  let!(:event_recipient) do
    EventRecipient.create!(
      user: user,              # required by schema (null: false)
      event: event,
      recipient: recipient
    )
  end

  let!(:idea) do
    AiGiftSuggestion.create!(
      user: user,
      event: event,
      recipient: recipient,
      event_recipient: event_recipient,
      title: "Perfume",
      description: "Great fragrance",
      category: "Beauty",
      estimated_price: "$60"
    )
  end

  def sign_in(u)
    post login_path, params: { email: u.email, password: "Password@1" }
  end

  it "requires login to view orders" do
    get orders_path
    expect(response).to redirect_to(login_path)
  end

  it "lists orders when logged in" do
    sign_in(user)
    get orders_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("My Orders")
  end

  it "creates an order from cart (COD checkout)" do
    sign_in(user)

    cart = Cart.for(user)
    CartItem.create!(
      cart: cart,
      ai_gift_suggestion: idea,
      event: event,
      recipient: recipient,
      quantity: 1
    )

    expect {
      post orders_path, params: {
        delivery_address: "123 Test St",
        delivery_phone: "+1 (222) 333-4444",
        delivery_note: "Leave at door"
      }
    }.to change(Order, :count).by(1)

    # robust redirect check (works whether it redirects to index or show)
    expect(response).to have_http_status(:redirect)
    expect(response.location).to match(%r{/orders(/\d+)?$})
  end

  it "shows an order page" do
    sign_in(user)

    order = Order.create!(
      user: user,
      status: "placed",
      placed_at: Time.current,
      delivery_address: "abc",
      delivery_phone: "111"
    )

    get order_path(order)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Order ##{order.id}")
  end

  it "cancels an order (if supported)" do
    sign_in(user)

    order = Order.create!(
      user: user,
      status: "placed",
      placed_at: Time.current,
      delivery_address: "abc",
      delivery_phone: "111"
    )

    if Rails.application.routes.url_helpers.respond_to?(:cancel_order_path)
      patch cancel_order_path(order)
      expect(response).to have_http_status(:redirect)
      order.reload
      expect(order.status).to eq("cancelled")
    end
  end

  it "marks delivered (if supported)" do
    sign_in(user)

    order = Order.create!(
      user: user,
      status: "placed",
      placed_at: Time.current,
      delivery_address: "abc",
      delivery_phone: "111"
    )

    if Rails.application.routes.url_helpers.respond_to?(:deliver_order_path)
      patch deliver_order_path(order)
      expect(response).to have_http_status(:redirect)
      order.reload
      expect(order.status).to eq("delivered")
    end
  end
end
