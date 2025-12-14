class SessionsController < ApplicationController
  def new
  end

  def create
    user = User.find_by(email: params[:email].downcase)

    if user && !user.has_password?
      flash.now[:alert] = 'This account was created with Google. Please use "Login with Google" or set a password in your profile.'
      render :new, status: :unprocessable_content
      return
    end

    if user&.authenticate(params[:password])
      if user.mfa_enabled?
        session[:pending_mfa_user_id] = user.id
        redirect_to new_mfa_session_path
      else
        session[:user_id] = user.id
        check_and_accept_pending_invite(user)
        redirect_to dashboard_path, notice: "Welcome back, #{user.name}!"
      end
    else
      flash.now[:alert] = 'Invalid email or password'
      render :new, status: :unprocessable_content
    end
  end

  def omniauth
    auth = request.env['omniauth.auth']
    user = User.from_omniauth(auth)

    if user&.persisted?
      session[:user_id] = user.id
      check_and_accept_pending_invite(user)
      redirect_to dashboard_path, notice: "Welcome, #{user.name}!"
    else
      redirect_to login_path, alert: 'Authentication failed. Please try again.'
    end
  end

  def auth_failure
    redirect_to login_path, alert: 'Authentication failed. Please try again.'
  end

  def destroy
    session[:user_id] = nil
    redirect_to root_path, notice: 'You have been logged out successfully'
  end

  private

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
    flash[:notice] = "Welcome back, #{user.name}! You've successfully joined #{invite.event.event_name}!"
  end
end