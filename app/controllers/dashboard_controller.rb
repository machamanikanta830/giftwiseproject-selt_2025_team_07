# app/controllers/dashboard_controller.rb
class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @tab = params[:tab].presence_in(%w[events recipients profile]) || "events"

    if @tab == "recipients"
      @recipient = Recipient.new
      @search_query = params[:q].to_s.strip

      scope = current_user.recipients.order(:name)

      if @search_query.present?
        like = "%#{@search_query}%"
        scope = scope.where(
          "name LIKE ? OR email LIKE ? OR relationship LIKE ?",
          like, like, like
        )
      end

      @recipients = scope
    end
  end
end
