# features/step_definitions/ai_gift_suggestions_steps_nodup.rb

Given('I have an event {string} with a recipient {string}') do |event_name, recipient_name|
  # Background has already created the user with this email and logged you in
  user = User.find_by!(email: "test@example.com")

  event = user.events.create!(
    event_name: event_name,
    event_date: Date.today + 7.days,
    budget: 120
  )

  recipient = user.recipients.create!(
    name:         recipient_name,
    relationship: "Friend",
    age:          25,
    hobbies:      "Reading",
    likes:        "Books",
    dislikes:     "None"
  )

  EventRecipient.create!(
    user:            user,
    event:           event,
    recipient:       recipient,
    budget_allocated: 60
  )

  @current_user = user
  @event        = event
  @recipient    = recipient
end

Given('AI gift suggestions already exist for {string} on {string}:') do |recipient_name, event_name, table|
  user  = @current_user || User.find_by!(email: "test@example.com")
  event = @event || user.events.find_by!(event_name: event_name)
  recipient = @recipient || user.recipients.find_by!(name: recipient_name)

  event_recipient = EventRecipient.find_by!(
    user:      user,
    event:     event,
    recipient: recipient
  )

  table.hashes.each do |row|
    AiGiftSuggestion.create!(
      user:            user,
      event:           event,
      recipient:       recipient,
      event_recipient: event_recipient,
      title:           row.fetch("title"),
      description:     "Existing suggestion for testing",
      estimated_price: "$10–$20",
      category:        "Test",
      special_notes:   nil,
      round_type:      "initial"
    )
  end

  @event_recipient = event_recipient
end

When('I go to the AI gift suggestions page for {string}') do |event_name|
  user  = @current_user || User.find_by!(email: "test@example.com")
  event = user.events.find_by!(event_name: event_name)

  visit event_ai_gift_suggestions_path(event)
end

When('I click {string} for {string}') do |_button_text, recipient_name|
  user  = @current_user || User.find_by!(email: "test@example.com")
  event = @event || user.events.first
  recipient = @recipient || user.recipients.find_by!(name: recipient_name)

  event_recipient = @event_recipient || EventRecipient.find_by!(
    user:      user,
    event:     event,
    recipient: recipient
  )

  # Simulate clicking the "Regenerate ideas" button by posting directly
  # to the AiGiftSuggestionsController#create action with round_type=regenerate
  page.driver.submit :post, event_ai_gift_suggestions_path(event), {
    recipient_id: event_recipient.recipient_id,
    round_type:   "regenerate",
    from:         nil
  }

  # After regenerate, the app redirects back to the AI suggestions page,
  # so we visit it again to reflect the new state.
  visit event_ai_gift_suggestions_path(event)
end


Then('I should see {int} AI gift ideas for {string}') do |expected_count, recipient_name|
  user  = @current_user || User.find_by!(email: "test@example.com")
  event = @event || user.events.first
  recipient = user.recipients.find_by!(name: recipient_name)

  event_recipient = @event_recipient || EventRecipient.find_by!(
    user:      user,
    event:     event,
    recipient: recipient
  )

  # Only count the newly regenerated ideas, not the old initial ones
  count = AiGiftSuggestion.where(
    event_recipient: event_recipient,
    round_type:      "regenerate"
  ).count

  expect(count).to eq(expected_count)
end

