class PatronBarcodeController < ApplicationController

  def index
    @config = APP_CONFIG[:patron_barcode]
    return head(:internal_server_error) unless @config && @config[:clients]

    params = patron_barcode_params
    return head(:bad_request) unless params[:uni] && params[:token]
    
    return head(:unauthorized) unless authorize_client( params[:token] )     
    
    @patron_barcode = lookup_patron_barcode(params[:uni])
  end
  
  
  private
  
  def patron_barcode_params
    params.permit(:uni, :token)
  end

  
  def lookup_patron_barcode(uni)
    begin
      oracle_connection ||= Voyager::OracleConnection.new
      patron_id ||= oracle_connection.get_patron_id(uni)
      patron_barcode = oracle_connection.retrieve_patron_barcode(patron_id)
      return patron_barcode
    rescue => ex
      return nil
    end
  end

  
  def authorize_client(token)
    # (1) Verify Token
    # find the client-config block matching the given token
    client = @config[:clients].select { |client| client[:token] == token }.first
    return unless client
    
    # (2) Verify IP
    # test client-ip against the list of approved addresses
    whitelisted = client[:ips].any? { |cidr| IPAddr.new(cidr) === request.remote_addr }
    return unless whitelisted

    # If the above tests didn't fail, we're authorized
    return true
  end
  
  
end

