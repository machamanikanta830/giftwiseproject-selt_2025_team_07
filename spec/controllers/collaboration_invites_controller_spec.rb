require 'rails_helper'

RSpec.describe CollaborationInvitesController, type: :controller do
  let(:inviter) { User.create!(name: 'Alice', email: 'alice@example.com', password: 'Password123!') }
  let(:invitee) { User.create!(name: 'Bob', email: 'bob@example.com', password: 'Password123!') }
  let(:event) { Event.create!(event_name: 'Test Event', event_date: Date.tomorrow, user: inviter) }
  let(:invite) do
    CollaborationInvite.create!(
      event: event,
      inviter: inviter,
      invitee_email: 'bob@example.com',
      role: Collaborator::ROLE_CO_PLANNER,
      status: 'pending',
      expires_at: 14.days.from_now
    )
  end

  describe 'GET #accept' do
    context 'when user is not logged in' do
      it 'stores token in session and redirects to login' do
        get :accept, params: { token: invite.token }

        expect(session[:pending_invite_token]).to eq(invite.token)
        expect(response).to redirect_to(login_path)
        expect(flash[:notice]).to include('Please log in or sign up')
      end
    end

    context 'when user is logged in' do
      before { session[:user_id] = invitee.id }

      it 'creates a collaborator and marks invite as accepted' do
        expect {
          get :accept, params: { token: invite.token }
        }.to change(Collaborator, :count).by(1)

        expect(invite.reload.status).to eq('accepted')
        expect(invite.accepted_at).to be_present
      end

      it 'redirects to event page with success message' do
        get :accept, params: { token: invite.token }

        expect(response).to redirect_to(event_path(event))
        expect(flash[:notice]).to include("successfully joined")
      end

      it 'clears pending invite token from session' do
        session[:pending_invite_token] = invite.token
        get :accept, params: { token: invite.token }

        expect(session[:pending_invite_token]).to be_nil
      end
    end

    context 'with invalid token' do
      it 'redirects with error message' do
        get :accept, params: { token: 'invalid-token' }

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include('Invalid or expired')
      end
    end

    context 'with expired invite' do
      before { invite.update!(expires_at: 1.day.ago) }

      it 'redirects with expiry message' do
        get :accept, params: { token: invite.token }

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include('expired')
      end
    end

    context 'with already accepted invite' do
      before { invite.update!(status: 'accepted', accepted_at: Time.current) }

      it 'redirects with already accepted message' do
        get :accept, params: { token: invite.token }

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include('already been accepted')
      end
    end

    context 'when logged in user email does not match invite' do
      let(:other_user) { User.create!(name: 'Charlie', email: 'charlie@example.com', password: 'Password123!') }

      before { session[:user_id] = other_user.id }

      it 'redirects with email mismatch error' do
        get :accept, params: { token: invite.token }

        expect(response).to redirect_to(dashboard_path)
        expect(flash[:alert]).to include('sent to bob@example.com')
      end
    end

    context 'when user is already a collaborator' do
      before do
        session[:user_id] = invitee.id
        event.collaborators.create!(user: invitee, role: Collaborator::ROLE_VIEWER, status: Collaborator::STATUS_ACCEPTED)
      end

      it 'redirects with already collaborator message' do
        get :accept, params: { token: invite.token }

        expect(response).to redirect_to(event_path(event))
        expect(flash[:notice]).to include('already a collaborator')
      end
    end
  end
end