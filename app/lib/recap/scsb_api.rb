
module Recap
  class ScsbApi

    attr_reader :conn, :scsb_args

    # APP_CONFIG parameter block looks like this:
    # 
    # scsb_connection_details:
    #   api_key: xxx
    #   url: http://foo.bar.com:999
    #   item_availability_path: /blah/itemAvailabilityStatus
    #   search_path: /blah/search
    #   search_by_param_path: /blah/searchByParam

    def self.get_scsb_args
      app_config_key = 'scsb_connection_details'
      scsb_args = APP_CONFIG[app_config_key]
      raise "Cannot find #{app_config_key} in APP_CONFIG!" if scsb_args.blank?
      scsb_args.symbolize_keys!

      [:api_key, :url, :item_availability_path].each do |key|
        raise "SCSB config needs value for '#{key}'" unless scsb_args.has_key?(key)
      end

      @scsb_args = scsb_args
    end

    def self.open_connection(url = nil)
      if @conn
        if url.nil?  || (@conn.url_prefix.to_s == url)
          return @conn
        end
      end

      get_scsb_args
      url ||= @scsb_args[:url]
      Rails.logger.debug "- opening new connection to #{url}"
      @conn = Faraday.new(url: url)
      raise "Faraday.new(#{url}) failed!" unless @conn

      @conn.headers['Content-Type'] = 'application/json'
      @conn.headers['api_key'] = @scsb_args[:api_key]

      return @conn
    end

    # NOTE: Currently bibAvailabilityStatus and itemAvailabilityStatus
    # return the same response format:
    # [
    #   {
    #     "itemBarcode": "CU10104704",
    #     "itemAvailabilityStatus": "Available",
    #     "errorMessage": null
    #   },
    #   {
    #     "itemBarcode": "CU10104712",
    #     "itemAvailabilityStatus": "Available",
    #     "errorMessage": null
    #   },
    #   ...
    # ]
    # But the APIs are still under active development.  Response
    # format may diverge in the future.


    # Called like this:
    # availability = Recap::ScsbApi.get_item_availability(barcodes)
    def self.get_item_availability(barcodes = [], conn = nil)
      raise "Recap::ScsbApi.get_item_availability() got blank barcodes" if barcodes.blank?
      Rails.logger.debug "- get_item_availability(#{barcodes})"

      conn ||= open_connection()
      raise "get_item_availability() bad connection [#{conn.inspect}]" unless conn

      get_scsb_args
      path = @scsb_args[:item_availability_path]
      params = {
        barcodes: barcodes
      }

      response = conn.post path, params.to_json
      if response.status != 200
        # Raise or just log error?
        Rails.logger.error "ERROR:  API response status #{response.status}"
        Rails.logger.error "ERROR DETAILS: " + response.body
        return ''
      end

      # parse returned array of item-info hashes into simple barcode->status hash
      response_data = JSON.parse(response.body).with_indifferent_access
      availabilities = Hash.new
      response_data.each do |item|
        availabilities[ item['itemBarcode'] ] = item['itemAvailabilityStatus']
      end
      return availabilities
    end


    # Return a hash:
    #   { barcode: availability, barcode: availability, ...}

    # BIB NOT FOUND - Response Code 200, Response Body:
    # [
    #   {
    #     "itemBarcode": "",
    #     "itemAvailabilityStatus": null,
    #     "errorMessage": "Bib Id doesn't exist in SCSB database."
    #   }
    # ]
    def self.get_bib_availability(bib_id = nil, institution_id = nil, conn = nil)
      raise "Recap::ScsbApi.get_bib_availability() got nil bib_id" if bib_id.blank?
      raise "Recap::ScsbApi.get_bib_availability() got nil institution_id" if bib_id.blank?
      Rails.logger.debug "- get_bib_availability(#{bib_id}, #{institution_id})"

      conn  ||= open_connection()
      raise "get_bib_availability() bad connection [#{conn.inspect}]" unless conn

      get_scsb_args
      path = @scsb_args[:bib_availability_path]
      params = {
        bibliographicId: bib_id,
        institutionId:   institution_id
      }
      Rails.logger.debug "get_bib_availability(#{bib_id}) calling SCSB API with params #{params.inspect}"
      response = conn.post path, params.to_json
      Rails.logger.debug "SCSB response status: #{response.status}"

      if response.status != 200
        # Raise or just log error?
        Rails.logger.error "ERROR:  API response status #{response.status}"
        Rails.logger.error "ERROR DETAILS: " + response.body
        return
      end

      # parse returned array of item-info hashes into simple barcode->status hash
      response_data = JSON.parse(response.body)
      availabilities = Hash.new
      response_data.each do |item|
        availabilities[ item['itemBarcode'] ] = item['itemAvailabilityStatus']
      end
      return availabilities
    end


    def self.get_patron_information(patron_barcode = nil, institution_id = nil, conn = nil)
      raise "Recap::ScsbApi.get_patron_information() got blank patron_barcode" if patron_barcode.blank?
      raise "Recap::ScsbApi.get_patron_information() got blank institution_id" if institution_id.blank?
      Rails.logger.debug "- get_patron_information(#{patron_barcode}, #{institution_id})"

      conn  ||= open_connection()
      raise "get_bib_availability() bad connection [#{conn.inspect}]" unless conn

      get_scsb_args
      path = @scsb_args[:patron_information_path]
      params = {
        patronIdentifier:      patron_barcode,
        itemOwningInstitution: institution_id
      }
      response = conn.post path, params.to_json

      if response.status != 200
        # Raise or just log error?
        Rails.logger.error "ERROR:  API response status #{response.status}"
        Rails.logger.error "ERROR DETAILS: " + response.body
        return
      end

      # Rails.logger.debug "response.body=\n#{response.body}"
      patron_information_hash = JSON.parse(response.body).with_indifferent_access
      # Just return the full hash, let the caller pull out what they want
      return patron_information_hash
    end

    # This is for RETRIEVAL / RECALL, not for EDD
    # def self.request_item(requestType = nil, itemBarcodes = [], deliveryLocation = nil, itemOwningInstitution = nil, conn = nil)
    def self.request_item(params, conn = nil)

      # How much valet-side param validation should we do?
      # raise "Recap::ScsbApi.request_item() got invalid requestType" unless
      #   params[:requestType].present? &&
      #   ['RETRIEVAL','RECALL'].include?(requestType)
      # raise "Recap::ScsbApi.request_item() got blank itemBarcodes" if params[itemBarcodes].blank?
      # raise "Recap::ScsbApi.request_item() got blank deliveryLocation" if params[deliveryLocation].blank?
      # raise "Recap::ScsbApi.request_item() got blank itemOwningInstitution" if [itemOwningInstitution].blank?

      Rails.logger.debug "- request_item(#{params.inspect})"

      conn  ||= open_connection()
      raise "request_item() bad connection [#{conn.inspect}]" unless conn

      # set values that aren't passed in as parameters
      params.merge!(
        {
          requestingInstitution: 'CUL'
        }
      )

      get_scsb_args
      path = @scsb_args[:request_item_path]
      response = conn.post path, params.to_json

      if response.status != 200
        # Raise or just log error?
        Rails.logger.error "ERROR:  API response status #{response.status}"
        Rails.logger.error "ERROR DETAILS: " + response.body
        return {}
      end

      # Rails.logger.debug "response.body=\n#{response.body}"
      response_hash = JSON.parse(response.body).with_indifferent_access
      # Just return the full hash, let the caller pull out what they want
      return response_hash
    end


  end
end


