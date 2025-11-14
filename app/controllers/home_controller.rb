class HomeController < ApplicationController
  def index
    if respond_to?(:current_user) && current_user
      redirect_to dashboard_path
    else
      # explicit, just to be clear
      render :index
    end
  end
end
