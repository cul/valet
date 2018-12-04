
class FormsController < ApplicationController
  # The FormsController handles many different services.
  # Initialize based on active service.
  before_action :initialize_service

  # CUMC staff who have not completed security training
  # may not use authenticated online request services.
  before_action :cumc_block

  # Given a bib record id as an 'id' param,
  # Lookup bibliographic information on that bib,
  # Lookup form details in app_config,
  # Either:
  # - build an appropriate form
  # - bounce directly to URL
  def show
    # validate user
    return error("Current user is not elible for service #{@config['label']}") unless @service.patron_eligible?(current_user)

    # validate bib record
    bib_id = params['id']
    bib_record = ClioRecord.new_from_bib_id(bib_id)
    return error("Cannot find bib record for id #{bib_id}") if bib_record.blank?
    return error("Bib ID #{bib_id} is not eligble for service #{@config['label']}") unless @service.bib_eligible?(bib_record)

    # process as form or as direct bounce
    case @config['type']
    when 'form'
      return build_form(bib_record)
    when 'bounce'
      return bounce(bib_record)
    else
      return error("No 'type' defined for service #{@config['label']}")
    end

    error("Valet error: unknown show() failure for service #{@config['label']}")
  end

  # form processor
  # we've collected data from the patron,
  # now create the service request.
  # (which means either redirecting or emailing)
  # possibly land on confirm page.
  def create
    bib_id = params['id']
    bib_record = ClioRecord.new_from_bib_id(bib_id)

    # All should log, so that should happen here.
    # (should add service-specific fields)
    log(bib_record, current_user)

    # Service may want to send emails.
    @service.send_emails(params, bib_record, current_user)

    # Now that we have user-input params,
    # the service may want to redirect to an external URL
    redirect_url = @service.build_service_url(params, bib_record, current_user)
    return redirect_to redirect_url if redirect_url.present?

    # Service may want to render a confirm page
    confirm_params = @service.get_confirm_params(params, bib_record, current_user)
    return render(confirm_params) if confirm_params.present?

    # If the service didn't render or redirect??
    error("Service #{@config.service} ")

    # # For now, just send it to the service module,
    # # with the most commonly used args - the bib and the user
    # @service.form_handler(params, bib_record, current_user)
  end

  private

  # SERVICE HANDLING

  # called in before_action
  def initialize_service
    service = determine_service
    return error('Unable to determine service!') unless service
    load_service_config(service)
    # load_service_module(service)
    authenticate_user! if @config[:authenticate]
    instantiate_service_object(service)
  end

  # Original path is something like:  /docdel/123
  # which rails will route to:        /forms/123
  # Recover our service from the original path,
  # store in session
  def determine_service
    original = request.original_fullpath
    return unless original && original.starts_with?('/')
    # '/docdel/123'  ==>  [ '', 'docdel', '123' ]
    service = original.split('/')[1]
    service
  end

  def load_service_config(service)
    Rails.logger.debug "load_service_config() for #{service}..."
    @config = APP_CONFIG[service]
    # store the service key within the config hash
    @config[:service] = service
    return error("Can't find configuration for: #{service}") unless @config.present?
  end

  # # Dynamically prepend the module methods for the active service
  # # so that calling the un-scoped method names, e.g.
  # #   build_service_url()
  # # will call the build_service_url() method of the active service.
  # def load_service_module(service)
  #   service_module_name = "Service::#{service.camelize}"
  #   Rails.logger.debug "self.class prepend #{service_module_name}"
  #   service_module = service_module_name.constantize rescue nil
  #   return error("Cannot load service module for #{@config['label']}") unless service_module.present?
  #   self.class.send :prepend, service_module_name.constantize
  # end

  def instantiate_service_object(service)
    service_class_name = "Service::#{service.camelize}"
    Rails.logger.debug "instatiating class #{service_class_name}"
    service_class_instance = begin
                               service_class_name.constantize
                             rescue
                               nil
                             end
    return error("Cannot constantize #{service_class_name}") if service_class_instance.nil?
    @service = service_class_instance.new
  end

  # CUMC staff who have not completed security training
  # may not use authenticated online request services.
  def cumc_block
    return unless current_user && current_user.affils
    return error('Internal error - CUMC Block config missing') unless APP_CONFIG[:cumc]
    if current_user.has_affil(APP_CONFIG[:cumc][:block_affil])
      Rails.logger.info "CUMC block: #{current_user.login}"
      return redirect_to APP_CONFIG[:cumc][:block_url]
    end
  end

  # HELPER METHODS

  # Process a 'form' service
  # - setup service-specific local variables for the form
  # - render the service-specific form
  def build_form(bib_record = nil)
    locals = @service.setup_form_locals(bib_record)
    # render @config[:service], locals: {bib_record: bib_record}
    render @config[:service], locals: locals
  end

  # Process a 'bounce' service.
  # - build the bounce URL
  # - log
  # - redirect the user
  def bounce(bib_record = nil)
    bounce_url = @service.build_service_url(params, bib_record, current_user)
    if bounce_url.present?
      log(bib_record, current_user)
      Rails.logger.debug "bounce() redirecting to: #{bounce_url}"
      return redirect_to bounce_url
    end

    # Unable to build a bounce URL?  Error!
    error("Cannot determine bounce url for service #{@config['label']}")
  end

  # DEFAULT LOGGING
  # We'll probably need to support custom logging as well
  def log(bib_record = nil, current_user = nil)
    # basic request data - ip, timestamp, etc.
    data = request_data

    # which log set?
    data[:set] = @config['label']

    # build up logdata for this specific transation
    # - tell about the bib
    logdata = bib_record.basic_log_data
    # - tell about the user
    login = current_user.present? ? current_user.login : ''
    logdata[:user] = login
    # logdata is stored as in JSON
    data[:logdata] = logdata.to_json

    # Log it!
    begin
      # If logging fails, don't die - report the error and continue
      Log.create(data)
    rescue => ex
      Rails.logger.error "FormsController#bounce error: #{ex.message}"
      Rails.logger.error data.inspect
    end
  end

  # Let caller just do:
  #    if broken() return error("Broken!")
  # instead of multi-line if/end
  def error(message)
    flash.now[:error] = message
    service_error = begin
                      @service.error
                    rescue
                      ''
                    end
    render :error, locals: { service_error: service_error }
  end
end
