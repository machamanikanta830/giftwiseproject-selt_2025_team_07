#features/step_definitions/recipient_steps.rb
def unique_email_for(name)
  "#{name.downcase.gsub(/\s+/, '_')}_#{SecureRandom.hex(4)}@example.com"
end

When("I visit the recipients page") do
  visit recipients_path
end

Then("I should see the list of my recipients") do
  expect(page).to have_content("Recipients")
end

When("I visit the new recipient page") do
  visit new_recipient_path
end


When("I edit the recipient {string}") do |name|
  rec = Recipient.find_by(name: name)
  visit edit_recipient_path(rec)
end

When("I delete the recipient {string}") do |name|
  visit recipients_path
  expect(page).to have_content(name)

  first(:link_or_button, "Remove").click
end

Given("I am on the new recipient page") do
  visit new_recipient_path
end


When("I submit the updated recipient form") do
  begin
    click_button "Save Recipient"
  rescue Capybara::ElementNotFound
    begin
      click_button "Update Recipient"
    rescue Capybara::ElementNotFound
      click_button "Submit"
    end
  end
end