# frozen_string_literal: true
require "rails_helper"

RSpec.describe MessagesController, type: :controller do
  let!(:user)   { create(:user) }
  let!(:friend) { create(:user) }

  before do
    # authenticate_user! stub (NO devise dependency)
    allow(controller).to receive(:authenticate_user!).and_return(true)
    allow(controller).to receive(:current_user).and_return(user)

    # make them friends
    allow(user).to receive(:friend?).with(friend).and_return(true)
    allow(user).to receive(:friends).and_return([friend])
  end

  describe "GET #index" do
    it "loads messages between users" do
      msg = create(:message, sender: user, receiver: friend)

      get :index, params: { friend_id: friend.id }

      expect(assigns(:messages)).to include(msg)
      expect(response).to have_http_status(:ok)
    end

    it "marks unread messages as read" do
      msg = create(:message, sender: friend, receiver: user, read: false)

      get :index, params: { friend_id: friend.id }

      expect(msg.reload.read).to eq(true)
    end
  end

  describe "POST #create" do
    it "creates a new message successfully" do
      expect {
        post :create, params: {
          friend_id: friend.id,
          message: { body: "Hello" }
        }
      }.to change(Message, :count).by(1)

      expect(response).to redirect_to(messages_path(friend_id: friend.id))
    end

    it "returns turbo_stream on success" do
      post :create,
           params: {
             friend_id: friend.id,
             message: { body: "Hi" }
           },
           format: :turbo_stream

      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    end

    it "renders index on validation failure" do
      post :create, params: {
        friend_id: friend.id,
        message: { body: "" }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response).to render_template(:index)
    end

    it "raises error when message param is missing" do
      expect {
        post :create, params: { friend_id: friend.id }
      }.to raise_error(ActionController::ParameterMissing)
    end
  end

  describe "GET #conversations" do
    it "lists only friends with messages" do
      silent_friend = build_stubbed(:user, id: 999)

      allow(user).to receive(:friends).and_return([friend, silent_friend])

      create(:message, sender: user, receiver: friend)

      get :conversations

      expect(assigns(:friends_with_messages)).to include(friend)
      expect(assigns(:friends_with_messages)).not_to include(silent_friend)
    end
  end

  describe "POST #clear" do
    it "soft deletes messages for current user" do
      msg = create(:message, sender: user, receiver: friend)

      post :clear, params: { friend_id: friend.id }

      expect(msg.reload.deleted_by_user_ids).to include(user.id)
      expect(response).to redirect_to(messages_path(friend_id: friend.id))
    end

    it "returns turbo_stream on clear" do
      create(:message, sender: user, receiver: friend)

      post :clear,
           params: { friend_id: friend.id },
           format: :turbo_stream

      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    end
  end

  describe "authorization" do
    it "redirects if friend is not actually a friend" do
      allow(user).to receive(:friend?).with(friend).and_return(false)

      get :index, params: { friend_id: friend.id }

      expect(response).to redirect_to(friendships_path)
      expect(flash[:alert]).to eq("You can only message friends.")
    end
  end
end
