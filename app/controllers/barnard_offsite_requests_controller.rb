class BarnardOffsiteRequestsController < ApplicationController
  before_action :authenticate_user!

  before_action :confirm_barnard_offsite_eligibility!, except: [ :ineligible, :error ]

  before_action :set_offsite_request, only: [:show, :edit, :update, :destroy]

  # before_filter :authenticate_user!, if: :devise_controller?


  # GET /offsite_requests
  # GET /offsite_requests.json
  def index
    return redirect_to(action: 'bib')
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
      return redirect_to holding_barnard_offsite_requests_path params
    end
  end

  # Given a bib_id, get a mfhd_id
  # Either select automatically,
  # or get from the user
  def holding
    bib_id = params['bib_id']
    if bib_id.blank?
      flash[:error] = "Please supply a record number"
      return redirect_to bib_barnard_offsite_requests_path
    end

    @clio_record = ClioRecord::new_from_bib_id(bib_id)
    if @clio_record.blank?
      flash[:error] = "Cannot find record #{bib_id}"
      return redirect_to bib_barnard_offsite_requests_path
    end

    offsite_holdings = @clio_record.barnard_offsite_holdings
    if offsite_holdings.size == 0
      flash[:error] = "The requested record (bib id #{bib_id}) has no Barnard offsite holdings available."
      return redirect_to bib_barnard_offsite_requests_path
    end

    if @clio_record.barnard_offsite_holdings.size == 1
      @holding = @clio_record.barnard_offsite_holdings.first
      mfhd_id = @holding[:mfhd_id]
      params = { bib_id: bib_id, mfhd_id: mfhd_id }
      # clear any leftover error message, let new page figure it out.
      flash[:error] = nil
      return redirect_to new_barnard_offsite_request_path params
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
      return redirect_to bib_barnard_offsite_requests_path
    end
    if mfhd_id.blank?
      flash[:error] = "Please specify a holding"
      params = { bib_id: bib_id }
      return redirect_to holding_barnard_offsite_requests_path params
    end

    @clio_record = ClioRecord::new_from_bib_id(bib_id)

    @holding = @clio_record.holdings.select { |h| h[:mfhd_id] == mfhd_id }.first

    # populate clio record object with barcode availability details
    @clio_record.fetch_voyager_availability

    # There's special view logic if the available-item list is empty.
    @available_items = get_available_items(@clio_record, @holding)

    if @available_items.size == 1
      @barcode = @available_items.first[:barcode]
    end

    @offsite_location_code = @holding[:location_code]
    @customer_code = @holding[:customer_code]
    @barnard_offsite_request = BarnardOffsiteRequest.new
  end


  # This is the request-form-submit.
  # All it has to do is send email to Barnard staff.
  def create
    @offsite_request_params = offsite_request_params()

    barnard_config = APP_CONFIG['barnard']
    die "Missing barnard configuration!" unless 
      barnard_config.present? && barnard_config['request_email'].present?
    email = barnard_config['request_email']

    # Send request email to barnard library staff
    from    = "Barnard Offsite Request Service <#{email}>"
    to      = "Barnard Offsite Request Service <#{email}>"
    subject = "New BearStor Request [#{@offsite_request_params[:titleIdentifier]}]"
    body    = request_email_body()
    ActionMailer::Base.mail(from: from, to: to, subject: subject, body: body).deliver_now

    # Send confirmation email to patron
    from    = "Barnard Offsite Request Service <#{email}>"
    to      = current_user.email
    subject = "BearStor Request Confirmation [#{@offsite_request_params[:titleIdentifier]}]"
    body    = confirmation_email_body()
    ActionMailer::Base.mail(from: from, to: to, subject: subject, body: body).deliver_now

    # Then continue on to render the page
  end


  # # PATCH/PUT /offsite_requests/1
  # # PATCH/PUT /offsite_requests/1.json
  # def update
  #   # respond_to do |format|
  #   #   if @offsite_request.update(offsite_request_params)
  #   #     format.html { redirect_to @offsite_request, notice: 'Offsite request was successfully updated.' }
  #   #     format.json { render :show, status: :ok, location: @offsite_request }
  #   #   else
  #   #     format.html { render :edit }
  #   #     format.json { render json: @offsite_request.errors, status: :unprocessable_entity }
  #   #   end
  #   # end
  # end

  # # DELETE /offsite_requests/1
  # # DELETE /offsite_requests/1.json
  # def destroy
  #   # @offsite_request.destroy
  #   # respond_to do |format|
  #   #   format.html { redirect_to offsite_requests_url, notice: 'Offsite request was successfully destroyed.' }
  #   #   format.json { head :no_content }
  #   # end
  # end

  def ineligible
  end

  def error
  end

  private

  # Just make sure we've got an authenticated user, with 
  # a login id and a contact email.
  def confirm_barnard_offsite_eligibility!
    return redirect_to(ineligible_barnard_offsite_requests_path) unless 
        current_user.login.present? &&
        current_user.email.present?
  end

  def get_available_items(clio_record = nil, holding = nil)
    return [] if clio_record.blank? || holding.blank?
    
    available_items = []
    holding[:items].each do |item|
      availability = clio_record.voyager_availability[ item[:item_id] ]
      available_items << item if availability == 'Available'
    end
    return available_items
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_offsite_request
    @barnard_offsite_request = BarnardOffsiteRequest.find(params[:id])
  end


  # Never trust parameters from the scary internet, 
  # only allow the white list through.
  def offsite_request_params
    # Fill in ALL request params here, 
    # permit some from form params,
    # merge in others from other application state
    application_params = {
      patronBarcode:   current_user.barcode,
    }

    params.permit(
        # Information about the request
        :emailAddress,
        # Information about the requested item
        :bibId,
        :titleIdentifier,
        :callNumber,
        :itemBarcodes => [],
      ).merge(application_params)

  end


  def request_email_body()
    body = <<-EOT
The following has been requested from BearStor:

TITLE : #{@offsite_request_params[:titleIdentifier]}
CALL NO : #{@offsite_request_params[:callNumber]}
BARCODE: #{(@offsite_request_params[:itemBarcodes] || []).join(', ')}

PATRON UNI:  #{current_user.login}
PATRON EMAIL:  #{current_user.email}

EOT

  end

  def confirmation_email_body()
    body = <<-EOT
You have requested the following from BearStor:

TITLE : #{@offsite_request_params[:titleIdentifier]}
CALL NO : #{@offsite_request_params[:callNumber]}
BARCODE: #{(@offsite_request_params[:itemBarcodes] || []).join(', ')}

Requests submitted before 2:30pm Mon-Fri will be filled in one business day; all requests filled in two business days.

You will be contacted by email (to #{@offsite_request_params[:emailAddress]}) when the item is available.

Thank you for using Offsite collections!
EOT
  end



end



