class ErrorsController < ApplicationController
  allow_unauthenticated_access
  layout "error"

  def not_found
    render status: :not_found
  end

  def unprocessable_entity
    render status: :unprocessable_entity
  end

  def internal_server_error
    render status: :internal_server_error
  end

  def bad_request
    render status: :bad_request
  end
end
