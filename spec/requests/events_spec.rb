# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Events", type: :request do
  let!(:user) { create(:user) }
  let!(:event) do
    create(
      :event,
      user: user,
      event_name: "Birthday Party"
    )
  end

  let!(:recipient) { create(:recipient, user: user) }

  # ------------------------------------------------------------
  # AUTH STUB (same pattern as your other request specs)
  # ------------------------------------------------------------
  before do
    allow_any_instance_of(ApplicationController)
      .to receive(:authenticate_user!)
            .and_return(true)

    allow_any_instance_of(ApplicationController)
      .to receive(:current_user)
            .and_return(user)
  end

  # ------------------------------------------------------------
  # INDEX
  # ------------------------------------------------------------
  describe "GET /events" do
    it "loads the events index" do
      get events_path
      expect(response).to have_http_status(:ok)
    end
  end

  # ------------------------------------------------------------
  # NEW
  # ------------------------------------------------------------
  describe "GET /events/new" do
    it "loads the new event form" do
      get new_event_path
      expect(response).to have_http_status(:ok)
    end
  end

  # ------------------------------------------------------------
  # CREATE (success path)
  # ------------------------------------------------------------
  describe "POST /events" do
    it "creates an event and redirects to dashboard" do
      expect do
        post events_path,
             params: {
               event: {
                 event_name: "New Event",
                 description: "Test event",
                 event_date: Date.today,
                 location: "Home",
                 budget: "100"
               }
             }
      end.to change(Event, :count).by(1)

      expect(response).to redirect_to(dashboard_path)
    end
  end

  # ------------------------------------------------------------
  # SHOW
  # ------------------------------------------------------------
  describe "GET /events/:id" do
    it "shows an event" do
      get event_path(event)
      expect(response).to have_http_status(:ok)
    end
  end

  # ------------------------------------------------------------
  # UPDATE (success path)
  # ------------------------------------------------------------
  describe "PATCH /events/:id" do
    it "updates the event and redirects" do
      patch event_path(event),
            params: {
              event: {
                event_name: "Updated Name"
              }
            }

      expect(response).to redirect_to(event_path(event))
      expect(event.reload.event_name).to eq("Updated Name")
    end
  end

  # ------------------------------------------------------------
  # DESTROY
  # ------------------------------------------------------------
  describe "DELETE /events/:id" do
    it "deletes the event and redirects" do
      expect do
        delete event_path(event)
      end.to change(Event, :count).by(-1)

      expect(response).to redirect_to(events_path)
    end
  end

  # ------------------------------------------------------------
  # AUTHORIZATION FAILURE
  # ------------------------------------------------------------
  describe "authorization protection" do
    it "redirects when user cannot manage the event" do
      allow_any_instance_of(Event)
        .to receive(:can_manage_event?)
              .and_return(false)

      get edit_event_path(event)

      expect(response).to redirect_to(event_path(event))
    end
  end
end
