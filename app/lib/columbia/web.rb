
module Columbia
  class Web

    # Tocs live at URLs like this:
    #   http://www.columbia.edu/cgi-bin/cul/toc.pl?CU12731471
    # But that URL will return a status 200 html page for 
    # any input argument.  We'll need to text-scan the response
    # body to determine if it's a true TOC.

    # Invoked like so:
    # conn = Columbia::Web.open_connection()
    # toc = Columbia::Web.get_toc_link(barcode, conn)

    HOST = 'http://www.columbia.edu'
    TOCURL = '/cgi-bin/cul/toc.pl'

    def self.open_connection
      conn = Faraday.new(url: HOST)
      raise "Faraday.new(#{HOST}) failed!" unless conn
      return conn
    end

    def self.get_toc_link(barcode = nil, conn = nil)
      raise "Columbia::Web.get_toc_link() got nil barcode" if barcode.blank?

      conn ||= Faraday.new(url: HOST)
      raise "Faraday.new(#{HOST}) failed!" unless conn

      tocpath = "#{TOCURL}?#{barcode}"
      response = conn.get(tocpath)

      if response.status != 200
        Rails.logger.error "conn.get(#{tocpath}) got status #{response.status}"
        return nil
      end

      if response.body.include? barcode
        return HOST + tocpath
      else
        return nil
      end
    end

  end
end


