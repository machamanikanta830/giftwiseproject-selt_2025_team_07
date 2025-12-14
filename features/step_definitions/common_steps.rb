# features/step_definitions/common_steps.rb

Then('I should see {string}') do |text|
  expect(page).to have_content(text)
end

Then('I should not see {string}') do |text|
  expect(page).not_to have_content(text)
end

When('I press {string}') do |label|
  click_link_or_button(label, match: :first)
end
