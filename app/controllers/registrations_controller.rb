class RegistrationsController < ApplicationController
  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      session[:user_id] = @user.id
      check_and_accept_pending_invite(@user)
      redirect_to dashboard_path, notice: "Welcome to GiftWise, #{@user.name}!"
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :password, :date_of_birth, :phone_number, :gender, :occupation, :hobbies, :likes, :dislikes)
  end

  def check_and_accept_pending_invite(user)
    return unless session[:pending_invite_token].present?

    invite = CollaborationInvite.find_by(token: session[:pending_invite_token])
    return unless invite && invite.pending? && !invite.expired?
    return unless user.email.downcase == invite.invitee_email.downcase

    ActiveRecord::Base.transaction do
      invite.event.collaborators.create!(
        user: user,
        role: invite.role,
        status: Collaborator::STATUS_ACCEPTED
      )

      invite.update!(
        status: "accepted",
        accepted_at: Time.current
      )
    end

    session.delete(:pending_invite_token)
    flash[:notice] = "Welcome to GiftWise, #{user.name}! You've successfully joined #{invite.event.event_name}!"
  end
end