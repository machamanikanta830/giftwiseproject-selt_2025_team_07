module HelperMethods
  def find_email_to(email)
    ActionMailer::Base.deliveries.find { |mail| mail.to.include?(email) }
  end

  def extract_reset_token_from_email(email)
    mail = find_email_to(email)
    return nil unless mail

    match = mail.body.encoded.match(/reset_password\/([A-Za-z0-9_-]+)/)
    match[1] if match
  end
end

World(HelperMethods)