# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Friendships", type: :request do
  let(:user)   { create(:user) }
  let(:friend) { create(:user) }

  before do
    # Bypass authentication
    allow_any_instance_of(ApplicationController)
      .to receive(:authenticate_user!)
            .and_return(true)

    # Stub current_user
    allow_any_instance_of(ApplicationController)
      .to receive(:current_user)
            .and_return(user)
  end

  # ---------------------------------------------------------
  # GET /friendships
  # ---------------------------------------------------------
  describe "GET /friendships" do
    it "loads the friendships index page successfully" do
      get friendships_path
      expect(response).to have_http_status(:success)
    end
  end

  # ---------------------------------------------------------
  # POST /friendships
  # ---------------------------------------------------------
  describe "POST /friendships" do
    it "creates a pending friendship request" do
      expect {
        post friendships_path, params: { friend_id: friend.id }
      }.to change(Friendship, :count).by(1)

      friendship = Friendship.last
      expect(friendship.user).to eq(user)
      expect(friendship.friend).to eq(friend)
      expect(friendship.status).to eq("pending")
    end
  end

  # ---------------------------------------------------------
  # PATCH /friendships/:id/accept
  # ---------------------------------------------------------
  describe "PATCH /friendships/:id/accept" do
    let!(:incoming_request) do
      create(
        :friendship,
        user: friend,
        friend: user,
        status: "pending"
      )
    end

    it "accepts the friendship and creates reverse friendship" do
      expect {
        patch accept_friendship_path(incoming_request)
      }.to change(Friendship, :count).by(1)

      expect(incoming_request.reload.status).to eq("accepted")

      reverse = Friendship.find_by(
        user_id: user.id,
        friend_id: friend.id
      )

      expect(reverse).to be_present
      expect(reverse.status).to eq("accepted")
    end
  end

  # ---------------------------------------------------------
  # DELETE /friendships/:id/reject
  # ---------------------------------------------------------
  describe "DELETE /friendships/:id/reject" do
    let!(:incoming_request) do
      create(
        :friendship,
        user: friend,
        friend: user,
        status: "pending"
      )
    end

    it "rejects and deletes the friendship request" do
      expect {
        delete reject_friendship_path(incoming_request)
      }.to change(Friendship, :count).by(-1)
    end
  end

  # ---------------------------------------------------------
  # DELETE /friendships/:id (unfriend)
  # ---------------------------------------------------------
  describe "DELETE /friendships/:id" do
    let!(:friendship) do
      create(
        :friendship,
        user: user,
        friend: friend,
        status: "accepted"
      )
    end

    let!(:reverse_friendship) do
      create(
        :friendship,
        user: friend,
        friend: user,
        status: "accepted"
      )
    end

    it "destroys both friendships" do
      expect {
        delete friendship_path(friendship)
      }.to change(Friendship, :count).by(-2)
    end
  end

  # ---------------------------------------------------------
  # DELETE /friendships/:id - RecordNotFound
  # ---------------------------------------------------------
  describe "DELETE /friendships/:id when record does not exist" do
    it "handles RecordNotFound gracefully" do
      delete friendship_path(999_999)
      expect(response).to redirect_to(friendships_path)
    end
  end
end
