# features/step_definitions/ai_gift_suggestions_steps_nodup.rb

# ---------- Shared setup ----------
def ensure_test_user!
  @user = User.find_or_create_by!(email: "test@example.com") do |u|
    u.name = "Test User"
    u.password = "Password1!"
    u.password_confirmation = "Password1!"
  end
end

Given("I have an event {string} with a recipient {string}") do |event_name, recipient_name|
  ensure_test_user!

  @event = Event.create!(
    user: @user,
    event_name: event_name,
    event_date: Date.today + 10,
    budget: 100
  )

  email = "#{recipient_name.downcase.gsub(/\s+/, '')}@example.com"

  @recipient = Recipient.create!(
    user: @user,
    name: recipient_name,
    email: email,
    relationship: "Friend",
    gender: "Male"
  )

  EventRecipient.create!(
    user: @user,
    event: @event,
    recipient: @recipient
  )
end


