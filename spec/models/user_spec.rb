RSpec.describe User, type: :model do
  describe ".from_omniauth" do
    let(:auth_hash) do
      OmniAuth::AuthHash.new(
        provider: "google",
        uid: "123456",
        info: {
          email: "oauth@test.com",
          name: "OAuth User"
        }
      )
    end

    it "returns nil if auth or email is missing" do
      expect(User.from_omniauth(nil)).to be_nil
    end

    it "creates a new user and authentication if user does not exist" do
      user = User.from_omniauth(auth_hash)

      expect(user).to be_persisted
      expect(user.email).to eq("oauth@test.com")
      expect(user.authentications.count).to eq(1)
    end

    it "adds authentication to existing user" do
      existing = create(:user, email: "oauth@test.com")

      user = User.from_omniauth(auth_hash)

      expect(user.id).to eq(existing.id)
      expect(user.authentications.count).to eq(1)
    end
  end

  describe "#has_password?" do
    it "returns false when password is not set" do
      user = create(:user, password: nil)
      expect(user.has_password?).to eq(false)
    end

    it "returns true when password exists" do
      user = create(:user, password: "Password@123")
      expect(user.has_password?).to eq(true)
    end
  end

  describe "#unread_messages_from" do
    let(:sender) { create(:user) }
    let(:receiver) { create(:user) }

    it "counts unread messages correctly" do
      create(:message, sender: sender, receiver: receiver, read: false)
      create(:message, sender: sender, receiver: receiver, read: true)

      expect(receiver.unread_messages_from(sender)).to eq(1)
    end
  end

  describe "MFA verification" do
    it "verifies MFA code when enabled" do
      user = create(:user)
      mfa = create(:mfa_credential, user: user, enabled: true)

      allow(mfa).to receive(:verify_code).and_return(true)

      expect(user.verify_mfa_code("123456")).to eq(true)
    end
  end

  describe "backup code verification" do
    it "marks backup code as used when verified" do
      user = create(:user)
      backup = create(:backup_code, user: user, used: false)

      allow(backup).to receive(:verify).and_return(true)

      expect(user.verify_backup_code("backup123")).to eq(true)
      expect(backup.reload.used).to eq(true)
    end

    it "returns false when no backup code matches" do
      user = create(:user)
      create(:backup_code, user: user, used: false)

      expect(user.verify_backup_code("wrong")).to eq(false)
    end
  end

  describe "password_required?" do
    it "returns false when skip_password_validation is true" do
      user = build(:user)
      user.skip_password_validation = true

      expect(user.send(:password_required?)).to eq(false)
    end
  end

  describe "password complexity validation" do
    it "adds errors for weak passwords" do
      user = build(:user, password: "weak")

      expect(user).not_to be_valid
      expect(user.errors[:password]).to be_present
    end
  end
end
