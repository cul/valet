
module Recap
  class ScsbApi

    attr_reader :scsb_args

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

    def self.open_connection
      get_scsb_args
      full_url = @scsb_args[:url] + @scsb_args[:item_availability_path]
      conn = Faraday.new(url: full_url)
      raise "Faraday.new(#{full_url}) failed!" unless conn
      return conn
    end

    # Called like this:
    # availability = Recap::ScsbApi.get_barcode_availability(barcode)
    def self.get_barcode_availability(barcode = nil, conn = nil)
      raise "Recap::ScsbApi.get_barcode_availability() got nil barcode" if barcode.blank?
      get_scsb_args

      full_url = @scsb_args[:url] + @scsb_args[:item_availability_path]

      # rest-client - always gives me 401 Unauthorized?
      # params = { itemBarcode: barcode }
      # headers = { api_key: @scsb_args[:api_key], params: params }
      # response = RestClient.get(full_url, headers)
      # faraday
      conn ||= Faraday.new(url: full_url)
      raise "Faraday.new(#{full_url}) failed!" unless conn
      response = conn.get do |req|
        req.headers['api_key'] = @scsb_args[:api_key]
        req.params['itemBarcode'] = barcode
      end

      # status = response.status  # numeric http status code
      availability = response.body
    end

  end
end


