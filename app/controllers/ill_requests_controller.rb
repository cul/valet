class IllRequestsController < ApplicationController
  before_action :authenticate_user!

  before_action :confirm_ill_eligibility!, except: [ :ineligible, :error ]

  def index
    redirect_to action: 'affiliation'
  end

  # 1) Collect affiliation
  def affiliation
    # If a bib is passed, we'll want to pass that along in the form
    @bib_id = params['bib_id']

    # Do we want to fetch bibliographic metadata to display with affilation form?
    @clio_record = @bib_id ? ClioRecord::new_from_bib_id(@bib_id) : nil
  end
  
  # 2) Collect bib
  def bib
    bib_id = params['bib_id']
    @affiliation = params['affiliation']

    # If we don't have an affiliation yet, bounce back to step #1
    if @affiliation.blank?
      # continue to pass along bib_id, but no other params
      params = { bib_id: bib_id}
      return redirect_to affiliation_ill_requests_path params
    end

    # If our affiliation is Law or Teacher's College, redirect outwards
    if @affiliation == 'law'
      return redirect_to 'http://www.law.columbia.edu/library'
    end
    if @affiliation == 'tc'
      return redirect_to 'http://library.tc.columbia.edu/request.php'
    end
    
    # If we already have a bib (e.g. passed in from CLIO), skip to step #3
    if bib_id.present?
      params = { affiliation: @affiliation, bib_id: bib_id }
      return redirect_to new_ill_request_path params
    end
    
    # drop-through to the form to collect the bib id
  end
  
  # 3) Using the bib and affiliation, create new ILL request
  def new
    bib_id = params['bib_id']
    affiliation = params['affiliation']
    
     # If we don't have an affiliation yet, bounce back to step #1
     if affiliation.blank?
       # continue to pass along bib_id, but no other params
       params = { bib_id: bib_id}
       return redirect_to affiliation_ill_requests_path params
     end

     # If we don't have a bib yet, bounce back to step #2
     if bib_id.blank?
       # continue to pass along bib_id, but no other params
       params = { affiliation: affiliation}
       return redirect_to bib_ill_requests_path params
     end
    
     # If we've got both affiliation and bib,
     # we can create a new ILL request
    
     @affiliation_code = case affiliation
     when /geo|mbuts/
       'zcu'
     when /mcc/
       'zch'
     else
       raise 'IllRequestsController#new() unexpected affiliation value [affiliation]'
     end
    
     @clio_record = ClioRecord::new_from_bib_id(bib_id)
     openurl = @clio_record.openurl
    
     ezproxy_url = 'https://www1.columbia.edu/sec-cgi-bin/cul/prox/ezpwebserv-ezproxy.cgi'
     illiad_url  = 'https://columbia.illiad.oclc.org/illiad/' + 
                   @affiliation_code + '/illiad.dll/OpenURL'
     @redirect_url = ezproxy_url + '?url=' + illiad_url + '?' + openurl
  end

  def ineligible
  end

  def error
  end

  private

  def confirm_ill_eligibility!
    redirect_to ineligible_ill_requests_path unless current_user
    redirect_to ineligible_ill_requests_path unless current_user.ill_eligible?
  end


end


