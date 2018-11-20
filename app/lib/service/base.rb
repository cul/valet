module Service
  class Base

    attr_accessor :error
    
    # DEFAULT METHOD IMPLEMENTATIONS
    # They may be overridden in service-specific modules.

    def patron_eligible?(current_user = nil)
      Rails.logger.debug "patron_eligible? - DEFAULT"
      return true
    end

    def bib_eligible?(bib_record = nil)
      return true
    end

    def build_service_url(params, bib_record, current_user)
      return nil
    end
    
    def get_confirm_params(params, bib_record, current_user)
      return {}
    end

    def setup_form_locals(bib_record = nil)
      locals = { bib_record: bib_record }
      return locals
    end


    # COMMON LOGIC
    # Generic methods called by different service modules

    def get_holdings_by_location_code(bib_record = nil, location_code = nil)
      return [] if bib_record.blank? or bib_record.holdings.blank?
      return [] if location_code.blank?

      found_holdings = []
      bib_record.holdings.each do |holding|
        found_holdings << holding if holding[:location_code] == location_code
      end
      return found_holdings
    end

    # Accept either a single holding or an array of holdings,
    # return an array of all available items within the holding(s).
    def get_available_items(holding, availability)
      return [] if holding.blank? || availability.blank?

      available_items = []
      Array.wrap(holding).each do |each_holding|
        each_holding[:items].each do |item|
          available_items << item if availability[ item[:item_id] ] == 'Available'
        end
      end
      return available_items
    end

  end

end

