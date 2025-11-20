require 'rails_helper'

RSpec.describe PasswordResetMailer, type: :mailer do
  describe '#reset_email' do
    let(:user) { create(:user, name: 'Test User', email: 'testuser@example.com') }
    let(:token) { create(:password_reset_token, user: user) }
    let(:mail) { PasswordResetMailer.reset_email(user, token) }

    it 'renders the correct subject' do
      expect(mail.subject).to eq('Reset Your GiftWise Password')
    end

    it 'sends to the user email' do
      expect(mail.to).to eq([user.email])
    end

    it 'sends from noreply@mygiftwise.online' do
      expect(mail.from).to eq(['noreply@mygiftwise.online'])
    end

    it 'includes the user name in the body' do
      expect(mail.body.encoded).to include(user.name)
    end

    it 'includes the reset link in the body' do
      reset_url = reset_password_url(token: token.token)
      expect(mail.body.encoded).to include(reset_url)
    end

    it 'includes reset password button text' do
      expect(mail.body.encoded).to include('Reset Password')
    end

    it 'includes expiration notice' do
      expect(mail.body.encoded).to match(/expires? in 1 hour/i)
    end

    it 'includes security notice about unsolicited reset' do
      expect(mail.body.encoded).to match(/didn't request/i)
    end

    it 'includes instruction to ignore if not requested' do
      expect(mail.body.encoded).to match(/safely ignore/i)
    end

    it 'has both HTML and text parts' do
      expect(mail.body.parts.count).to eq(2)
      expect(mail.body.parts.collect(&:content_type)).to include('text/plain; charset=UTF-8')
      expect(mail.body.parts.collect(&:content_type)).to include('text/html; charset=UTF-8')
    end

    it 'renders HTML body with reset link' do
      html_part = mail.body.parts.find { |p| p.content_type.include?('text/html') }
      expect(html_part.body.to_s).to include('Reset Your Password')
      expect(html_part.body.to_s).to include(token.token)
    end

    it 'renders text body with reset link' do
      text_part = mail.body.parts.find { |p| p.content_type.include?('text/plain') }
      expect(text_part.body.to_s).to include('Reset Your Password')
      expect(text_part.body.to_s).to include(token.token)
    end

    it 'uses the correct layout' do
      html_part = mail.body.parts.find { |p| p.content_type.include?('text/html') }
      expect(html_part.body.to_s).to include('GiftWise')
    end
  end
end