# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Cart", type: :request do
  let!(:user) { create(:user) }

  before do
    # Auth stub (same pattern used elsewhere)
    allow_any_instance_of(ApplicationController)
      .to receive(:authenticate_user!)
            .and_return(true)

    allow_any_instance_of(ApplicationController)
      .to receive(:current_user)
            .and_return(user)
  end

  describe "GET /cart" do
    it "loads the cart page" do
      get cart_path
      expect(response).to have_http_status(:ok)
    end
  end
end
