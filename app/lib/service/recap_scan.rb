module Service
  class RecapScan < Service::Base

    # For the ReCAP services, use the offsite_elibible? logic from User model
    def patron_eligible?(current_user = nil)
      current_user.offsite_eligible?
    end

    # May this bib be requested from Offsite?
    def bib_eligible?(bib_record = nil)
      bib_record.offsite_holdings.size > 0
    end

    def setup_form_locals(params, bib_record, current_user)
      # find the holding being requested
      target_holding = bib_record.holdings.select do |holding|
        holding[:mfhd_id] == params[:mfhd_id]
      end.first
      
      # form has special handling for zero-available-items
      available_count = 0
      target_holding[:items].each do |item|
        available_count += 1 if (bib_record.fetch_scsb_availabilty[item[:barcode]] == 'Available')
      end
      
      # pass along the bib and the holding being requested
      locals = {
        bib_record: bib_record,
        holding: target_holding,
        available_count: available_count
      }
      locals
    end


    # Service-specific form-param handling, before any email or confirm screen.
    # For ReCAP services, this is where the actual SCSB API request is made.
    def service_form_handler(params)
      service_response = Recap::ScsbRest.request_item(params)
    end


    # Basic request data (bib, user, datestamp, IP) is automatically logged.
    # Services may return a hash of additional data to be logged.
    def get_extra_log_params(params)
      extra_log_params = {}
      
      extra_log_params['patronBarcode'] = params['patronBarcode']
      extra_log_params['emailAddress'] = params['emailAddress']
      
      success = params['service_response']['success'] ||  params['service_response']['error'] || 'false'
      extra_log_params['success'] = success

      screenMessage = params['service_response']['screenMessage'] ||  params['service_response']['message'] || ''
      extra_log_params['screenMessage'] = screenMessage

      extra_log_params['requestType'] = params['requestType']

      extra_log_params['itemOwningInstitution'] = params['itemOwningInstitution']
      extra_log_params['itemBarcodes'] = Array(params['itemBarcodes']).join(' / ')
      extra_log_params['callNumber'] = params['callNumber']

      extra_log_params
    end
    
    def send_emails(params, bib_record, current_user)
      # Call recap_scan_confirm() method of /app/mailers/form_mailer.rb
      # Pass along all our params to be used in email subject and 
      # email body template (views/form_mailer/recap_scan_confirm.text.erb)
      FormMailer.with(params).recap_scan_confirm.deliver_now
    end
    
    # The ReCAP services will give the patrons a confirmation screen,
    # so they need to define a locals hash for the template
    def get_confirmation_locals(params, bib_record, current_user)
      confirm_locals = {
        params: params
        # bib_record: bib_record,
        # barcodes:  params[:itemBarcodes],
        # patron_uni: current_user.uid,
        # patron_email: current_user.email,
        # staff_email: APP_CONFIG[:bearstor][:staff_email]
      }
      confirm_locals
    end


  end
end
