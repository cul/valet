class User < ActiveRecord::Base
  include Cul::Omniauth::Users

  # cul_omniauth includes several options (:registerable, 
  # :recoverable, :rememberable, :trackable, :validatable, ...)
  # but we also want...
  devise :timeoutable

  serialize :affils, Array

  attr_reader :ldap_attributes, :patron_id, :oracle_connection
  
  # cul_omniauth sets "devise :recoverable", and that requires
  # that the following user attributes be available.
  attr_accessor :reset_password_token, :reset_password_sent_at

  # Before first-time User record creation...
  before_create :set_personal_info_via_ldap, :set_email

  # Every user-object instantiation...
  after_initialize :set_personal_info_via_ldap
  after_initialize :set_email
  after_initialize :set_barcode_via_oracle

  # we don't need this
  # after_initialize :get_scsb_patron_information

  def to_s
    if first_name
      first_name.to_s + ' ' + last_name.to_s
    else
      login
    end
  end

  def name
    self.to_s
  end

  def set_personal_info_via_ldap
    # return if the ldap attributes have already been filled in
    return unless @ldap_attributes.nil?

    if uid
      ldap_args = APP_CONFIG['ldap_connection_details']

      raise "LDAP config needs 'host'" unless ldap_args.has_key?(:host)
      raise "LDAP config needs 'port'" unless ldap_args.has_key?(:port)
      raise "LDAP config needs 'base'" unless ldap_args.has_key?(:base)

      Rails.logger.debug "Querying LDAP #{ldap_args.inspect} for uid=#{uid}"
      entry = Net::LDAP.new({host: ldap_args[:host], port: ldap_args[:port]}).search(base: ldap_args[:base], :filter => Net::LDAP::Filter.eq("uid", uid)) || []
      entry = entry.first
      Rails.logger.debug "LDAP response: #{entry.inspect}"

      if entry
        # Copy all attributes of the LDAP entry to an instance variable,
        # keeping them in list format
        @ldap_attributes = Hash.new
        entry.each_attribute do |attribute, value_list|
          next if value_list.blank?
          @ldap_attributes[attribute] = value_list
        end

        # Process certain raw attributes into cleaned up fields
        self.last_name  = Array(entry[:sn]).first.to_s
        self.first_name = Array(entry[:givenname]).first.to_s
      end
    end

    return self
  end

  def set_email
    # Try to find email via LDAP
    if @ldap_attributes && ldap_mail = @ldap_attributes[:mail]
      ldap_mail = Array(ldap_mail).first.to_s
      if ldap_mail.length > 6 and ldap_mail.match(/^.+@.+$/)
        self.email = ldap_mail
        return self
      end
    end
    
    # Try to find email via Voyager
    if @oracle_connection ||= Voyager::OracleConnection.new()
      if @patron_id ||= @oracle_connection.retrieve_patron_id(uid)
        if voyager_email = @oracle_connection.retrieve_patron_email(@patron_id)
          if voyager_email.length > 6 and voyager_email.match(/^.+@.+$/)
            self.email = voyager_email
            return self
          end
        end
      end
    end
    
    # No email!  Fill in guess.
    Rails.logger.error "ERROR: Cannot find email address via LDAP or Voyager for uid [#{uid}], assuming @columbia.edu"
    self.email = "#{uid}@columbia.edu"
    return self
  end

  def set_barcode_via_oracle
    self.barcode = ''

    if uid
      if @oracle_connection ||= Voyager::OracleConnection.new()
        if @patron_id ||= @oracle_connection.retrieve_patron_id(uid)
          if patron_barcode = @oracle_connection.retrieve_patron_barcode(@patron_id)
            self.barcode = patron_barcode
          end
        end
      end
    end

    return self
  end


  def login
    self.uid.split('@').first
  end

  def email
    email = super
    self.email = email
    return email
  end

  # Password methods required by Devise.
  def password
    Devise.friendly_token[0,20]
  end

  def password=(*val)
    # NOOP
  end

  def phone
    get_first_ldap_value('telephonenumber', 'campusphone')
  end

  def department
    get_first_ldap_value( 'ou' )
  end

  def get_first_ldap_value(*attribute_list)
    # Try passed attributes in preference order
    Array(attribute_list).each do |attribute|
      value_list = @ldap_attributes[attribute]
      Array(value_list).each do |value|
        return value unless value.blank?
      end
    end
    # fallback, return an empty string value
    return ''
  end

  def offsite_eligible?
    return false unless affils

    # Offsite eligibility set via app_config
    config = APP_CONFIG['offsite'] || {}

    # But hardcode a default, in case nothing is set in app_config
    if config['permitted_affils'].blank? && config['permitted_affil_regex'].blank?
      config['permitted_affil_regex'] = [ 'CUL_role-clio' ]
    end

    return eligible?(config, affils)
  end

  def offsite_blocked?
    return false unless affils
    # This is not a "denied" affiliation, 
    # because blocked users can still request physical delivery.
    affils.each do |affil|
      return true if affil.match(/CUL_role-clio-.*-blocked/)
    end
    return false
  end

  def ill_eligible?
    return false unless affils

    # Default to allow users with any 'CUL_role-clio*' affil,
    # but override with the app_config setting, if present
    config = APP_CONFIG['offsite'] || {}

    return eligible?(config, affils)
  end

  def eligible?(config, affils)
    unless config.present? && affils.present?
      Rails.logger.error "elibible?(config,affils) needs valid input args"
      return false
    end
    
    denied_affils         = config['denied_affils']         || []
    permitted_affils      = config['permitted_affils']      || []
    permitted_affil_regex = config['permitted_affil_regex'] || []

    [ denied_affils, permitted_affils, permitted_affil_regex ].each do |f|
      raise "#{f.to_s} must be an array!" unless f.is_a? Array
    end

    unless permitted_affils.present? || permitted_affil_regex.present?
      Rails.log.error "Cannot find ANY permitted_affils - no access allowed!" 
      return false
    end
    
    # Immediate rejection
    denied_affils.each do |bad_affil|
      Rails.logger.debug "#{login} has bad_affil #{bad_affil}" if
          affils.include?(bad_affil)
      return false if affils.include?(bad_affil)
    end
    permitted_affils.each do |good_affil|
      Rails.logger.debug "#{login} has good_affil #{good_affil}" if
          affils.include?(good_affil)
      return true if affils.include?(good_affil)
    end
    permitted_affil_regex.each do |good_regex|
      affils.each do |affil|
        Rails.logger.debug "affil #{affil} matches regexp #{good_regex}" if
            affil.match(/#{good_regex}/)
        return true if affil.match(/#{good_regex}/)
      end
    end

    # Default, if not explicitly permitted, return elible == false
    return false
  end
  
  
  # developers and sysadmins
  def admin?
    affils && (affils.include?('CUNIX_litosys') || affils.include?('CUL_dpts-dev'))
  end

  # application-level admin permissions
  def valet_admin?
    return true if self.admin?
    valet_admins = Array(APP_CONFIG['valet_admins']) || []
    return valet_admins.include? login
  end

  # # UNUSED
  # def get_scsb_patron_information
  #   raise # UNUSED
  #   return {} if barcode.blank?
  #   institution_id = 'CUL'
  #   @scsb_patron_information = Recap::ScsbRest.get_patron_information(barcode, institution_id) || {}
  # end


end
