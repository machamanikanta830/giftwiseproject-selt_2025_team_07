# frozen_string_literal: true

require "rails_helper"

RSpec.describe Notification, type: :model do
  it "is valid with a user and an event" do
    user  = create(:user)
    event = create(:event, user: user)

    notification = Notification.new(
      user: user,
      event: event
    )

    expect(notification).to be_valid
  end
end
