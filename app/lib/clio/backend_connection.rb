# Call CLIO-Backend, 
# which queries Voyager database for /status and /circ-status
module Clio
  class BackendConnection

    # Lots borrowed from CLIO Spectrum
    def backend_httpclient
      hc = HTTPClient.new
      # The default is to wait 60/120 seconds - but we expect an instant response,
      # anything else means trouble, and we should give up immediately so as not
      # to not sit on resources.
      hc.connect_timeout = 10 # default 60
      hc.send_timeout    = 10 # default 120
      hc.receive_timeout = 10 # default 60
      hc
    end


    def get_circ_status(id = nil)
      return {} unless id.present? && id.match(/^\d+$/)
      
      backend_config = APP_CONFIG['clio_backend_connection_details']
      unless backend_config.present? && backend_config['url'].present?
        Rails.logger.error "Missing CLIO Backend config!"
        return {}
      end

      backend_url = backend_config['url'] + '/holdings/circ_status/' + id

      begin
        json_results = backend_httpclient.get_content(backend_url)
        backend_results = JSON.parse(json_results).with_indifferent_access
      rescue => ex
        logger.error "Clio::BackendConnection#circ_status #{ex} URL: #{backend_url}"
        return nil
      end

      if backend_results.nil? or backend_results.empty?
        logger.error "Clio::BackendConnection#circ_status URL: #{backend_url} nothing returned"
        return nil
      end

      # data retrieved successfully...
      return backend_results
    end


    def get_availability(id)
      circ_status = get_circ_status
      
      # Simplify circ_status to just available/unavailable
      
      
    end

    # Called like this:
    #   @voyager_availability = Clio::Backend.get_bib_availability(self.key) || {}
    # Discard 
      

  end
end