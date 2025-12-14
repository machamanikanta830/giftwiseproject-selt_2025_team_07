# frozen_string_literal: true

Given("there is an event {string} owned by {string} happening in {int} days") do |event_name, owner_email, days|
  owner = User.find_by!(email: owner_email)
  Event.create!(
    user: owner,
    event_name: event_name,
    event_date: Date.current + days
  )
end

Given("the event {string} has a recipient {string}") do |event_name, recipient_name|
  event = Event.find_by!(event_name: event_name)

  owner = event.user

  email = "#{recipient_name.downcase.gsub(/[^a-z0-9]+/, '')}@example.com"

  recipient = Recipient.create!(
    user: owner,
    name: recipient_name,
    email: email,
    relationship: "Friend",
    gender: "Female"
  )

  # Create join row (your schema seems to have user_id on EventRecipient)
  EventRecipient.create!(
    event: event,
    recipient: recipient,
    user: owner
  )
end

Given("{string} is an accepted {string} collaborator on event {string}") do |email, role, event_name|
  user = User.find_by!(email: email)
  event = Event.find_by!(event_name: event_name)

  Collaborator.create!(
    event: event,
    user: user,
    role: role,
    status: Collaborator::STATUS_ACCEPTED
  )
end

Given("{string} is a pending {string} collaborator on event {string}") do |email, role, event_name|
  user = User.find_by!(email: email)
  event = Event.find_by!(event_name: event_name)

  Collaborator.create!(
    event: event,
    user: user,
    role: role,
    status: Collaborator::STATUS_PENDING
  )
end

When("I log in as {string} with password {string}") do |email, password|
  visit login_path
  fill_in "Email", with: email
  fill_in "Password", with: password
  click_button "Log In"
end

When("I go to the dashboard") do
  visit dashboard_path
end

When("I visit the event page for {string}") do |event_name|
  event = Event.find_by!(event_name: event_name)
  visit event_path(event)
end

When("I open the event {string} from the dashboard") do |event_name|
  # Dashboard rows are clickable via JS onclick; easiest stable way is direct visit.
  event = Event.find_by!(event_name: event_name)
  visit event_path(event, from: "dashboard")
end

Then("the {string} action should be disabled") do |label|
  # In your event show, disabled Get Ideas is a <button disabled>Get Ideas</button>
  expect(page).to have_selector("button[disabled]", text: label)
end

When("I accept the collaboration for {string} on event {string}") do |email, event_name|
  user = User.find_by!(email: email)
  event = Event.find_by!(event_name: event_name)

  collab = Collaborator.find_by!(user: user, event: event, status: Collaborator::STATUS_PENDING)

  # We don't depend on the Collaboration Requests view HTML.
  # We hit the controller endpoint directly (RackTest driver).
  page.driver.submit :post, accept_collaboration_request_path(collab.id), {}
end

When('I fill in {string} with {string}') do |field, value|
  fill_in field, with: value
end

When('I select {string} from {string}') do |value, field|
  select value, from: field
end

When('I press {string}') do |button|
  click_button button
end

Then('{string} should receive an email') do |email|
  expect(ActionMailer::Base.deliveries.map(&:to).flatten).to include(email)
end

Then('{string} should receive an email with subject {string}') do |email, subject|
  mail = ActionMailer::Base.deliveries.find { |m| m.to.include?(email) }
  expect(mail).not_to be_nil
  expect(mail.subject).to eq(subject)
end

When('{string} opens the email') do |email|
  @current_email = ActionMailer::Base.deliveries.find { |m| m.to.include?(email) }
  expect(@current_email).not_to be_nil
end

When('they click the {string} link in the email') do |link_text|
  expect(@current_email).not_to be_nil
  html_body = @current_email.html_part.body.to_s
  doc = Nokogiri::HTML(html_body)
  link = doc.css('a').find { |a| a.text.include?(link_text) }
  expect(link).not_to be_nil
  visit link['href']
end

When('they click {string}') do |link_text|
  click_link link_text
end

When('they fill in the following:') do |table|
  table.rows_hash.each do |field, value|
    fill_in field, with: value
  end
end

When('{int} days pass') do |days|
  travel days.days
end

After do
  travel_back
end