# spec/models/recipient_spec.rb
require "rails_helper"

RSpec.describe Recipient, type: :model do
  let(:user) do
    User.create!(
      name: "Test User",
      email: "user@example.com",
      password: "Password1!"
    )
  end

  it "is valid with valid attributes" do
    rec = user.recipients.new(
      name: "John",
      relationship: "Friend",
      email: "john@example.com",
      age: 30,
      gender: "Male"
    )
    expect(rec).to be_valid
  end

  it "is invalid without a name" do
    rec = user.recipients.new(
      name: nil,
      relationship: "Friend",
      email: "john@example.com"
    )

    expect(rec).not_to be_valid
    expect(rec.errors[:name]).to include("can't be blank")
  end

  it "is invalid without a relationship" do
    rec = user.recipients.new(
      name: "John",
      relationship: nil,
      email: "john@example.com"
    )

    expect(rec).not_to be_valid
    expect(rec.errors[:relationship]).to include("can't be blank")
  end

  it "is invalid without an email" do
    rec = user.recipients.new(
      name: "John",
      relationship: "Friend",
      email: ""
    )

    expect(rec).not_to be_valid
    expect(rec.errors[:email]).to be_present
  end

  it "validates email format" do
    rec = user.recipients.new(
      name: "John",
      relationship: "Friend",
      email: "not-an-email"
    )

    expect(rec).not_to be_valid
    expect(rec.errors[:email]).to be_present
  end

  it "enforces email uniqueness per user (case-insensitive)" do
    user.recipients.create!(
      name: "A",
      relationship: "Friend",
      email: "john@example.com"
    )

    rec2 = user.recipients.new(
      name: "B",
      relationship: "Friend",
      email: "JOHN@EXAMPLE.COM"
    )

    expect(rec2).not_to be_valid
    expect(rec2.errors[:email]).to be_present
  end

  it "allows nil age" do
    rec = user.recipients.new(
      name: "John",
      relationship: "Friend",
      email: "john2@example.com",
      age: nil
    )
    expect(rec).to be_valid
  end

  it "requires age to be an integer if present" do
    rec = user.recipients.new(
      name: "John",
      relationship: "Friend",
      email: "john3@example.com",
      age: 25.5
    )

    expect(rec).not_to be_valid
    expect(rec.errors[:age]).to be_present
  end

  it "allows nil gender" do
    rec = user.recipients.new(
      name: "John",
      relationship: "Friend",
      email: "john4@example.com",
      gender: nil
    )
    expect(rec).to be_valid
  end

  it "requires gender to be in the defined list when present" do
    rec = user.recipients.new(
      name: "John",
      relationship: "Friend",
      email: "john5@example.com",
      gender: "InvalidGender"
    )

    expect(rec).not_to be_valid
    expect(rec.errors[:gender]).to be_present
  end

  it "belongs to a user" do
    rec = user.recipients.create!(
      name: "Ayra",
      relationship: "Family",
      email: "ayra@example.com"
    )
    expect(rec.user).to eq(user)
  end

  it "can be associated with events through event_recipients" do
    rec = user.recipients.create!(
      name: "Ayra",
      relationship: "Family",
      email: "ayra2@example.com"
    )

    event = user.events.create!(
      event_name: "Birthday Party",
      event_date: Date.today,
      description: "Test event"
    )

    er = EventRecipient.create!(recipient: rec, event: event, user: user)

    expect(rec.events).to include(event)
    expect(rec.event_recipients).to include(er)
  end

  describe "#events_with_details" do
    it "returns event_recipients with events eager loaded" do
      rec = user.recipients.create!(
        name: "Myra",
        relationship: "Friend",
        email: "myra@example.com"
      )

      event = user.events.create!(
        event_name: "Anniversary Party",
        event_date: Date.today,
        description: "Test event"
      )

      er = EventRecipient.create!(recipient: rec, event: event, user: user)

      result = rec.events_with_details
      expect(result).to include(er)
    end
  end
end
