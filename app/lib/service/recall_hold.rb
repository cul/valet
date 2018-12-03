module Service
  class RecallHold < Service::Base

    # Recall / Hold just throws the user to a Voyager page
    def build_service_url(_params, bib_record, _current_user)
      return APP_CONFIG[:recall_hold][:voyager_url] + bib_record.id
    end

    # Is this bib subject to hold/recall?
    def bib_eligible?(bib_record = nil)
      # Only Voyager records
      unless bib_record.voyager?
        self.error = "This catalog record is not owned by Columbia.<br><br>Recall / Hold services are only available for Columbia material."
        return false 
      end
      
      availability = bib_record.fetch_voyager_availability
      if availability.all? { |item| item[1] == 'Available'  }
        self.error = "All available copies of this bib are available.<br><br>Recall / Hold services are only possible for checked-out items."
        return false 
      end
      
      return true
    end

    # def patron_eligible?(current_user = nil)
    #   return true
    # end

  end
end


