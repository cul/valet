module Requests
  module RecallHold

    # Recall / Hold just throws the user to a Voyager page
    def build_bounce_url(bib_record)
      return @config[:voyager_url] + bib_record.key
    end

    def patron_eligible?(current_user = nil)
      Rails.logger.debug "patron_eligible? - RECALL-HOLD"
      return true
    end

  end
end


