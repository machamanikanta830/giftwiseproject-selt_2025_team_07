class AiGiftSuggestion < ApplicationRecord
  belongs_to :user
  belongs_to :event
  belongs_to :recipient, optional: true
  belongs_to :event_recipient, optional: true

  has_many :wishlists, dependent: :destroy

  # Heart state for a specific user
  def saved_for_user?(user)
    return false unless user
    wishlists.exists?(user_id: user.id)
  end

  def average_estimated_price
    self.class.average_price_from_range(estimated_price)
  end

  def self.average_price_from_range(text)
    return nil if text.blank?

    # grab numbers like 25, 25.99, 1,200 (handles commas)
    nums = text.to_s.scan(/(\d[\d,]*\.?\d*)/).flatten.map { |n| n.delete(",").to_f }
    return nil if nums.empty?

    if nums.length >= 2
      ((nums[0] + nums[1]) / 2.0).round(2)
    else
      nums[0].round(2)
    end
  end

end
