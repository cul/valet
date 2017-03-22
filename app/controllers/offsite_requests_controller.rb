class OffsiteRequestsController < ApplicationController
  before_action :set_offsite_request, only: [:show, :edit, :update, :destroy]

  # before_filter :authenticate_user!, if: :devise_controller?
  before_filter :authenticate_user!


  # GET /offsite_requests
  # GET /offsite_requests.json
  def index
    @offsite_requests = OffsiteRequest.all
    # raise
  end

  # GET /offsite_requests/1
  # GET /offsite_requests/1.json
  def show
  end

  # Get a bib_id from the user
  def bib
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
# raise
    if @clio_record.offsite_holdings.size == 1
      @holding = @clio_record.offsite_holdings.first
      mfhd_id = @holding[:mfhd_id]
      params = { bib_id: bib_id, mfhd_id: mfhd_id }
      # clear any leftover error message, let new page figure it out.
      flash[:error] = nil
      return redirect_to new_offsite_request_path params
    end

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
      return redirect_to holding_offsite_requests_path bib_id: bib_id
    end

    @clio_record = ClioRecord::new_from_bib_id(bib_id)

    # if @clio_record.blank?
    #   flash[:error] = "Cannot find record #{bib_id}"
    #   return redirect_to action: 'bib'
    # end
    # 
    # #  Determine which Holding we're requesting
    # offsite_holdings = @clio_record.offsite_holdings
    # if offsite_holdings.size == 0
    #   flash[:error] = "The requested record (#{bib_id}) has no offsite holdings."
    #   return redirect_to action: 'bib'
    # end
    # if @clio_record.offsite_holdings.size == 1
    #   @holding = @clio_record.offsite_holdings.first
    # end
    # 
    # if @clio_record.offsite_holdings.size > 1
    #   if mfhd_id.blank?
    #     return redirect_to action: 'holding', bib_id: bib_id
    #   end
    #   # If mfhd_id passed in, it must be
    #   # (1) found in the record, (2) offsite
    # 
    # end
    # 
    # # # Holdings conditions:
    # # - invalid mfhd_id:
    # #   - ERROR
    # # - No offsite holdings (error)
    # #   - mfhd_id passed?  ignore
    # # - Single offsite holding (proceed)
    # #   - mfhd_id passed?  ignore (? no validation ?)
    # # - Multiple offsite holding (select)
    # #   - mfhd_id passed?  validate:
    # #       - valid?
    # LOCATIONS['offsite_locations'].exclude?(@holding[:location_code])
    # 
    # 
    # 
    # if offsite_holdings.none? do |holding|
    # 
    # if mfhd_id = params['mfhd_id']
    # 
    # # Identify which holding we'll be requesting
    # if @clio_record.offsite_holdings.size == 1
    #   @holding = @clio_record.offsite_holdings.first
    #   mfhd_id = @holding[:mfhd_id]
    # else
    #   mfhd_id = params['mfhd_id']
    # end
    # 
    # if mfhd_id.blank? ||
    #    LOCATIONS['offsite_locations'].exclude?(@holding[:location_code])
    #   return redirect_to action: 'holding', bib_id: bib_id
    # end
    # 

    @clio_record.fetch_availabilty
    @holding = @clio_record.holdings.select { |h| h[:mfhd_id] = mfhd_id }.first
    @offsite_location_code = @holding[:location_code]
    @offsite_request = OffsiteRequest.new
  end


  # GET /offsite_requests/1/edit
  def edit
  end

  # POST /offsite_requests
  # POST /offsite_requests.json
  def create
    @offsite_request = OffsiteRequest.new(offsite_request_params)

    respond_to do |format|
      if @offsite_request.save
        format.html { redirect_to @offsite_request, notice: 'Offsite request was successfully created.' }
        format.json { render :show, status: :created, location: @offsite_request }
      else
        format.html { render :new }
        format.json { render json: @offsite_request.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /offsite_requests/1
  # PATCH/PUT /offsite_requests/1.json
  def update
    respond_to do |format|
      if @offsite_request.update(offsite_request_params)
        format.html { redirect_to @offsite_request, notice: 'Offsite request was successfully updated.' }
        format.json { render :show, status: :ok, location: @offsite_request }
      else
        format.html { render :edit }
        format.json { render json: @offsite_request.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /offsite_requests/1
  # DELETE /offsite_requests/1.json
  def destroy
    @offsite_request.destroy
    respond_to do |format|
      format.html { redirect_to offsite_requests_url, notice: 'Offsite request was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_offsite_request
      @offsite_request = OffsiteRequest.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def offsite_request_params
      params.fetch(:offsite_request, {})
    end
end
