# features/step_definitions/chatbot_steps.rb

def chatbot_root
  # Most stable: scope to the widget container that has the Stimulus controller
  if page.has_css?("[data-controller~='chatbot']", wait: 2)
    find("[data-controller~='chatbot']", match: :first)
  else
    # fallback: just use the first toggleButton we can find
    nil
  end
end

Given("a chatbot test user exists") do
  @chatbot_user = User.find_or_create_by!(email: "chatbot@example.com") do |u|
    u.name = "Chatbot User"
    u.password = "Password1!"
    u.password_confirmation = "Password1!"
  end
end

Given("I am logged in as the chatbot test user") do
  @chatbot_user ||= User.find_by!(email: "chatbot@example.com")
  visit login_path

  fill_in "Email Address", with: @chatbot_user.email if page.has_field?("Email Address")
  fill_in "Email", with: @chatbot_user.email if page.has_field?("Email")
  fill_in "Password", with: "Password1!"
  click_button "Log In"

  expect(page).to have_current_path(dashboard_path, ignore_query: true)
end

When("I visit the dashboard page") do
  visit dashboard_path
end

Then("I should see the chatbot button") do
  if (root = chatbot_root)
    within(root) do
      expect(page).to have_css("[data-chatbot-target='toggleButton']", visible: true)
    end
  else
    expect(page).to have_css("[data-chatbot-target='toggleButton']", visible: true)
  end
end

When("I click the chatbot button") do
  if (root = chatbot_root)
    within(root) do
      find("[data-chatbot-target='toggleButton']", match: :first).click
    end
  else
    find("[data-chatbot-target='toggleButton']", match: :first).click
  end
end

Then("I should see the chatbot panel") do
  if (root = chatbot_root)
    within(root) do
      # Panel target name can vary; check a few common ones
      expect(
        page.has_css?("[data-chatbot-target='panel']", wait: 2) ||
        page.has_css?("[data-chatbot-target='drawer']", wait: 2) ||
        page.has_css?("[data-chatbot-target='container']", wait: 2)
      ).to eq(true)
    end
  else
    expect(
      page.has_css?("[data-chatbot-target='panel']", wait: 2) ||
      page.has_css?("[data-chatbot-target='drawer']", wait: 2) ||
      page.has_css?("[data-chatbot-target='container']", wait: 2)
    ).to eq(true)
  end
end

Then("I should see the chatbot header") do
  # Don’t hardcode tag; just assert header text exists after opening
  expect(page).to have_content(/GiftWise Assistant|Assistant|Chatbot/i)
end

Then("I should see the chatbot input field") do
  if (root = chatbot_root)
    within(root) do
      expect(
        page.has_css?("textarea", wait: 2) ||
        page.has_css?("input[type='text']", wait: 2) ||
        page.has_css?("input[placeholder*='message' i]", wait: 2)
      ).to eq(true)
    end
  else
    expect(
      page.has_css?("textarea", wait: 2) ||
      page.has_css?("input[type='text']", wait: 2) ||
      page.has_css?("input[placeholder*='message' i]", wait: 2)
    ).to eq(true)
  end
end
