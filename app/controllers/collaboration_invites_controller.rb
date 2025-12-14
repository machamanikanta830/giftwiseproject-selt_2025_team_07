class CollaborationInvitesController < ApplicationController
  before_action :set_invite, only: [:accept]

  def accept
    if @invite.nil?
      redirect_to root_path, alert: "Invalid or expired invitation link."
      return
    end

    if @invite.expired?
      redirect_to root_path, alert: "This invitation has expired."
      return
    end

    if @invite.accepted?
      redirect_to root_path, alert: "This invitation has already been accepted."
      return
    end

    unless user_signed_in?
      session[:pending_invite_token] = @invite.token
      redirect_to login_path, notice: "Please log in or sign up to accept this collaboration invitation."
      return
    end

    unless current_user.email.downcase == @invite.invitee_email.downcase
      redirect_to dashboard_path, alert: "This invitation was sent to #{@invite.invitee_email}. Please log in with that email address."
      return
    end

    if @invite.event.collaborators.exists?(user_id: current_user.id)
      redirect_to event_path(@invite.event), notice: "You're already a collaborator on this event."
      return
    end

    ActiveRecord::Base.transaction do
      @invite.event.collaborators.create!(
        user: current_user,
        role: @invite.role,
        status: Collaborator::STATUS_ACCEPTED
      )

      @invite.update!(
        status: "accepted",
        accepted_at: Time.current
      )
    end

    session.delete(:pending_invite_token)

    redirect_to event_path(@invite.event), notice: "You've successfully joined #{@invite.event.event_name}!"
  end

  private

  def set_invite
    @invite = CollaborationInvite.find_by(token: params[:token])
  end
end