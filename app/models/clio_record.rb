# Our CLIO Record class is primarily a MARC::Record container,
# with a few convenience methods specific to this application.
# 
# It is not a Blacklight Document.
class ClioRecord
  attr_reader :marc_record

  def initialize(marc_record = nil)
    @marc_record = marc_record
  end

  def self.new_from_bib_id(bib_id = nil)
    return nil unless bib_id.present?

    solr_connection = Clio::SolrConnection.new()
    raise "Clio::SolrConnection failed!" unless solr_connection

    marcxml = solr_connection.retrieve_marcxml(bib_id)
    return nil unless marcxml.present?

    reader = MARC::XMLReader.new(StringIO.new(marcxml))
    marc_record = reader.entries[0]
    return nil unless marc_record

    ClioRecord.new(marc_record)
  end

  def key
    return marc_record['001'].value
  end
  def title
    title ||= []
    "abcfghknps".split(//).each do |subfield|
      if marc_record['245']
        title << marc_record['245'][subfield]
      end
    end
    return title.compact.join(' ')
  end
  def author
    author ||= []
    "abcdefgjklnpqtu".split(//).each do |subfield|
      if marc_record['100']
        author << marc_record['100'][subfield]
      elsif marc_record['110']
        author << marc_record['110'][subfield]
      elsif marc_record['111']
        author << marc_record['111'][subfield]
      end
    end
    return author.compact.join(' ')
  end
  def publisher
    publisher ||= []
    'abcefg3'.split(//).each do |subfield|
      if marc_record['260']
        publisher << marc_record['260'][subfield]
      elsif marc_record['264']
        publisher << marc_record['260'][subfield]
      end
    end
    return publisher.compact.join(' ')
  end

  # Drill down into the MARC fields to build an
  # array of holdings.  See:
  # https://wiki.library.columbia.edu/display/cliogroup/Holdings+Revision+project
  def holdings

  end

end
