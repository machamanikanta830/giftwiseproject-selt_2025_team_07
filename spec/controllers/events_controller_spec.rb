# frozen_string_literal: true
require "rails_helper"

RSpec.describe EventsController, type: :controller do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  let(:recipient) do
    create(:recipient,
           user: user,
           name: "Alex",
           relationship: "Friend",
           email: "alex@test.com"
    )
  end

  let(:event) do
    create(:event,
           user: user,
           event_name: "Birthday",
           event_date: Date.tomorrow
    )
  end

  before do
    session[:user_id] = user.id
    allow(controller).to receive(:authenticate_user!).and_return(true)
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe "GET #index" do
    it "loads upcoming and past events" do
      get :index
      expect(response).to be_successful
    end
  end

  describe "GET #new" do
    it "renders new event page" do
      get :new
      expect(response).to be_successful
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates event and redirects to dashboard" do
        expect {
          post :create, params: {
            event: {
              event_name: "Party",
              event_date: Date.tomorrow
            }
          }
        }.to change(Event, :count).by(1)

        expect(response).to redirect_to(dashboard_path)
      end
    end

    context "with invalid params" do
      it "re-renders new with unprocessable_content" do
        post :create, params: {
          event: { event_name: "" }
        }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response).to render_template(:new)
      end
    end
  end

  describe "GET #show" do
    it "shows the event" do
      get :show, params: { id: event.id }
      expect(response).to be_successful
    end
  end

  describe "GET #edit" do
    it "renders edit page" do
      get :edit, params: { id: event.id }
      expect(response).to be_successful
    end
  end

  describe "PATCH #update" do
    context "with valid params" do
      it "updates event" do
        patch :update, params: {
          id: event.id,
          event: { event_name: "Updated Event" }
        }

        expect(event.reload.event_name).to eq("Updated Event")
        expect(response).to redirect_to(event_path(event))
      end
    end

    context "with invalid params" do
      it "re-renders edit page" do
        patch :update, params: {
          id: event.id,
          event: { event_name: "" }
        }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response).to render_template(:edit)
      end
    end
  end

  describe "POST #add_recipient" do
    it "adds recipient to event" do
      post :add_recipient, params: {
        id: event.id,
        recipient_id: recipient.id
      }

      expect(event.event_recipients.count).to eq(1)
      expect(response).to redirect_to(event_path(event))
    end

    it "handles recipient not found" do
      post :add_recipient, params: {
        id: event.id,
        recipient_id: 999
      }

      expect(flash[:alert]).to match(/Recipient not found/)
    end
  end

  describe "DELETE #remove_recipient" do
    let!(:event_recipient) do
      create(:event_recipient,
             event: event,
             recipient: recipient,
             user: user
      )
    end

    it "removes recipient from event" do
      delete :remove_recipient, params: {
        id: event.id,
        event_recipient_id: event_recipient.id
      }

      expect(EventRecipient.count).to eq(0)
      expect(response).to redirect_to(event_path(event))
    end

    it "handles missing event_recipient" do
      delete :remove_recipient, params: {
        id: event.id,
        event_recipient_id: 999
      }

      expect(flash[:alert]).to match(/not found/)
    end
  end

  describe "DELETE #destroy" do
    it "deletes the event" do
      event
      expect {
        delete :destroy, params: { id: event.id }
      }.to change(Event, :count).by(-1)

      expect(response).to redirect_to(events_path)
    end
  end

  describe "authorization" do
    it "blocks unauthorized user" do
      allow(event).to receive(:can_manage_event?).and_return(false)
      allow(Event).to receive(:accessible_to).and_return(Event.where(id: event.id))

      patch :update, params: {
        id: event.id,
        event: { event_name: "Hack" }
      }

      expect(response).to redirect_to(event_path(event))
      expect(response).to redirect_to(event_path(event))
    end
  end
end
