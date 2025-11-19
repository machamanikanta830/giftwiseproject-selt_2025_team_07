class ProfilesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user

  def edit
  end

  def update
    attrs = profile_params.dup

    if attrs[:password].blank? && attrs[:password_confirmation].blank?
      attrs.delete(:password)
      attrs.delete(:password_confirmation)
    end

    if @user.update(attrs)
      redirect_to dashboard_path, notice: "Profile updated successfully"
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  def set_user
    @user = current_user
  end

  def profile_params
    params.require(:user).permit(
      :name,
      :email,
      :date_of_birth,
      :phone_number,
      :gender,
      :occupation,
      :hobbies,
      :likes,
      :dislikes,
      :password,
      :password_confirmation
    )
  end
end
