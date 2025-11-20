class PasswordResetToken < ApplicationRecord
  belongs_to :user

  validates :token, presence: true, uniqueness: true
  validates :expires_at, presence: true

  before_validation :generate_token, on: :create
  before_validation :set_expiration, on: :create

  scope :active, -> { where(used: false).where('expires_at > ?', Time.current) }

  def expired?
    expires_at < Time.current
  end

  def mark_as_used!
    update!(used: true)
  end

  private

  def generate_token
    self.token = SecureRandom.urlsafe_base64(32)
  end

  def set_expiration
    self.expires_at = 1.hour.from_now
  end
end