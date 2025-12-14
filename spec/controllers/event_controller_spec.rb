# frozen_string_literal: true
require "rails_helper"

RSpec.describe EventsController, type: :controller do
  let!(:user) { create(:user) }
  let!(:recipient) { create(:recipient, user: user) }

  let!(:event) do
    create(
      :event,
      user: user,
      event_name: "Birthday",
      event_date: 1.week.from_now
    )
  end

  before do
    allow(controller).to receive(:authenticate_user!).and_return(true)
    allow(controller).to receive(:current_user).and_return(user)
    allow(Event).to receive(:accessible_to).and_return(Event.all)
    allow_any_instance_of(Event).to receive(:can_manage_event?).and_return(true)
  end

  # --------------------------------------------------
  # GET #index
  # --------------------------------------------------
  describe "GET #index" do
    it "loads upcoming and past events" do
      get :index
      expect(assigns(:upcoming_events)).to include(event)
    end
  end

  # --------------------------------------------------
  # GET #new
  # --------------------------------------------------
  describe "GET #new" do
    it "initializes a new event" do
      get :new
      expect(assigns(:event)).to be_a_new(Event)
    end
  end

  # --------------------------------------------------
  # POST #create
  # --------------------------------------------------
  describe "POST #create" do
    it "creates an event successfully" do
      post :create, params: {
        event: {
          event_name: "Wedding",
          description: "Test",
          event_date: 2.weeks.from_now,
          location: "NY",
          budget: 500
        }
      }

      expect(response).to redirect_to(dashboard_path)
      expect(Event.count).to be >= 1
    end

    it "renders new on validation failure" do
      post :create, params: {
        event: { event_name: "" }
      }

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  # --------------------------------------------------
  # GET #show
  # --------------------------------------------------
  describe "GET #show" do
    it "loads event details" do
      get :show, params: { id: event.id }
      expect(assigns(:event)).to eq(event)
    end
  end

  # --------------------------------------------------
  # GET #edit
  # --------------------------------------------------
  describe "GET #edit" do
    it "loads edit page" do
      get :edit, params: { id: event.id }
      expect(assigns(:event)).to eq(event)
    end
  end

  # --------------------------------------------------
  # PATCH #update
  # --------------------------------------------------
  describe "PATCH #update" do
    it "updates the event" do
      patch :update, params: {
        id: event.id,
        event: { location: "Chicago" }
      }

      expect(event.reload.location).to eq("Chicago")
      expect(response).to redirect_to(event_path(event))
    end
  end

  # --------------------------------------------------
  # DELETE #destroy
  # --------------------------------------------------
  describe "DELETE #destroy" do
    it "deletes the event" do
      expect {
        delete :destroy, params: { id: event.id }
      }.to change(Event, :count).by(-1)

      expect(response).to redirect_to(events_path)
    end
  end

  # --------------------------------------------------
  # Authorization failure
  # --------------------------------------------------
  describe "authorization" do
    it "redirects if user cannot manage event" do
      allow_any_instance_of(Event).to receive(:can_manage_event?).and_return(false)

      get :edit, params: { id: event.id }

      expect(response).to redirect_to(event_path(event))
      expect(flash[:alert]).to be_present
    end
  end
end
