class AiGiftSuggestion < ApplicationRecord
  belongs_to :user
  belongs_to :event
  belongs_to :recipient
  belongs_to :event_recipient
end
