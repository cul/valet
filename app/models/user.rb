class User < ActiveRecord::Base
  include Cul::Omniauth::Users

  # cul_omniauth includes several options (:registerable, 
  # :recoverable, :rememberable, :trackable, :validatable, ...)
  # but we also want...
  devise :timeoutable

  serialize :affils, Array

  # attr_reader :ldap_attributes, :scsb_patron_information
  attr_reader :ldap_attributes

  before_create :set_personal_info_via_ldap
  after_initialize :set_personal_info_via_ldap

  # before_create :set_barcode_via_oracle
  after_initialize :set_barcode_via_oracle

  # we don't need this
  # but during initial development, let's fetch anyway,
  # more info can't hurt.
  # 8/5 - going prod, turn this off.
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
    if uid

      ldap_args = APP_CONFIG['ldap_connection_details']

      raise "LDAP config needs 'host'" unless ldap_args.has_key?(:host)
      raise "LDAP config needs 'port'" unless ldap_args.has_key?(:port)
      raise "LDAP config needs 'base'" unless ldap_args.has_key?(:base)

      Rails.logger.debug "Querying LDAP #{ldap_args.inspect}"
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
        _mail = (entry[:mail].kind_of?(Array) ? entry[:mail].first : entry[:mail]).to_s
        if _mail.length > 6 and _mail.match(/^[\w.]+[@][\w.]+$/)
          self.email = _mail
        else
          self.email = uid + '@columbia.edu'
        end
        self.last_name = (entry[:sn].kind_of?(Array) ? entry[:sn].first : entry[:sn]).to_s
        self.first_name = (entry[:givenname].kind_of?(Array) ? entry[:givenname].first : entry[:givenname]).to_s
      end
    end

    return self
  end

  def set_barcode_via_oracle
    if uid
      # connection_details = APP_CONFIG['voyager_connection']['oracle']
      # oracle_connection = Voyager::OracleConnection.new(connection_details)
      oracle_connection = Voyager::OracleConnection.new()
      patron_id = oracle_connection.retrieve_patron_id(uid)
      patron_barcode = oracle_connection.retrieve_patron_barcode(patron_id)
      self.barcode = patron_barcode
    end

    return self

  end


  def login
    self.uid.split('@').first
  end

  def email
    super || "#{login}@columbia.edu"
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
    affils.each do |affil|
      # TODO
      return true if affil.match(/CUL_role-clio/)
    end
    return false
  end

  def offsite_blocked?
    return false unless affils
    affils.each do |affil|
      return true if affil.match(/CUL_role-clio-.*-blocked/)
    end
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

  # UNUSED
  def get_scsb_patron_information
    raise # UNUSED
    return {} if barcode.blank?
    institution_id = 'CUL'
    @scsb_patron_information = Recap::ScsbRest.get_patron_information(barcode, institution_id) || {}
  end


end
