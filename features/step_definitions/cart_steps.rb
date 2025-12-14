# features/step_definitions/cart_steps.rb

def ensure_logged_in_user!
  # Background step "Given I am logged in" should already create a user.
  # But to be safe, find one deterministically.
  @user ||= User.find_by(email: "cuke@example.com") ||
            User.find_by(email: "test@test.com") ||
            User.first ||
            User.create!(
              name: "Cuke User",
              email: "cuke@example.com",
              password: "Password1!",
              password_confirmation: "Password1!"
            )
end

Given("an AI gift suggestion exists") do
  ensure_logged_in_user!

  event = Event.create!(
    user: @user,
    event_name: "Cuke Event",
    event_date: Date.today + 5,
    budget: 100
  )

  recipient = Recipient.create!(
    user: @user,
    name: "Sam",
    email: "sam@example.com",
    relationship: "Friend",
    gender: "Male"
  )

  # Make sure the join exists (some apps validate presence)
  er =
    if defined?(EventRecipient)
      cols = EventRecipient.column_names rescue []
      attrs = { event: event, recipient: recipient }
      attrs[:user] = @user if cols.include?("user_id")
      EventRecipient.create!(attrs)
    end

  @idea = AiGiftSuggestion.create!(
    user: @user,
    event: event,
    recipient: recipient,
    event_recipient: er,
    title: "Shoes",
    description: "Running shoes",
    category: "Fashion",
    estimated_price: "$70"
  )
end

When("I visit the cart page") do
  visit cart_path
end

When("I add that suggestion to the cart") do
  # Direct POST keeps it deterministic and avoids UI coupling
  page.driver.post(cart_items_path, { ai_gift_suggestion_id: @idea.id })
  visit cart_path
end

Given("my cart has at least one item") do
  step "an AI gift suggestion exists"
  cart = Cart.for(@user)
  CartItem.create!(
    cart: cart,
    ai_gift_suggestion: @idea,
    event_id: @idea.event_id,
    recipient_id: @idea.recipient_id,
    quantity: 1
  )
end

When("I clear the cart") do
  page.driver.delete(clear_cart_items_path)
  visit cart_path
end
