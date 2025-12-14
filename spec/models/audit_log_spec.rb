# frozen_string_literal: true

require "rails_helper"

RSpec.describe AuditLog, type: :model do
  it "is valid with a user" do
    user = create(:user)
    audit_log = AuditLog.new(user: user)

    expect(audit_log).to be_valid
  end
end
