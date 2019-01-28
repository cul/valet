class BorrowdirectController < ApplicationController

  before_action :authenticate_user!
  
  # CUMC staff who have not completed security training
  # may not use authenticated online request services.
  before_action :cumc_block
  
  def show
    @config = APP_CONFIG['borrowdirect']

    # validate user
    return redirect_to @config[:login_failure_url] unless valid_user?

    # validate requested bib
    # If no bib is passed, that's ok, we'll just redirect to BD home page.
    # If bib is passed, it needs to pass validation.
    bib_id = params['id']
    bib_record = nil
    if bib_id.present?
      bib_record = ClioRecord.new_from_bib_id(bib_id)
      return error("Cannot find bib record (#{bib_id})") unless valid_bib?(bib_record)
    end

    # setup logdata 
    logdata = {}
    
    # build the relais redirect url (and add to logdata)
    redirect_url = build_service_url(params, bib_record, current_user, logdata)
    
    # log
    log_borrowdirect(params, bib_record, current_user, logdata)
    
    # bounce patron to Relais
    return redirect_to redirect_url
  end

  private
  
  def valid_user?
    # There must be a Voyager patron record for the current user
    return false unless current_user.patron_record

    # The patron record must have valid borrowing privileges
    return false if current_user.patron_expired?
    return false if current_user.patron_blocked?
    return false if current_user.patron_has_recalls?

    # Patrons in any of these patron groups may use Borrow Direct
    return true if ['GRD','OFF','REG','SAC'].include?(current_user.patron_group)

    # 2CUL patrons may use Borrow Direct
    return true if current_user.patron_2cul?
    
    # Any other patrons are not permitted to use the Borrow Direct service
    return false
  end

  # Don't enforce valet-layer bib validation.
  # The CLIO OPAC displays the Borrow Direct service link conditionally,
  # and the Relais BD endpoint also verifies that items is unavailable locally.
  def valid_bib?(bib_record)
    return false unless bib_record
    return true
  end

  # Borrow Direct bounces to Relais D2D,
  # with the following fields:
  # LS - Library Symbol (hardcoded:  COLUMBIA)
  # PI - Patron Identifier (Voyager Barcode)
  # query - query by isbn, issn, or title/author, see:
  # https://relais.atlassian.net/wiki/spaces/ILL/pages/132579329/Using+other+discovery+tools
  # A full example is: https://bd.relaisd2d.com/?LS=COLUMBIA&PI=123456789&query=ti%3D%22Piotr%22+and+au%3D%22Sokorski%2C+Wodzimierz%22
  #
  def build_service_url(_params, bib_record, current_user, logdata)
    # (pass along logdata - so that we can log query-construction details)
    url = 'https://bd.relaisd2d.com/'
    url += '?LS=COLUMBIA'
    url += '&PI=' + current_user.barcode
    if bib_record.present?
      url += '&query=' + build_query(bib_record, logdata)
    end
    url
  end

  def build_query(bib_record, logdata)
    query = ''
    if bib_record.issn.present?
      logdata[:query] = 'issn'
      query = 'issn=' + bib_record.issn.first
    elsif bib_record.isbn.present?
      logdata[:query] = 'isbn'
      query = 'isbn=' + bib_record.isbn.first
    else
      query = 'ti="' + bib_record.title + '"'
      logdata[:query] = 'ti'
      if bib_record.author.present?
        logdata[:query] = 'ti/au'
        query += ' and au="' + bib_record.author + '"'
      end
    end
    relais_escape(query)
  end

  def relais_escape(string)
    # standard Rails CGI param escaping...
    string = CGI.escape(string)
    # ...but then also use %20 instead of + for spaces
    string.gsub!(/\+/, '%20')
    string
  end
  
  def log_borrowdirect(params, bib_record, current_user, logdata)
    data = { set: @config[:label] || 'Borrow Direct'}
    
    # basic request data - ip, timestamp, etc.
    data.merge! request_data
raise
    # the 'logdata' key is service-specific data.
    # the query is the type of Relais query - will be blank if no bib passed
    query = logdata[:query] || ''
    # - tell about the user
    logdata =  {user: current_user.login || ''}
    logdata.merge!(patron_barcode: (current_user.barcode || '') )
    # - tell about the bib, if there is one
    if bib_record.present?
      logdata.merge! bib_record.basic_log_data
    end
    # - tell about the query, last
    logdata.merge!(query: query)
    # logdata is stored as in JSON
    data[:logdata] = logdata.to_json

    begin
      # If logging fails, don't die - report the error and continue
      Log.create(data)
    rescue => ex
      Rails.logger.error "BorrowdirectController#log error: #{ex.message}"
      Rails.logger.error data.inspect
    end
    
  end
  
end
