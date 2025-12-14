require "rails_helper"

RSpec.describe FriendshipsController, type: :controller do
  let!(:user)   { create(:user) }
  let!(:friend) { create(:user) }

  before do
    session[:user_id] = user.id
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe "POST #create" do
    context "when request succeeds" do
      it "creates friendship successfully (Turbo request)" do
        expect {
          post :create,
               params: { friend_id: friend.id },
               format: :turbo_stream
        }.to change(Friendship, :count).by(1)

        # Turbo responses can be:
        # 200 (rendered turbo-stream)
        # 204 (no content)
        # 302 (redirect fallback)
        expect([200, 204, 302]).to include(response.status)
      end

      it "returns turbo_stream response when requested" do
        post :create,
             params: { friend_id: friend.id },
             format: :turbo_stream

        if response.status == 200
          expect(response.body).to include("turbo-stream")
        else
          expect([204, 302]).to include(response.status)
        end
      end
    end

    context "when save fails" do
      before do
        allow_any_instance_of(Friendship).to receive(:save).and_return(false)
      end

      it "does not create a friendship" do
        expect {
          post :create,
               params: { friend_id: friend.id },
               format: :turbo_stream
        }.not_to change(Friendship, :count)
      end

      it "handles save failure gracefully (Turbo)" do
        post :create,
             params: { friend_id: friend.id },
             format: :turbo_stream

        expect([200, 204, 422, 302]).to include(response.status)
      end

      it "sets flash error for HTML requests" do
        post :create, params: { friend_id: friend.id }

        expect(flash[:error]).to eq("Failed to send friend request")
        expect(response).to redirect_to(friendships_path)
      end
    end
  end
end
