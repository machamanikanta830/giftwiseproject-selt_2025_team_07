class HomeController < ApplicationController
  def index
    if respond_to?(:current_user) && current_user
      redirect_to dashboard_path
    else
      render :index
    end
  end
end