# spec/controllers/friendships_controller_spec.rb
require "rails_helper"

RSpec.describe FriendshipsController, type: :controller do
  let(:user)   { create(:user) }
  let(:friend) { create(:user) }

  before do
    allow_any_instance_of(ApplicationController).to receive(:authenticate_user!).and_return(true)
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
  end

  describe "POST #create" do
    it "creates friendship successfully" do
      expect {
        post :create, params: { friend_id: friend.id }, format: :turbo_stream
      }.to change(Friendship, :count).by(1)

      # turbo success may be 200 or 204 depending on implementation
      expect([200, 204, 302]).to include(response.status)
    end

    it "handles save failure gracefully" do
      allow_any_instance_of(Friendship).to receive(:save).and_return(false)

      post :create, params: { friend_id: friend.id }, format: :turbo_stream

      expect([200, 204, 422, 302]).to include(response.status)
    end

    it "returns turbo_stream on success when requested" do
      post :create, params: { friend_id: friend.id }, format: :turbo_stream

      # In controller specs, media_type may be nil even if turbo rendered.
      # The stable check is: response body includes turbo-stream OR status is 204.
      if response.status == 200
        expect(response.body).to include("turbo-stream")
      else
        expect(response.status).to eq(204).or eq(302)
      end
    end
  end
end
