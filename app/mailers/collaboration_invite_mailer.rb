class CollaborationInviteMailer < ApplicationMailer
  default from: 'no-reply@mygiftwise.online'

  def invite_email(invite)
    @invite = invite
    @event = invite.event
    @inviter = invite.inviter
    @accept_url = accept_collaboration_invite_url(invite.token)

    @role_permissions = if invite.role == Collaborator::ROLE_CO_PLANNER
                          ['View and manage gift ideas', 'Add and edit recipients', 'Collaborate on gift planning', 'Share wishlist items']
                        else
                          ['View gift ideas', 'See event details', 'Browse suggestions']
                        end

    mail(
      to: invite.invitee_email,
      subject: "#{@inviter.name} invited you to collaborate on #{@event.event_name}"
    )
  end
end