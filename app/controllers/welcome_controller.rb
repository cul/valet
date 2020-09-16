class WelcomeController < ApplicationController
  # For now, only staff/admins see the Valet home page
  layout 'admin'

  def index
  end

  def logout
  end
end
