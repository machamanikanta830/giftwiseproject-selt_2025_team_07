class PasswordsController < ApplicationController
  before_action :set_user

  def edit
  end

  def update
    if @user.update(password_params)
      redirect_to dashboard_path, notice: "Password updated successfully"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = current_user
  end

  def password_params
    params.require(:user).permit(:password, :password_confirmation)
  end
end
