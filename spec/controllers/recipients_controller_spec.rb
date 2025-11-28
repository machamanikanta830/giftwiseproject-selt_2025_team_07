# spec/controllers/recipients_controller_spec.rb
require "rails_helper"

RSpec.describe RecipientsController, type: :controller do
  let(:user) do
    User.create!(
      name: "Test User",
      email: "user@example.com",
      password: "Password1!"
    )
  end

  let(:recipient) do
    user.recipients.create!(
      name: "Mani",
      relationship: "Friend",
      email: "mani@example.com"
    )
  end

  before do
    # however you sign the user in in your tests
    session[:user_id] = user.id
  end

  describe "GET #show" do
    it "returns success" do
      get :show, params: { id: recipient.id }
      expect(response).to be_successful
    end
  end

  describe "GET #edit" do
    it "returns success" do
      get :edit, params: { id: recipient.id }
      expect(response).to be_successful
    end
  end

  describe "POST #create" do
    it "creates a recipient with valid params and redirects to dashboard" do
      expect {
        post :create, params: {
          recipient: {
            name: "New Rec",
            email: "new@example.com",
            relationship: "Family",
            gender: "Male" # optional
          }
        }
      }.to change(Recipient, :count).by(1)

      expect(response).to redirect_to(dashboard_path)
    end
  end

  describe "PATCH #update" do
    it "updates a recipient with valid params and redirects to index" do
      patch :update, params: {
        id: recipient.id,
        recipient: { name: "Updated Name" }
      }

      expect(response).to redirect_to(recipients_path)
      expect(recipient.reload.name).to eq("Updated Name")
    end

    it "does not update recipient with invalid params and re-renders edit" do
      patch :update, params: {
        id: recipient.id,
        recipient: { name: "" } # invalid because name presence
      }

      expect(response).to render_template(:edit)
    end
  end

  describe "DELETE #destroy" do
    it "deletes a recipient and redirects to index" do
      rec = recipient # trigger creation

      expect {
        delete :destroy, params: { id: rec.id }
      }.to change(Recipient, :count).by(-1)

      expect(response).to redirect_to(recipients_path)
    end
  end
end
