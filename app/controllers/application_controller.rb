class ApplicationController < ActionController::Base
  include Authentication
  allow_browser versions: :modern unless Rails.env.test?
end
