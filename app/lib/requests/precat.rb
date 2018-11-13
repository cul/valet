module Requests
  module Precat

    # Are any of this bib's holdings in the precat location?
    def bib_eligible?(bib_record = nil)
      precat_holdings = get_precat_holdings(bib_record)
      return true if precat_holdings.size > 0
      
      flash.now[:default] = '<h5>This item is not in PreCat.
        <br><br>  Please 
        <a href="http://library.columbia.edu/services/askalibrarian.html">
          ask a librarian
        </a> 
        or ask for assistance at a service desk.</h5>'.html_safe
      return false
    end
    
    def setup_form_locals(bib_record)
      # We'll want to give lots of info details about the
      # precat holding and it's availability
      precat_holdings = get_precat_holdings(bib_record)
      availability ||= bib_record.fetch_voyager_availability
      available_items = get_available_items(precat_holdings.first, availability)
      locals = { 
        bib_record: bib_record,
        holding: precat_holdings.first,
        available: (available_items.count > 0)
      }
      return locals
    end
    
    # What do we do with the results of the Precat request form?
    # - mail search details to staff, patron
    # - redirect to confirmation page
    def form_handler(params, bib_record)
      holding = get_precat_holdings(bib_record).first

      precat_params = {
        bib_record: bib_record, 
        location_name: holding[:location_display],
        location_code: holding[:location_code],
        note:  params[:note],
        patron_email: current_user.email,
        staff_email: APP_CONFIG[:precat][:staff_email],
      }
      # mail search details to staff, patron
      FormMailer.with(precat_params).precat.deliver_now
      # redirect patron browser to confirm webpage
      render 'precat_confirm', locals: precat_params
    end

    def get_precat_holdings(bib_record)
      precat_location = APP_CONFIG[:precat][:location_code]
      return get_holdings_by_location_code(bib_record, precat_location)
    end
    
    
  end
end