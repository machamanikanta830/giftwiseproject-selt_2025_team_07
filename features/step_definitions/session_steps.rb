# features/step_definitions/session_steps.rb

Given("I am logged in") do
  email = "cuke@example.com"
  password = "Password@1"

  @user = User.find_or_create_by!(email: email) do |u|
    u.name = "Cuke User"
    u.password = password
    u.password_confirmation = password
  end

  visit login_path

  if page.has_field?("Email Address")
    fill_in "Email Address", with: email
  elsif page.has_field?("Email")
    fill_in "Email", with: email
  else
    fill_in "email", with: email
  end

  if page.has_field?("Password")
    fill_in "Password", with: password
  else
    fill_in "password", with: password
  end

  click_button "Log In"
end
