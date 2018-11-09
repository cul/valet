module Requests
  module Intercampus

    # InterCampus is just a direct bounce
    # to a hardcoded LWeb URL
    def build_bounce_url(bib_record = nil)
      return @config[:bounce_url]
    end
    
  end
end