# Our CLIO Record class is primarily a MARC::Record container,
# with a few convenience methods specific to this application.
# 
# It is not a Blacklight Document.
class ClioRecord
  attr_reader :marc_record, :holdings, :barcodes,
              :availability, :tocs, :owningInstitution

  def initialize(marc_record = nil)
    @marc_record = marc_record
    self.populate_holdings
    self.populate_barcodes
    # self.fetch_availabilty
    self.fetch_tocs
    # self.fetch_locations
    self.populate_owningInstitution
    @availability = {}
  end

  def self.new_from_bib_id(bib_id = nil)
    if bib_id.blank?
      Rails.logger.error "ClioRecord::new_from_bib_id() missing bib_id!"
      return nil
    end
    return nil unless bib_id.present?

    solr_connection = Clio::SolrConnection.new()
    raise "Clio::SolrConnection failed!" unless solr_connection

    marcxml = solr_connection.retrieve_marcxml(bib_id)
    if marcxml.blank?
      Rails.logger.error "ClioRecord::new_from_bib_id() marcxml nil!"
      return nil
    end

    reader = MARC::XMLReader.new(StringIO.new(marcxml))
    marc_record = reader.entries[0]
    if marc_record.blank?
      Rails.logger.error "ClioRecord::new_from_bib_id() marc_record nil!"
      return nil
    end

    ClioRecord.new(marc_record)
  end

  def key
    case owningInstitution
    when 'CUL'
      return @marc_record['001'].value
    else
      return @marc_record['009'].value
    end
  end

  def title
    title ||= []
    "abcfghknps".split(//).each do |subfield|
      if @marc_record['245']
        title << @marc_record['245'][subfield]
      end
    end
    return title.compact.join(' ')
  end

  def author
    author ||= []
    ['100', '110', '111'].each do |field|
      next unless @marc_record[field]
      'abcdefgjklnpqtu'.split(//).each do |subfield|
        author << @marc_record[field][subfield]
      end
      # stop once the 1st possible field is found & processed
      break
    end
    return author.compact.join(' ')
  end

  def publisher
    publisher ||= []
    ['260', '264'].each do |field|
      next unless @marc_record[field]
      'abcefg3'.split(//).each do |subfield|
        publisher << @marc_record[field][subfield]
      end
      # stop once the 1st possible field is found & processed
      break
    end
    return publisher.compact.join(' ')
  end


  def populate_owningInstitution
    return 'CUL' unless holdings.present?

    case holdings.first[:location_code]
    when 'scsb-nypl'
      @owningInstitution = 'NYPL'
    when 'scsb-pul'
      @owningInstitution = 'PUL'
    else
      @owningInstitution = 'CUL'
    end

  end

  # Drill down into the MARC fields to build an
  # array of holdings.  See:
  # https://wiki.library.columbia.edu/display/cliogroup/Holdings+Revision+project
  def populate_holdings
    mfhd_fields  = {
      summary_holdings:         '866',
      supplements:              '867',
      indexes:                  '868',
      public_notes:             '890',
      donor_information:        '891',
      reproduction_note:        '892',
      url:                      '893',
      acquisitions_information: '894',
      current_issues:           '895',
    }

    # Process each 852, creating a new mfhd for each
    holdings = Hash.new
    @marc_record.each_by_tag('852') do |tag852|
      mfhd_id = tag852['0']
      holdings[mfhd_id] = {
        mfhd_id:                  mfhd_id,
        location_display:         tag852['a'],
        location_code:            tag852['b'],
        display_call_number:      tag852['h'],
        items:                    [],
      }
      # And fill in all possible mfhd fields with empty array
      mfhd_fields.each_pair do |label, tag|
        holdings[mfhd_id][label] = []
      end
    end

    # Scan the MARC record for each of the possible mfhd fields,
    # if any found, add to appropriate Holding
    # (e.g., label :summary_holdings, tag '866')
    mfhd_fields.each_pair do |label, tag|
       @marc_record.each_by_tag(tag) do |mfhd_data_field|
         mfhd_id = mfhd_data_field['0']
         value = mfhd_data_field['a']
         next unless mfhd_id and value
         holdings[mfhd_id][label] << value
       end
    end

    # Now add the list of items to each holding.
    @marc_record.each_by_tag('876') do |item_field|
      # build the Item hash
      item = {
        item_id:            item_field['a'],
        use_restriction:    item_field['h'],
        temporary_location: item_field['l'],
        barcode:            item_field['p'],
        enum_chron:         item_field['3']
      }
      # Store this item hash in the apppropriate Holding
      mfhd_id = item_field['0']
      holdings[mfhd_id][:items] << item
    end

    # Now that all the data is matched up, we don't need
    # the hash of mfhd_id ==> holdings_hash
    # Just store an array of Holdings
    @holdings = holdings.values
  end

  def offsite_holdings
    holdings.select do |holding|
      LOCATIONS['offsite_locations'].include? holding[:location_code]
    end
  end

  def populate_barcodes
    # Single array of barcodes from all holdings, all items
    barcodes = @holdings.collect do |holdings|
      holdings[:items].collect do |item|
        item[:barcode]
      end
    end.flatten.uniq

    @barcodes = barcodes
  end

  # Fetch availability for each barcode from SCSB
  def fetch_availabilty
    @availability = Recap::ScsbRest.get_bib_availability(key, owningInstitution) || {}
  end

  # For each of the barcodes in this record (@barcodes),
  # check to see if there's a TOC.
  # If so, add the toc URL to this record's tocs Hash:
  # { 
  # 'CU12731471' => 'http://www.columbia.edu/cgi-bin/cul/toc.pl?CU12731471',
  #  ...etc...
  # }
  def fetch_tocs
    tocs = {}
    # SLOW FOR SERIALS WITH MANY MANY BARCODES
    # conn = Columbia::Web.open_connection()
    # @barcodes.each do |barcode|
    #   toc = Columbia::Web.get_toc_link(barcode, conn)
    #   if toc.present?
    #     tocs[barcode] = toc
    #   end
    # end
    # Hopefully faster?
    tocs = Columbia::Web.get_bib_toc_links(key)
    @tocs = tocs
  end

  def public_locations
    # basic set of public delivery locations
    basic_set = ['AR', 'BL', 'UT', 'BS', 'BU', 'EA', 'GE', 'HS', 'CJ', 'GS', 'LE', 'ML', 'MR', 'CA', 'SW']

    locations = {
      'OFF AVE'   => { default: 'AR', available: ['AR']},
      'OFF BIO'   => { default: 'CA', available: basic_set},
      'OFF BMC'   => { default: 'CV', available: ['CV']},
      'OFF BSSC'  => { default: 'BS', available: ['BS']},
      'OFF BUS'   => { default: 'BS', available: basic_set},
      'OFF CHE'   => { default: 'CA', available: basic_set},
      'OFF DOCS'  => { default: 'LE', available: basic_set},
      'OFF EAL'   => { default: 'EA', available: basic_set},
      'OFF EAN'   => { default: 'EA', available: ['EA']},
      'OFF EAX'   => { default: 'EA', available: basic_set},
      'OFF ENG'   => { default: 'CA', available: basic_set},
      'OFF FAX'   => { default: 'AR', available: ['AR']},
      'OFF GLG'   => { default: 'GE', available: basic_set},
      'OFF GLX'   => { default: 'BU', available: basic_set},
      'OFF GSC'   => { default: 'GS', available: basic_set},
      'OFF HSL'   => { default: 'HS', available: basic_set},
      'OFF HSR'   => { default: 'HS', available: basic_set},
      'OFF JOU'   => { default: 'CJ', available: basic_set},
      'OFF LEH'   => { default: 'LE', available: basic_set},
      'OFF LES'   => { default: 'LE', available: ['LE']},
      'OFF MAT'   => { default: 'ML', available: basic_set},
      'OFF MRR'   => { default: 'CF', available: ['CF']},
      'OFF MSC'   => { default: 'MR', available: ['MR']},
      'OFF MSR'   => { default: 'MR', available: ['MR']},
      'OFF MUS'   => { default: 'MR', available: basic_set},
      'OFF MVR'   => { default: 'MR', available: ['MR']},
      'OFF PHY'   => { default: 'CA', available: basic_set},
      'OFF PSY'   => { default: 'CA', available: basic_set},
      'OFF REF'   => { default: 'BU', available: basic_set},
      'OFF SCI'   => { default: 'CA', available: basic_set},
      'OFF SWX'   => { default: 'SW', available: basic_set},
      'OFF UNR'   => { default: 'UT', available: ['UT']},
      'OFF UTMRL' => { default: 'UT', available: ['UT']},
      'OFF UTN'   => { default: 'UT', available: basic_set},
      'OFF UTP'   => { default: 'UT', available: ['UT']},
      'OFF UTS'   => { default: 'UT', available: basic_set},
      'OFF WAR'   => { default: 'AR', available: basic_set}
    }
  end

  def location_labels
    labels = {
    'BC' => 'Bibliographic Control',
    'BT' => 'Butler Preservation',
    'CI' => 'Interlibrary Loan<',
    'CV' => 'Milstein Reserves',
    'MP' => 'Monographic Recon -- for MRP',
    'MZ' => 'ReCAP Coordinator',
    'IL' => 'ReCAP Interlibrary Loan',
    'AR' => 'Avery Library',
    'BL' => 'Barnard Library',
    'UT' => 'Burke Library (UTS)',
    'BS' => 'Business/Econ Library',
    'BU' => 'Butler Library',
    'EA' => 'East Asian Library',
    'EN' => 'Engineering Library',
    'GE' => 'Geology Library',
    'GS' => 'Lamont-Doherty Earth Observatory',
    'HS' => 'Health Sciences Library',
    'CJ' => 'Journalism Library',
    'LE' => 'Lehman Library',
    'RH' => 'Lehman Suite',
    'ML' => 'Mathematics Library',
    'CF' => '401 Butler Library (Microform Reading Room)',
    'MR' => 'Music &amp; Arts Library',
    'RS' => 'Rare Book Library',
    'CA' => 'Science &amp; Engineering Lib (NWC Building)',
    'SW' => 'Social Work Library'
  }
  end

end



