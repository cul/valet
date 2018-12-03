
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

    HOST = 'http://www.columbia.edu'.freeze
    TOCURL = '/cgi-bin/cul/toc.pl'.freeze
    TOCLISTURL = '/cgi-bin/cul/toclist.pl'.freeze

    def self.open_connection
      conn = Faraday.new(url: HOST)
      raise "Faraday.new(#{HOST}) failed!" unless conn
      conn
    end

    def self.get_toc_link(barcode = nil, conn = nil)
      raise 'Columbia::Web.get_toc_link() got nil barcode' if barcode.blank?

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

    def self.get_bib_toc_links(bib = nil, conn = nil)
      raise 'Columbia::Web.get_bib_toc_links() got nil bib' if bib.blank?

      conn ||= Faraday.new(url: HOST)
      raise "Faraday.new(#{HOST}) failed!" unless conn

      tocpath = "#{TOCLISTURL}?bib=#{bib}"
      response = conn.get(tocpath)

      if response.status != 200
        Rails.logger.error "conn.get(#{TOCLISTURL}) got status #{response.status}"
        return nil
      end

      barcodeList = JSON.parse(response.body)
      tocLinkHash = {}
      barcodeList.each do |barcode|
        tocLinkHash[barcode] = "#{HOST}#{TOCURL}?#{barcode}"
      end

      tocLinkHash
    end
  end
end
