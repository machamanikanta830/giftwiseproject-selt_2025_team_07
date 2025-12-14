class CollaborationInvite < ApplicationRecord
  belongs_to :event
  belongs_to :inviter, class_name: "User"

  validates :invitee_email, presence: true
  validates :role, presence: true
  validates :status, presence: true
  validates :token, presence: true, uniqueness: true

  before_validation :normalize_email
  before_validation :ensure_token, on: :create

  scope :pending, -> { where(status: "pending") }
  scope :accepted, -> { where(status: "accepted") }
  scope :expired, -> { where("expires_at < ?", Time.current) }

  def pending?
    status == "pending"
  end

  def accepted?
    status == "accepted"
  end

  def expired?
    expires_at.present? && expires_at < Time.current
  end

  def role_label
    role == Collaborator::ROLE_CO_PLANNER ? "Co-Planner" : "Viewer"
  end

  private

  def normalize_email
    self.invitee_email = invitee_email.to_s.strip.downcase
  end

  def ensure_token
    self.token ||= SecureRandom.hex(24)
  end
end