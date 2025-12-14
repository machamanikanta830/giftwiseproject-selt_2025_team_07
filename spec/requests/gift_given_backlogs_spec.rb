require "rails_helper"

RSpec.describe GiftGivenBacklogsController, type: :request do
  let!(:user) do
    User.create!(
      name: "Test User",
      email: "test-#{SecureRandom.hex(6)}@example.com",
      password: "Password@1",
      password_confirmation: "Password@1"
    )
  end

  let!(:recipient) do
    Recipient.create!(
      user: user,
      name: "Sam",
      relationship: "Friend",
      email: "sam-#{SecureRandom.hex(6)}@example.com"
    )
  end

  before do
    allow_any_instance_of(ApplicationController).to receive(:authenticate_user!).and_return(true)
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
  end

  let(:valid_params) do
    {
      gift_given_backlog: {
        gift_name: "Book",
        price: 10
      }
    }
  end

  describe "GET /recipients/:recipient_id/gift_given_backlogs/new" do
    it "renders the new template successfully" do
      get new_recipient_gift_given_backlog_path(recipient)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /recipients/:recipient_id/gift_given_backlogs" do
    it "creates a gift_given_backlog and redirects on success" do
      post recipient_gift_given_backlogs_path(recipient), params: valid_params
      expect(response).to have_http_status(:found).or have_http_status(:see_other)
    end

    it "re-renders new with unprocessable_content when save fails" do
      invalid_params = { gift_given_backlog: { gift_name: "" } }

      post recipient_gift_given_backlogs_path(recipient), params: invalid_params
      expect(response).to have_http_status(:unprocessable_content).or have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE /recipients/:recipient_id/gift_given_backlogs/:id" do
    let!(:backlog) do
      GiftGivenBacklog.create!(
        user: user,
        recipient: recipient,
        gift_name: "Old Gift",
        price: 5
      )
    end

    it "destroys the record and returns turbo_stream when requested" do
      delete recipient_gift_given_backlog_path(recipient, backlog),
             headers: { "ACCEPT" => "text/vnd.turbo-stream.html" }

      expect(response).to have_http_status(:ok)
      expect(GiftGivenBacklog.exists?(backlog.id)).to eq(false)
    end

    it "destroys the record and redirects for HTML requests" do
      delete recipient_gift_given_backlog_path(recipient, backlog)

      expect(response).to redirect_to(/.*/)
      expect(GiftGivenBacklog.exists?(backlog.id)).to eq(false)
    end
  end
end
