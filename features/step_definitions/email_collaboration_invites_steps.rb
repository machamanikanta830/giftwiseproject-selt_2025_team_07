# frozen_string_literal: true

Given("the following users exist:") do |table|
  table.hashes.each do |row|
    user = User.find_or_initialize_by(email: row["email"])
    user.name = row["name"] if user.respond_to?(:name=)

    if user.respond_to?(:password=)
      user.password = row["password"]
      user.password_confirmation = row["password"] if user.respond_to?(:password_confirmation=)
    end

    user.save!
  end
end

Given('I have created an event called {string} on {string}') do |event_name, date_str|
  owner = User.find_by!(email: "alice@example.com")

  attrs = {}

  # your app uses event_name + event_date (based on collaboration_steps.rb)
  attrs["event_name"] = event_name if Event.column_names.include?("event_name")

  parsed = Date.parse(date_str)
  parsed = Date.current + 7 if parsed < Date.current
  attrs["event_date"] = parsed if Event.column_names.include?("event_date")

  attrs["user_id"] = owner.id if Event.column_names.include?("user_id")

  event = Event.new(attrs)
  event.user = owner if event.respond_to?(:user=) && !attrs.key?("user_id")

  # If there are other required fields like budget, set a safe default
  if Event.column_names.include?("budget") && event.budget.blank?
    event.budget = 100
  end

  event.save!
end


When("I log out") do
  # prefer your existing logout route if present
  if respond_to?(:logout_path)
    visit logout_path
  else
    raise "No logout_path helper found"
  end
end

# --- "they ..." aliases (used in invite email flow) ---

Then('they should see {string}') do |text|
  expect(page).to have_content(text)
end

Then('they should be on the login page') do
  # you already use login_path throughout your steps
  expect(current_path).to eq(login_path)
end

When('they press {string}') do |label|
  click_button(label)
end

When('they fill in {string} with {string}') do |field, value|
  # Works for ids/names like "email" and for labels like "Email"
  if page.has_field?(field)
    fill_in field, with: value
  elsif field.downcase == "email" && page.has_field?("Email")
    fill_in "Email", with: value
  elsif field.downcase == "password" && page.has_field?("Password")
    fill_in "Password", with: value
  else
    # Last attempt: try exact anyway (Capybara will raise a useful error)
    fill_in field, with: value
  end
end

Then('they should be on the event page for {string}') do |event_name|
  name_col = (Event.column_names & %w[event_name name title]).first
  event = Event.find_by!(name_col => event_name)
  expect(current_path).to eq(event_path(event))
end
