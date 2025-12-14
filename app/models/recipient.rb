class Recipient < ApplicationRecord
  belongs_to :user
  has_many :event_recipients, dependent: :destroy
  has_many :events, through: :event_recipients
  has_many :gift_ideas, through: :event_recipients
  has_many :gift_given_backlogs, dependent: :destroy
  def has_any_event?
    event_recipients.exists?
  end

  GENDERS = ['Male', 'Female', 'Prefer not to say', 'Other'].freeze

  # RELATIONSHIPS = [
  #   "Friend",
  #   "Family",
  #   "Partner",
  #   "Colleague",
  #   "Other"
  # ].freeze
  before_validation :normalize_email

  validates :name, presence: true

  VALID_EMAIL_REGEX = /\A[^@\s]+@[^@\s]+\.[^@\s]+\z/

  validates :email,
            presence: true,
            uniqueness: { scope: :user_id, case_sensitive: false, message: "is already added" },
            format: { with: VALID_EMAIL_REGEX, message: "Invalid email format" }

  validates :age,
            numericality: { only_integer: true },
            allow_nil: true

  validates :relationship,
            presence: true

  validates :gender,
            inclusion: { in: GENDERS },
            allow_nil: true

  def events_with_details
    event_recipients.includes(:event)
  end

  private

  def normalize_email
    self.email = email.to_s.strip.downcase
  end

end
