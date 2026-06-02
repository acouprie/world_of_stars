class ApplicationController < ActionController::Base
  include Authentication
  allow_browser versions: :modern unless Rails.env.test?

  before_action :set_locale

  rescue_from ActiveRecord::RecordNotFound, with: :not_found

  private

  def not_found
    render template: "errors/not_found", layout: "error", status: :not_found
  end

  def set_locale
    requested = cookies[:locale]
    I18n.locale = if I18n.available_locales.map(&:to_s).include?(requested.to_s)
      requested.to_sym
    else
      I18n.default_locale
    end
  end
end
