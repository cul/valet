module Service
  class Bearstor < Service::Base

    # Is the current patron allowed to use the 
    # BearStor offsite request paging service?
    def patron_eligible?(current_user = nil)
      # For now, any authenticated user may use Bearstor
      return true;
    end

    # May this bib be requested from Bearstor?
    def bib_eligible?(bib_record = nil)
      # Only records with bearstor holdings
      # which include an available item
      availability ||= bib_record.fetch_voyager_availability
      
      bearstor_holdings = get_bearstor_holdings(bib_record)
      if bearstor_holdings.size == 0
        self.error = "This item has no BearStor holdings.
        <br><br>
        Only items stored in Barnard's remote storage facility
        may be requested via BeatStor."
        return false
      end
      
      bearstor_holdings.each do |holding|
        available_items = get_available_items(holding, availability)
        return true if available_items.size > 0
      end

      flash.now[:default] = "* No available BearStor items for this record"
      return false
    end


    def setup_form_locals(bib_record)
      availability ||= bib_record.fetch_voyager_availability
      bearstor_holdings = get_bearstor_holdings(bib_record)
      available_bearstor_items = get_available_items(bearstor_holdings, availability)
      filter_barcode = nil
      if available_bearstor_items.count == 1
        filter_barcode = available_bearstor_items.first[:barcode]
      end
      locals = { 
        bib_record: bib_record,
        bearstor_holdings: bearstor_holdings,
        filter_barcode: filter_barcode,
      }
      return locals
    end


    def send_emails(params, bib_record, current_user)
      mail_params = {
        bib_record: bib_record, 
        barcodes:  params[:itemBarcodes],
        patron_uni: current_user.uid,
        patron_email: current_user.email,
        staff_email: APP_CONFIG[:bearstor][:staff_email]
      }
      # mail request to staff
      FormMailer.with(mail_params).bearstor_request.deliver_now
      # mail confirm to patron
      FormMailer.with(mail_params).bearstor_confirm.deliver_now
    end
    
    def get_confirm_params(params, bib_record, current_user)
      #   # redirect patron browser to confirm webpage
      #   render 'bearstor_confirm', locals: bearstor_params
      confirm_locals = {
        bib_record: bib_record, 
        barcodes:  params[:itemBarcodes],
        patron_uni: current_user.uid,
        patron_email: current_user.email,
        staff_email: APP_CONFIG[:bearstor][:staff_email]
      }
      confirm_params = {
        template: '/forms/bearstor_confirm',
        locals:   confirm_locals
      }
      return confirm_params
    end

    def get_bearstor_holdings(bib_record)
      bearstor_location = APP_CONFIG[:bearstor][:location_code]
      return get_holdings_by_location_code(bib_record, bearstor_location)
    end
    
  end
end