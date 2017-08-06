class OffsiteRequestsController < ApplicationController
  before_action :authenticate_user!

  before_action :confirm_offsite_eligibility!, except: [ :ineligible ]

  before_action :set_offsite_request, only: [:show, :edit, :update, :destroy]

  # before_filter :authenticate_user!, if: :devise_controller?


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


  # # GET /offsite_requests/1/edit
  # def edit
  # end

  # POST /offsite_requests
  # POST /offsite_requests.json
  def create

    @request_item_response = Recap::ScsbRest.request_item(offsite_request_params) || {}

    log_request(offsite_request_params, @request_item_response)

    # Send confirmation email to patron
    from    = 'recap@libraries.cul.columbia.edu'
    to      = current_user.email
    subject = confirmation_email_subject(offsite_request_params, @request_item_response)
    body    = confirmation_email_body(offsite_request_params, @request_item_response)
    ActionMailer::Base.mail(from: from, to: to, subject: subject, body: body).deliver_now

    # Then continue on to render the page
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

  def ineligible
  end

  private

  def confirm_offsite_eligibility!
    redirect_to ineligible_offsite_requests_path unless current_user
    redirect_to ineligible_offsite_requests_path unless current_user.offsite_eligible?
  end


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
      requestingInstitution: 'CUL',
    }

    params.permit(
        # Information about the request
        :requestType,
        :deliveryLocation,
        :emailAddress,
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


  def confirmation_email_subject(offsite_request_params, request_item_response)
    subject = 'Offsite Request Submission Confirmation'
    if @request_item_response[:titleIdentifier]
      subject = subject + " [#{@request_item_response[:titleIdentifier]}]"
    end
    
    if Rails.env != 'valet_prod'
      subject = subject + " (#{Rails.env})"
    end
    return subject
  end

  def confirmation_email_body(offsite_request_params, request_item_response)

    status = @request_item_response[:screenMessage]

    error = ''
    if @request_item_response[:success] != true
      error = <<-EOT
=============================================
ERROR : This submission was not successful.  
Please check the message below.
=============================================
EOT
    end
    

    body = <<-EOT
You have requested the following from Offsite:

TITLE : #{@request_item_response[:titleIdentifier]}
CALL NO : #{@request_item_response[:callNumber]}
BARCODE: #{(@request_item_response[:itemBarcodes] || []).join(', ')}

#{@error}
Response message:
        #{status}


Requests submitted before 2:30pm Mon-Fri will be filled in one business day; all requests filled in two business days.

You will be contacted by email (to #{@request_item_response[:emailAddress]}) when the item is available.

In order to best serve the Columbia community, please request 20 items or fewer per day. Contact recap@libraries.cul.columbia.edu with questions and comments.

Patrons can check the status of their pending requests at:
http://www.columbia.edu/cgi-bin/cul/resolve?lweb0087-1

Thank you for using Offsite collections.
EOT
  end


  def log_request(params, response)
    log_dir = get_log_dir
    return unless log_dir
    
    log_entry = get_log_entry(params, response)
    return unless log_entry

    log_file = [ 'valet', Date.today.strftime('%Y%m'), 'log' ].join('.')
    File.open("#{log_dir}/#{log_file}", 'a') do |f|
      f.puts log_entry
    end

  end


  def get_log_dir
    log_dir = APP_CONFIG['log_directory']
    unless log_dir
      Rails.logger.error "cannot log request - log_dir not given in app_config"
      return
    end
    unless Dir.exist?(log_dir)
      Rails.logger.error "cannot log request - can't find log_dir [#{log_dir.to_s}]"
      return
    end

    # # Full log_dir is top dir plus YYYY-MM subdir (e.g., "2017-07")
    # log_dir = log_dir + '/' + Date.today.strftime('%Y-%m')

    Dir.mkdir(log_dir) unless Dir.exist?(log_dir)
    return log_dir
  end
  

  # Given the request parameters and the SCSB API response,
  # build the log entry - a single line string
  def get_log_entry(params, response)
    fields = []

    # basic info
    fields.push DateTime.now.strftime('%F %T')
    fields.push current_user.login
    fields.push request.remote_ip

    # patron information
    fields.push "patronBarcode=#{params[:patronBarcode]}"
    fields.push "emailAddress=#{params[:emailAddress]}"

    # Information about the request
    fields.push "requestType=#{params[:requestType]}"
    fields.push "deliveryLocation=#{params[:deliveryLocation]}"
    fields.push "requestingInstitution=#{params[:requestingInstitution]}"

    # Information about the requested item
    fields.push "itemOwningInstitution=#{params[:itemOwningInstitution]}"
    fields.push "bibId=#{params[:bibId]}"
    fields.push "titleIdentifier=#{params[:titleIdentifier]}"
    fields.push "callNumber=#{params[:callNumber]}"
    fields.push "itemBarcodes=#{(params[:itemBarcodes] || []).join('/')}"

    # Optional EDD params
    fields.push "author=#{params[:author]}"
    fields.push "chapterTitle=#{params[:chapterTitle]}"
    fields.push "volume=#{params[:volume]}"
    fields.push "issue=#{params[:issue]}"
    fields.push "startPage=#{params[:startPage]}"
    fields.push "endPage=#{params[:endPage]}"

    # SCSB API Response information
    fields.push "success=#{response[:success]}"
    fields.push "screenMessage=#{(response[:screenMessage] || '').squish}"

    # Data fields could contain commas, or just about anything
    entry = fields.join('|')

    return entry
  end
  

end



