module Service
  class RecapLoan < Service::Base

    # For the ReCAP services, use the offsite_elibible? logic from User model
    def patron_eligible?(current_user = nil)
      current_user.offsite_eligible?
    end

    # May this bib be requested from Offsite?
    def bib_eligible?(bib_record = nil)
      bib_record.offsite_holdings.size > 0
    end


  end
end
