# We use the library-number-normalization througout
require 'library_stdnums'

# UNIX-5942 - work around spotty CUIT DNS
require 'resolv-hosts-dynamic'
require 'resolv-replace'

class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception, prepend: true

  include Devise::Controllers::Helpers
  devise_group :user, contains: [:user]

  prepend_before_action :cache_dns_lookups

  # Overwriting the sign_out redirect path method
  def after_sign_out_path_for(_resource_or_scope)
    cas_opts = YAML.load_file(File.join(Rails.root, 'config', 'cas.yml'))[Rails.env] || {}

    # If CAS options are absent, we can only do application-level logout,
    # not CAS logout.  Warn, and proceed.
    unless cas_opts['host'] && cas_opts['logout_url']
      Rails.logger.error 'CAS options missing - skipping CAS logout!'
      return welcome_logout_path
    end

    # Full CAS logout + application logout page looks like this:
    # https://cas.columbia.edu/cas/logout?service=https://helpdesk.cul.columbia.edu/welcome/logout
    cas_logout_url = 'https://' + cas_opts['host'] + cas_opts['logout_url']
    service = request.base_url + welcome_logout_path
    after_sign_out_path = "#{cas_logout_url}?service=#{service}"
    Rails.logger.debug "after_sign_out_path = #{after_sign_out_path}"
    after_sign_out_path
  end

  # Return a hash with a set of attributes
  # of the current request, to be added to
  # a given log entry.
  # What do we want to know?
  # Referrer, Timestamp, IP,
  def request_data
    data = {}
    data[:user_agent] = request.user_agent
    # Also for convenience store name and version
    data[:browser_name] = browser.name
    data[:browser_version] = browser.version
    data[:referrer]   = request.referrer
    data[:remote_ip]  = request.remote_ip
    data
  end
  
  # UNIX-5942 - work around spotty CUIT DNS
  def cache_dns_lookups
    dns_cache = []
    hostnames = [ 'ldap.columbia.edu', 'cas.columbia.edu' ]
    hostnames.each { |hostname|
      addr = getaddress_retry(hostname)
      dns_cache << { 'hostname' => 'x' + hostname, 'addr' => addr } if addr.present?
    }
    return unless dns_cache.size > 0
    
    Rails.logger.debug "cache_dns_lookups() dns_cache=#{dns_cache}"
    
    cached_resolver = Resolv::Hosts::Dynamic.new(dns_cache)
    Resolv::DefaultResolver.replace_resolvers( [cached_resolver, Resolv::DNS.new] )
  end
  
  def getaddress_retry(hostname = nil)
    return unless hostname.present?

    addr = nil
    (1..3).each do |try|
      begin
        addr = Resolv.getaddress(hostname)
        break if addr.present?
      rescue => ex
        # failed?  log, pause, and try again
        Rails.logger.error "Resolv.getaddress(#{hostname}) failed on try #{try}: #{ex.message}, retrying..."
        sleep 1
      end
    end


    return addr
  end


end
