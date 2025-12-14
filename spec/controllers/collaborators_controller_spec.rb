# spec/controllers/collaborators_controller_spec.rb
require "rails_helper"

RSpec.describe CollaboratorsController, type: :controller do
  let(:owner) { User.create!(name: "Owner", email: "owner@example.com", password: "Password@123") }
  let(:other_user) { User.create!(name: "Friend", email: "friend@example.com", password: "Password@123") }

  let(:event) do
    Event.create!(user: owner, event_name: "Birthday", event_date: Date.today + 5, budget: 100.0)
  end

  before do
    # Auth stubs per your project convention
    allow_any_instance_of(ApplicationController).to receive(:authenticate_user!).and_return(true)
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(owner)
  end

  describe "POST #create" do
    context "when current_user is not the event owner" do
      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(other_user)
      end

      it "redirects to dashboard with alert" do
        post :create, params: { event_id: event.id, collaborator: { user_id: owner.id, role: "viewer" } }
        expect(response).to redirect_to(dashboard_path)
        expect(flash[:alert]).to match(/Only the event owner/i)
      end
    end

    context "when inviting an existing user by user_id" do
      it "creates a pending collaborator and redirects with notice" do
        expect {
          post :create, params: { event_id: event.id, collaborator: { user_id: other_user.id, role: "co_planner" } }
        }.to change(Collaborator, :count).by(1)

        c = event.collaborators.last
        expect(c.user_id).to eq(other_user.id)
        expect(c.role).to eq("co_planner")
        expect(c.status).to eq(Collaborator::STATUS_PENDING)

        expect(response).to redirect_to(event_path(event))
        expect(flash[:notice]).to include(other_user.name)
      end

      it "blocks if user is already a collaborator" do
        event.collaborators.create!(user: other_user, role: "viewer", status: Collaborator::STATUS_PENDING)

        expect {
          post :create, params: { event_id: event.id, collaborator: { user_id: other_user.id, role: "viewer" } }
        }.not_to change(Collaborator, :count)

        expect(response).to redirect_to(event_path(event))
        expect(flash[:alert]).to match(/already a collaborator/i)
      end
    end

    context "when inviting an existing user by email (case-insensitive)" do
      it "finds user and creates collaborator" do
        # Ensure controller path uses the 'invited_user exists' branch
        allow(User).to receive(:find_by).and_call_original
        allow(User).to receive(:find_by)
                         .with("LOWER(email) = ?", "friend@example.com")
                         .and_return(other_user)

        expect {
          post :create, params: { event_id: event.id, collaborator: { email: "FRIEND@EXAMPLE.COM", role: "viewer" } }
        }.to change(Collaborator, :count).by(1)

        c = event.collaborators.last
        expect(c.user_id).to eq(other_user.id)
        expect(c.role).to eq("viewer")
        expect(c.status).to eq(Collaborator::STATUS_PENDING)

        expect(response).to redirect_to(event_path(event))
        expect(flash[:notice]).to include(other_user.name)
      end
    end


    context "when invited user does not exist (email invite path)" do
      it "rejects when email is blank" do
        post :create, params: { event_id: event.id, collaborator: { email: "   ", role: "viewer" } }

        expect(response).to redirect_to(event_path(event))
        expect(flash[:alert]).to match(/Please provide an email/i)
      end

      it "creates a CollaborationInvite (token auto-generated) and redirects with notice" do
        expect {
          post :create, params: { event_id: event.id, collaborator: { email: "newperson@example.com", role: "viewer" } }
        }.to change(CollaborationInvite, :count).by(1)

        inv = CollaborationInvite.last
        expect(inv.event_id).to eq(event.id)
        expect(inv.inviter_id).to eq(owner.id)
        expect(inv.invitee_email).to eq("newperson@example.com") # downcased + stripped by model
        expect(inv.role).to eq("viewer")
        expect(inv.status).to eq("pending")
        expect(inv.sent_at).to be_present
        expect(inv.expires_at).to be_present
        expect(inv.token).to be_present

        expect(response).to redirect_to(event_path(event))
        expect(flash[:notice]).to include("Invite email sent")
      end

      it "blocks duplicate pending invite for same email (case-insensitive)" do
        # Create an existing pending invite; model normalizes to lowercase
        CollaborationInvite.create!(
          event: event,
          inviter: owner,
          invitee_email: "dup@example.com",
          role: "viewer",
          status: "pending",
          sent_at: Time.current,
          expires_at: 14.days.from_now
        # token auto
        )

        expect {
          post :create, params: { event_id: event.id, collaborator: { email: "DUP@EXAMPLE.COM", role: "viewer" } }
        }.not_to change(CollaborationInvite, :count)

        expect(response).to redirect_to(event_path(event))
        expect(flash[:alert]).to match(/already pending/i)
      end
    end

    context "role defaulting" do
      it "defaults role to Collaborator::ROLE_VIEWER when no role is provided" do
        post :create, params: { event_id: event.id, collaborator: { user_id: other_user.id } }

        c = event.collaborators.last
        expect(c.role).to eq(Collaborator::ROLE_VIEWER)
        expect(response).to redirect_to(event_path(event))
      end
    end
  end

  describe "PATCH #update" do
    let!(:collab) do
      event.collaborators.create!(user: other_user, role: "viewer", status: Collaborator::STATUS_PENDING)
    end

    it "updates role when role param is present and update succeeds" do
      patch :update, params: { event_id: event.id, id: collab.id, role: "co_planner" }

      expect(response).to redirect_to(event_path(event))
      expect(flash[:notice]).to match(/role updated/i)
      expect(collab.reload.role).to eq("co_planner")
    end

    it "fails when role param is missing (hits else branch)" do
      patch :update, params: { event_id: event.id, id: collab.id }

      expect(response).to redirect_to(event_path(event))
      expect(flash[:alert]).to match(/Failed to update collaborator/i)
    end

    it "fails when collaborator.update returns false" do
      allow_any_instance_of(Collaborator).to receive(:update).and_return(false)

      patch :update, params: { event_id: event.id, id: collab.id, role: "viewer" }

      expect(response).to redirect_to(event_path(event))
      expect(flash[:alert]).to match(/Failed to update collaborator/i)
    end
  end

  describe "DELETE #destroy" do
    let!(:collab) do
      event.collaborators.create!(user: other_user, role: "viewer", status: Collaborator::STATUS_PENDING)
    end

    it "destroys collaborator and redirects with notice including the user name" do
      expect {
        delete :destroy, params: { event_id: event.id, id: collab.id }
      }.to change(Collaborator, :count).by(-1)

      expect(response).to redirect_to(event_path(event))
      expect(flash[:notice]).to include(other_user.name)
    end
  end

  describe "set_event scoping" do
    it "uses Event.all for create (even if accessible_to would return none)" do
      # If set_event incorrectly used accessible_to here, create could 404.
      allow(Event).to receive(:accessible_to).and_return(Event.none)

      post :create, params: { event_id: event.id, collaborator: { email: "noone@example.com" } }

      expect(response).to redirect_to(event_path(event))
    end

    it "uses Event.accessible_to for update/destroy" do
      collab = event.collaborators.create!(user: other_user, role: "viewer", status: Collaborator::STATUS_PENDING)

      # Make accessible_to exclude the event -> should raise ActiveRecord::RecordNotFound
      allow(Event).to receive(:accessible_to).with(owner).and_return(Event.none)

      expect {
        patch :update, params: { event_id: event.id, id: collab.id, role: "viewer" }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
