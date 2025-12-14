# spec/support/controller_helpers.rb
# Add this file to spec/support/ and ensure it's required in rails_helper.rb

module ControllerHelpers
  # Sign in helper for controller tests
  def sign_in(user)
    session[:user_id] = user.id
  end

  # Sign out helper
  def sign_out
    session[:user_id] = nil
  end
end

# Include in rails_helper.rb:
# RSpec.configure do |config|
#   config.include ControllerHelpers, type: :controller
# end