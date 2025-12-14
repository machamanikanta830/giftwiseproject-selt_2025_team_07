require 'rails_helper'

RSpec.describe CollaborationInviteMailer, type: :mailer do
  let(:inviter) { User.create!(name: 'Alice', email: 'alice@example.com', password: 'Password123!') }
  let(:event) { Event.create!(event_name: 'Summer Party', event_date: Date.tomorrow, user: inviter) }
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

  describe 'invite_email' do
    let(:mail) { CollaborationInviteMailer.invite_email(invite) }

    it 'renders the subject' do
      expect(mail.subject).to eq('Alice invited you to collaborate on Summer Party')
    end

    it 'sends to the correct email' do
      expect(mail.to).to eq(['bob@example.com'])
    end

    it 'sends from the correct email' do
      expect(mail.from).to eq(['no-reply@mygiftwise.online'])
    end

    it 'includes the inviter name in the body' do
      expect(mail.html_part.body.encoded).to include('Alice')
    end

    it 'includes the event name in the body' do
      expect(mail.html_part.body.encoded).to include('Summer Party')
    end

    it 'includes the acceptance link in the body' do
      expect(mail.html_part.body.encoded).to include(accept_collaboration_invite_url(invite.token))
    end

    it 'includes role information for co-planner' do
      expect(mail.html_part.body.encoded).to include('Co-Planner')
      expect(mail.html_part.body.encoded).to include('View and manage gift ideas')
    end

    context 'when role is viewer' do
      before { invite.update!(role: Collaborator::ROLE_VIEWER) }

      it 'includes viewer role information' do
        expect(mail.html_part.body.encoded).to include('Viewer')
        expect(mail.html_part.body.encoded).to include('View gift ideas')
      end
    end

    it 'includes important notes' do
      expect(mail.html_part.body.encoded).to include('need a GiftWise account')
      expect(mail.html_part.body.encoded).to include('expires in 14 days')
    end

    it 'has a text part' do
      expect(mail.text_part.body.encoded).to include('Alice')
      expect(mail.text_part.body.encoded).to include('Summer Party')
      expect(mail.text_part.body.encoded).to include(accept_collaboration_invite_url(invite.token))
    end
  end
end