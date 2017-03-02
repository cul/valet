class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  include Devise::Controllers::Helpers
  devise_group :user, contains: [:user]
  # before_filter :authenticate_user!, if: :devise_controller?
  before_filter :authenticate_user!

end
