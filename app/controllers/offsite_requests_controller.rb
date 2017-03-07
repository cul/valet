class OffsiteRequestsController < ApplicationController
  before_action :set_offsite_request, only: [:show, :edit, :update, :destroy]

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

  # GET /offsite_requests/new
  def new
    bib_id = params['bib_id']

    if bib_id.blank?
      redirect_to action: 'bib'
    end

    marc = nil
    if bib_id.present?
      solr_connection = Clio::SolrConnection.new()
      if (marcxml = solr_connection.retrieve_marcxml(bib_id))
        reader = MARC::XMLReader.new(StringIO.new(marcxml))
        @marc = reader.entries[0]
        # Some Dublin Core support from rubymarc
        @dc = @marc.to_dublin_core
      end
    end

    @offsite_request = OffsiteRequest.new
  end

  def bib
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
