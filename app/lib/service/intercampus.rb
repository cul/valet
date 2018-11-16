module Service
  class Intercampus < Service::Base

    # InterCampus is just a direct bounce
    # to a hardcoded LWeb URL
    def build_service_url(params, bib_record, current_user)
      return APP_CONFIG[:intercampus][:bounce_url]
    end
    
  end
end