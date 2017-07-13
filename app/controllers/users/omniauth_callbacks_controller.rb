class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController

  include Cul::Omniauth::Callbacks

  def affiliations(user, affils)
    return unless user
    user.affils = affils.sort
  end

end
