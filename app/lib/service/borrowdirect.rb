module Service
  class Borrowdirect < Service::Base

    # Borrow Direct bounces to Relais D2D, 
    # with the following fields:
    # LS - Library Symbol (hardcoded:  COLUMBIA)
    # PI - Patron Identifier (Voyager Barcode)
    # query - query by isbn, issn, or title/author, see:
    # https://relais.atlassian.net/wiki/spaces/ILL/pages/132579329/Using+other+discovery+tools
    # A full example is: https://bd.relaisd2d.com/?LS=COLUMBIA&PI=123456789&query=ti%3D%22Piotr%22+and+au%3D%22Sokorski%2C+Wodzimierz%22
    # 
    def build_service_url(params, bib_record, current_user)
      url = 'https://bd.relaisd2d.com/'
      url += '?LS=COLUMBIA'
      url += '&PI=' + current_user.barcode
      url += '&query=' + build_query(bib_record)
      return url
    end

    def build_query(bib_record)
      query = ''
      if bib_record.issn.present?
        query = 'issn=' + bib_record.issn.first
      elsif bib_record.isbn.present?
        query = 'isbn=' + bib_record.isbn.first
      else
        query = 'ti=' + bib_record.title
        if bib_record.author.present?
          query += ' and au=' + bib_record.author
        end
      end
      return relais_escape(query)
    end
    
    def relais_escape(string)
      # standard Rails CGI param escaping...
      string = CGI.escape(string)
      # ...but then also use %20 instead of + for spaces
      string.gsub!( /\+/, '%20')
      return string
    end
    
    # def patron_eligible?(current_user = nil)
    #   Rails.logger.debug "patron_eligible? - BorrowDirect"
    #   return true
    # end

  end
end


