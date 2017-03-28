class OffsiteRequestsController < ApplicationController
  before_action :set_offsite_request, only: [:show, :edit, :update, :destroy]

  # before_filter :authenticate_user!, if: :devise_controller?
  before_filter :authenticate_user!


  # GET /offsite_requests
  # GET /offsite_requests.json
  def index
    redirect_to action: 'bib'
  end

  # GET /offsite_requests/1
  # GET /offsite_requests/1.json
  def show
  end

  # Get a bib_id from the user
  def bib
    # If a bib is passed, use that instead of asking the user
    bib_id = params['bib_id']
    if bib_id.present?
      params = { bib_id: bib_id }
      return redirect_to holding_offsite_requests_path params
    end
  end

  # Given a bib_id, get a mfhd_id
  # Either select automatically,
  # or get from the user
  def holding
    bib_id = params['bib_id']
    if bib_id.blank?
      flash[:error] = "Please supply a record number"
      return redirect_to bib_offsite_requests_path
    end

    @clio_record = ClioRecord::new_from_bib_id(bib_id)
    if @clio_record.blank?
      flash[:error] = "Cannot find record #{bib_id}"
      return redirect_to bib_offsite_requests_path
    end

    offsite_holdings = @clio_record.offsite_holdings
    if offsite_holdings.size == 0
      flash[:error] = "The requested record (#{bib_id}) has no offsite holdings."
      return redirect_to bib_offsite_requests_path
    end

    if @clio_record.offsite_holdings.size == 1
      @holding = @clio_record.offsite_holdings.first
      mfhd_id = @holding[:mfhd_id]
      params = { bib_id: bib_id, mfhd_id: mfhd_id }
      # clear any leftover error message, let new page figure it out.
      flash[:error] = nil
      return redirect_to new_offsite_request_path params
    end

    # If we haven't redirected, then we'll render
    # a page to let the user pick which holding they want.
  end

  # GET /offsite_requests/new
  # Needs to have a bib_id and mfhd_id,
  # if either is missing, bounce back to appropriate screen
  def new
    bib_id = params['bib_id']
    mfhd_id = params['mfhd_id']

    if bib_id.blank?
      flash[:error] = "Please supply a record number"
      return redirect_to bib_offsite_requests_path
    end
    if mfhd_id.blank?
      flash[:error] = "Please specify a holding"
      params = { bib_id: bib_id }
      return redirect_to holding_offsite_requests_path params
    end

    @clio_record = ClioRecord::new_from_bib_id(bib_id)
    @clio_record.fetch_availabilty

    @holding = @clio_record.holdings.select { |h| h[:mfhd_id] == mfhd_id }.first
    @offsite_location_code = @holding[:location_code]
    @offsite_request = OffsiteRequest.new
  end


  # GET /offsite_requests/1/edit
  def edit
  end

  # POST /offsite_requests
  # POST /offsite_requests.json
  def create
    # Are we submitting to the new (SCSB) or legacy (cgi) request system?
    # If legacy, pass control.
    if params[:legacy_submit]
      # Legacy system needs some extra fields
      legacy_params = offsite_request_params
      submit_legacy_offsite_request(legacy_params)
      return
    end

    @request_item_response = Recap::ScsbApi.request_item(offsite_request_params) || {}


  end



  def submit_legacy_offsite_request(params)
    # We need to map our Valet params to the params expected by
    # the legacy CGI offsite request system, then 

    # Delivery Type - "PHY" for physical, "WEB" for electronic
    deltype = params[:requestType] == 'EDD' ? 'WEB' : 'PHY'

    legacy_url = 'https://www1.columbia.edu/sec-cgi-bin' +
                 '/cul/offsite/processformdata'
    legacy_params = {
      # Patron contact information
      PATNAME:  current_user.name,
      PATMAIL:  params[:emailAddress],
      PATDEPT:  current_user.department,
      PATFONE:  current_user.phone,
      # PATNOTE:  '',  # omit
      PATRUNI:  current_user.login,

      # Citation details for Electronic Document Delivery (EDD)
      ARTAUTH:  params[:author] || '',
      ARTITLE:  params[:chapterTitle] || '',
      ARTVOL1:  params[:volume] || '',
      ARTVOL2:  params[:issue] || '',
      ARTSTPG:  params[:startPage] || '',
      ARTENPG:  params[:endPage] || '',
      # This was "Other Identifying Info" in vie.  Omit for now.
      # ARTINFO:  XXX,

      # Info about the requested item(s)
      CLIOKEY:  params[:bibId],
      ITMBARC:  params[:itemBarcodes],

      # Information about the request itself
      DELTYPE:  deltype,
      PICKUPL:  params[:deliveryLocation],

      # DEFLOCA:  XXX,

      # ITMAUTH:  XXX,
      # ITMCALL:  XXX,
      # ITMPART:  XXX,
      # ITMTITL:  XXX,

      # PRIORIT:  XXX,
      # REQCODE:  XXX,
      # REQDATE:  XXX,
      REQNOTE:  'Testing!! Please disregard.',
    }

    uri = URI(legacy_url)
    uri.query = legacy_params.to_query
    redirect_to uri.to_s
  end


  # PATCH/PUT /offsite_requests/1
  # PATCH/PUT /offsite_requests/1.json
  def update
    # respond_to do |format|
    #   if @offsite_request.update(offsite_request_params)
    #     format.html { redirect_to @offsite_request, notice: 'Offsite request was successfully updated.' }
    #     format.json { render :show, status: :ok, location: @offsite_request }
    #   else
    #     format.html { render :edit }
    #     format.json { render json: @offsite_request.errors, status: :unprocessable_entity }
    #   end
    # end
  end

  # DELETE /offsite_requests/1
  # DELETE /offsite_requests/1.json
  def destroy
    # @offsite_request.destroy
    # respond_to do |format|
    #   format.html { redirect_to offsite_requests_url, notice: 'Offsite request was successfully destroyed.' }
    #   format.json { head :no_content }
    # end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_offsite_request
      @offsite_request = OffsiteRequest.find(params[:id])
    end


    # Never trust parameters from the scary internet, 
    # only allow the white list through.
    def offsite_request_params
      # Fill in ALL request params here, 
      # permit some from form params,
      # merge in others from other application state
      application_params = {
        patronBarcode:   current_user.barcode,
        emailAddress:    current_user.email
      }

      params.permit(
          # Information about the request
          :requestType,
          :deliveryLocation,
          # Optional EDD params
          :author,
          :chapterTitle,
          :volume,
          :issue,
          :startPage,
          :endPage,
          # Information about the requested item
          :itemOwningInstitution,
          :bibId,
          :titleIdentifier,
          :callNumber,
          :itemBarcodes => [],
        ).merge(application_params)

    end
end
