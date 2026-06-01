class UsersController < ApplicationController
  allow_unauthenticated_access only: [:create]

  def create
    @user = User.new(user_params)
    if @user.save
      Users::OnboardingService.new(@user).call
      start_new_session_for @user
      redirect_to after_authentication_url
    else
      redirect_to root_path(tab: :register), alert: @user.errors.full_messages.to_sentence
    end
  end

  private

  def user_params
    params.permit(:email_address, :username, :password, :password_confirmation)
  end
end
