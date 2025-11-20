class PasswordResetToken < ApplicationRecord
  belongs_to :user

  validates :token, uniqueness: true, allow_nil: true

  before_validation :generate_token, on: :create
  before_validation :set_expiration, on: :create
  after_initialize :set_defaults, if: :new_record?

  scope :active, -> { where(used: false).where('expires_at > ?', Time.current) }

  def expired?
    Time.current >= expires_at
  end

  def mark_as_used!
    update!(used: true)
  end

  private

  def generate_token
    self.token = SecureRandom.urlsafe_base64(32) if token.blank?
  end

  def set_expiration
    self.expires_at = 1.hour.from_now if expires_at.blank?
  end

  def set_defaults
    self.used = false if used.nil?
  end
end