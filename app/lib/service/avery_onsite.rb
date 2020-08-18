module Service
  class AveryOnsite < Service::Base

    # For the ReCAP services, use the offsite_elibible? logic from User model
    def patron_eligible?(current_user = nil)
      return false unless current_user && current_user.affils

      permitted_affils = APP_CONFIG[:avery_onsite][:permitted_affils] || []
      permitted_affils.each do |affil|
        return true if current_user.affils.include?(affil)
      end
      return false
    end


    def bib_eligible?(bib_record = nil)
      avery_onsite_holdings = bib_record.holdings.select do |holding|
        APP_CONFIG[:avery_onsite][:locations].include?( holding[:location_code] )
      end

      return true if avery_onsite_holdings.present?

      self.error = "This record has no Avery holdings.
      <br><br>
      This service is for the request of Avery materials only."

      return false
    end

    def setup_form_locals(params, bib_record, current_user)
      avery_onsite_holdings = bib_record.holdings.select do |holding|
        APP_CONFIG[:avery_onsite][:locations].include?( holding[:location_code] )
      end

      # If there's only one holding with only one item, pre-select that item
      filter_barcode = nil
      if avery_onsite_holdings.size == 1
        if avery_onsite_holdings.first[:items].size == 1
          filter_barcode = avery_onsite_holdings.first[:items].first[:barcode]
        end
      end

      locals = {
        bib_record: bib_record,
        holdings: avery_onsite_holdings,
        filter_barcode: filter_barcode
      }
    end



    def send_emails(params, bib_record, current_user)
      mail_params = {
        bib_record: bib_record,
        barcodes:  params[:itemBarcodes],
        patron_uni: current_user.uid,
        patron_email: current_user.email,
        staff_email: APP_CONFIG[:avery_onsite][:staff_email]
      }
      # mail request to staff
      FormMailer.with(mail_params).avery_onsite_request.deliver_now
      # # mail confirm to patron
      # FormMailer.with(mail_params).avery_onsite_confirm.deliver_now
    end


  end
end


