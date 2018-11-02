class FormsController < ApplicationController

  # Given a bibkey as an 'id' param,
  # Lookup bibliographic information on that bib,
  # Lookup form details in app_config,
  # Either:
  # - build an appropriate form
  # - bounce directly to URL
  def show
    determine_service
    config = get_service_config
    
    raise
  end
  
  # 
  def create
    config = get_service_config
  end

  private

  def get_service_config
    # fetch configuration for the stored service key
    return APP_CONFIG[ session[:service] ]
  end

  # Original path is something like:  /docdel/123
  # which rails will route to:        /forms/123
  # Recover our service from the original path,
  # store in session
  def determine_service
    original = request.original_fullpath
    return unless original && original.starts_with?('/')
    # '/docdel/123'  ==>  [ '', 'docdel', '123' ]
    session[:service] = original.split('/')[1]
  end


end


