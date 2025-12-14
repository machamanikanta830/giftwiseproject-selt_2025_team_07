# app/controllers/password_resets_controller.rb
class PasswordResetsController < ApplicationController
  def new
  end

  def create
    email = params[:email].to_s.strip.downcase
    user  = User.find_by(email: email)

    if user
      token = user.generate_password_reset_token!
      PasswordResetMailer.reset_email(user, token).deliver_now
      redirect_to login_path, notice: "Password reset instructions have been sent to #{email}"
    else
      flash.now[:alert] = "No account found with that email address"
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @token = PasswordResetToken.find_by(token: params[:token])

    if @token.nil? || @token.used
      redirect_to login_path, alert: "Invalid or expired password reset link" and return
    elsif @token.expired?
      redirect_to forgot_password_path, alert: "This password reset link has expired. Please request a new one." and return
    end
  end

  def update
    @token = PasswordResetToken.find_by(token: params[:token])

    if @token.nil? || @token.used || @token.expired?
      redirect_to login_path, alert: "Invalid or expired password reset link" and return
    end

    user = @token.user
    user.password              = params.dig(:user, :password)
    user.password_confirmation = params.dig(:user, :password_confirmation)

    if user.save
      @token.mark_as_used!
      redirect_to login_path, notice: "Password successfully reset. Please log in with your new password."
    else
      flash.now[:alert] = user.errors.full_messages.first
      render :edit, status: :unprocessable_entity
    end
  end
end
