require 'rails_helper'

RSpec.describe HomeController, type: :controller do
  describe "GET #index" do
    context "when no user is logged in" do
      it "renders the index template" do
        get :index

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:index)
      end
    end

    context "when a user is logged in" do
      let(:user) do
        User.create!(
          name: "Test User",
          email: "user@example.com",
          password: "Password1!"
        )
      end

      before do
        # assuming ApplicationController#current_user uses session[:user_id]
        session[:user_id] = user.id
      end

      it "redirects to the dashboard" do
        get :index

        expect(response).to redirect_to(dashboard_path)
      end
    end
  end
end
