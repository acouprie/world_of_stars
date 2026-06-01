class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to root_path, alert: I18n.t("flash.sessions.too_many_attempts") }

  def create
    if user = User.authenticate_by(params.permit(:email_address, :password))
      start_new_session_for user
      redirect_to after_authentication_url
    else
      redirect_to root_path, alert: t("flash.sessions.invalid_credentials")
    end
  end

  def destroy
    terminate_session
    redirect_to root_path, status: :see_other
  end
end
