module OffsiteRequestsHelper

  # shortcuts used in several methods
  WWW  = 'http://www.columbia.edu'
  CGI  = 'http://www.columbia.edu/cgi-bin'
  LWEB = 'http://library.columbia.edu'

  def toc_link(clio_record = nil, barcode = nil)
    return '' unless clio_record.present? &&
                     clio_record.tocs.present? &&
                     barcode.present? &&
                     clio_record.tocs[barcode]
    label = 'Table of Contents'
    url = clio_record.tocs[barcode]
    link_to label, url, target: '_blank'
  end


  def legacy_offsite_request_link(clio_record = nil)
    return '' unless clio_record.present? &&
                     clio_record.key.present?
    label = 'Legacy Offsite Request Form'
    url   = "#{CGI}/cul/offsite2?#{clio_record.key}"
    link_to label, url, target: '_blank'
  end

  def my_library_account_link
    label = 'My Library Account'
    url   = "#{CGI}/cul/resolve?lweb0087"
    link_to label, url, target: '_blank'
  end

  def borrowing_info_link
    label = 'More Information'
    url   = "#{LWEB}/services/borrowing.html"
    link_to label, url, target: '_blank'
  end

  def to_library_info_link
    label = 'more info...'
    url = "#{LWEB}/find/request/off-site/item_to_library.html"
    link_to label, url, target: '_blank', class: 'info-link'
  end

  def electronic_info_link
    label = 'more info...'
    url = "#{LWEB}/find/request/off-site/electronic.html"
    link_to label, url, target: '_blank', class: 'info-link'
  end

  # For a given offsite location code ('OFF AVE', 'OFF BIO'),
  # return the default on-campus delivery location ('AR', 'CA')
  def get_delivery_default(offsite_location_code)
    delivery_config = get_delivery_config(offsite_location_code)
    # Each location should have it's own default oncampus delivery
    # location defined.  But if it doesn't, fallback to Butler.
    delivery_config['default'] || 'bu'
  end

  # For a given offsite location code ('OFF AVE', 'OFF BIO'),
  # return an array of available on-campus delivery locations.
  #   (by code, e.g., ['AR'] or ['AR', 'BL','UT'])
  def get_delivery_options(offsite_location_code)
    delivery_config = get_delivery_config(offsite_location_code)

    # If this config has an 'available' list defined,
    # return it.
    # Otherwise, just return the default list.
    delivery_config['available'] ||
      DELIVERY['standard_delivery_locations']
  end

  def get_delivery_config(offsite_location_code)
    delivery_config = DELIVERY[offsite_location_code]

    # If there are no specific delivery rules defined for 
    # this offsite location, treat it as if it were 'OFF GLX'
    delivery_config = DELIVERY['off,glx'] if delivery_config.blank?

    return delivery_config
  end

  # def delivery_select_tag(delivery_options = [], delivery_default = nil)
  def delivery_select_tag(offsite_location_code)
    delivery_options = get_delivery_options(offsite_location_code)
    delivery_default = get_delivery_default(offsite_location_code)
    options_array = delivery_options.map do |delivery_location_code|
      [LOCATIONS[delivery_location_code], delivery_location_code ]
    end

    select_tag(:deliveryLocation, options_for_select(options_array, delivery_default))
  end

  def location_label(location_code)
    return '' unless location_code
    location_name = LOCATIONS[location_code] || 'Offsite'
    return "#{location_name} (#{location_code.upcase})"
  end

  def holding_radio_button_label(holding)
    mfhd_id = holding[:mfhd_id]
    radio_button_id = "mfhd_id_#{mfhd_id}"
    label = 'Call number ' + holding[:display_call_number].upcase +
            ', location ' + location_label(holding[:location_code])

    return label_tag(radio_button_id, label)
  end


end
