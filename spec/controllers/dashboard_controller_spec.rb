# spec/controllers/dashboard_controller_spec.rb
require 'rails_helper'

RSpec.describe DashboardController, type: :controller do
  # Test user used across examples
  let(:user) do
    User.create!(
      name:  "Test User",
      email: "user@example.com",
      password: "Password1!"
    )
  end

  describe "GET #index" do
    context "when not logged in" do
      it "redirects to login" do
        get :index

        # adjust this if your authenticate_user! redirects somewhere else
        expect(response).to redirect_to(login_path)
      end
    end

    context "when logged in" do
      before do
        session[:user_id] = user.id
      end

      it "is successful" do
        get :index

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:index)
      end

      it "assigns at most 3 upcoming events for the current user in date order" do
        # all valid future events (your model disallows past dates)
        user.events.create!(
          event_name: "Soon Event",
          event_date: Date.today + 1,
          budget: 50
        )
        user.events.create!(
          event_name: "Later Event",
          event_date: Date.today + 10,
          budget: 100
        )
        user.events.create!(
          event_name: "Much Later Event",
          event_date: Date.today + 20,
          budget: 200
        )
        user.events.create!(
          event_name: "Too Many Event",
          event_date: Date.today + 30,
          budget: 300
        )

        get :index

        upcoming = assigns(:upcoming_events)

        expect(upcoming.size).to eq(3)
        expect(upcoming).to match_array(user.events.upcoming.limit(3))
      end
    end
  end
end
