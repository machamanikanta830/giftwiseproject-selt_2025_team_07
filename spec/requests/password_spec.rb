require "rails_helper"

RSpec.describe "Passwords", type: :request do
  let(:user) do
    User.create!(
      name: "Test User",
      email: "test@example.com",
      password: "Password1!"
    )
  end

  before do
    post login_path, params: { email: user.email, password: "Password1!" }
  end

  describe "GET /password/edit" do
    it "renders the edit template" do
      get edit_password_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Change Password")
    end
  end

  describe "PATCH /password" do
    it "updates the password with valid params" do
      patch password_path, params: {
        user: {
          password: "NewPass1!",
          password_confirmation: "NewPass1!"
        }
      }

      expect(response).to redirect_to(dashboard_path)
      follow_redirect!
      expect(response.body).to include("Password updated successfully")
    end

    it "re-renders when confirmation does not match" do
      patch password_path, params: {
        user: {
          password: "NewPass1!",
          password_confirmation: "WrongPass1!"
        }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Password confirmation")
    end
  end
end
