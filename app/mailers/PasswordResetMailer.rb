class PasswordResetMailer < ApplicationMailer
  default from: 'noreply@mygiftwise.online'

  def reset_email(user, token)
    @user = user
    @token = token
    @reset_url = reset_password_url(token: token.token)

    mail(
      to: user.email,
      subject: 'Reset Your GiftWise Password'
    ) do |format|
      format.html { render 'reset_email' }
      format.text { render 'reset_email' }
    end
  end
end