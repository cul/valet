class User < ActiveRecord::Base
  include Cul::Omniauth::Users

  serialize :affils, Array

  # # Include default devise modules. Others available are:
  # # :confirmable, :lockable, :timeoutable and :omniauthable
  # devise :database_authenticatable, :registerable,
  #        :recoverable, :rememberable, :trackable, :validatable


  before_create :set_personal_info_via_ldap
  after_initialize :set_personal_info_via_ldap

  before_create :set_barcode_via_oracle
  after_initialize :set_barcode_via_oracle

  def to_s
    if first_name
      first_name.to_s + ' ' + last_name.to_s
    else
      login
    end
  end

  def set_personal_info_via_ldap
    if uid

      ldap_args = APP_CONFIG['ldap_connection_details'].symbolize_keys!

      raise "LDAP config needs 'host'" unless ldap_args.has_key?(:host)
      raise "LDAP config needs 'port'" unless ldap_args.has_key?(:port)
      raise "LDAP config needs 'base'" unless ldap_args.has_key?(:base)

      entry = Net::LDAP.new({host: ldap_args[:host], port: ldap_args[:port]}).search(base: ldap_args[:base], :filter => Net::LDAP::Filter.eq("uid", uid)) || []
      entry = entry.first

      if entry
        puts "\n\n#{entry.inspect}\n\n"
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

  def offsite_eligible?
    return false unless affils
    affils.each do |affil|
      return true if affil.match(/CUL_role-clio-...$/)
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

end
