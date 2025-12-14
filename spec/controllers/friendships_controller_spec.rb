# frozen_string_literal: true
require "rails_helper"

RSpec.describe FriendshipsController, type: :controller do
  let(:user)   { create(:user) }
  let(:friend) { create(:user) }

  before do
    allow(controller).to receive(:authenticate_user!).and_return(true)
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe "GET index" do
    it "loads index successfully" do
      get :index
      expect(response).to have_http_status(:ok)
    end

    it "excludes current user and existing friends from potential friends" do
      create(:friendship, user: user, friend: friend, status: "accepted")
      create(:friendship, user: friend, friend: user, status: "accepted")

      get :index

      expect(assigns(:potential_friends)).not_to include(user)
      expect(assigns(:potential_friends)).not_to include(friend)
    end
  end

  describe "POST create" do
    it "creates friendship successfully" do
      post :create, params: { friend_id: friend.id }

      expect(response).to redirect_to(friendships_path)
      expect(flash[:success]).to include("Friend request sent")
    end

    it "handles save failure gracefully" do
      allow_any_instance_of(Friendship).to receive(:save).and_return(false)

      post :create, params: { friend_id: friend.id }

      expect(response).to redirect_to(friendships_path)
      expect(flash[:error]).to eq("Failed to send friend request")
    end

    it "returns turbo_stream on success" do
      post :create, params: { friend_id: friend.id }, format: :turbo_stream

      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    end
  end

  describe "POST accept" do
    let!(:friendship) do
      create(:friendship, user: friend, friend: user, status: "pending")
    end

    it "accepts the friendship" do
      post :accept, params: { id: friendship.id }

      expect(response).to redirect_to(friendships_path)
      expect(flash[:success]).to include("now friends")
    end

    it "handles update failure" do
      allow_any_instance_of(Friendship).to receive(:update).and_return(false)

      post :accept, params: { id: friendship.id }

      expect(response).to redirect_to(friendships_path)
      expect(flash[:error]).to eq("Failed to accept friend request")
    end
  end

  describe "POST reject" do
    let!(:friendship) do
      create(:friendship, user: friend, friend: user, status: "pending")
    end

    it "rejects the friendship" do
      post :reject, params: { id: friendship.id }

      expect(response).to redirect_to(friendships_path)
      expect(flash[:success]).to eq("Friend request rejected")
    end

    it "handles destroy failure" do
      allow_any_instance_of(Friendship).to receive(:destroy).and_return(false)

      post :reject, params: { id: friendship.id }

      expect(response).to redirect_to(friendships_path)
      expect(flash[:error]).to eq("Failed to reject friend request")
    end
  end

  describe "DELETE destroy" do
    let!(:friendship) do
      create(:friendship, user: user, friend: friend, status: "accepted")
    end

    let!(:reverse_friendship) do
      create(:friendship, user: friend, friend: user, status: "accepted")
    end

    it "destroys both friendships" do
      delete :destroy, params: { id: friendship.id }

      expect(response).to redirect_to(friendships_path)
      expect(flash[:success]).to include("Removed")
    end

    it "handles RecordNotFound gracefully" do
      delete :destroy, params: { id: 999_999 }

      expect(response).to redirect_to(friendships_path)
      expect(flash[:error]).to eq("Friendship not found")
    end

    it "returns turbo_stream format" do
      delete :destroy, params: { id: friendship.id }, format: :turbo_stream

      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    end
  end
end
