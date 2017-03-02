

# Called like this from the controller:
#   solr_connection = Clio::SolrConnection.new()
#   marc = solr_connection.retrieve_marc(bib_id)
module Clio
  class SolrConnection

    MARC_FIELD = 'marc_display'

    def initialize
      solr_args = APP_CONFIG['solr_connection_details'].symbolize_keys!
      raise "Solr config missing!" unless solr_args.present?
      raise "Solr config missing 'url'" unless solr_args.has_key?(:url)
      @solr_connection = RSolr.connect url: solr_args[:url]
    end

    def retrieve_marcxml(bib_id = nil)
      raise "retrieve_marc() needs bib_id" unless bib_id.present?

      solr_doc = fetch_solr_doc(bib_id)
      return nil unless solr_doc.present?

      marc = solr_doc_to_marcxml(solr_doc)
    end

    def fetch_solr_doc(bib_id = nil)
      raise "fetch_solr_doc() needs bib_id" unless bib_id.present?

      # Use the traditional 'select' handler to query for the id
      #   params = { q: "id:#{bib_id}", fl: 'marc_display', facet: 'off'}
      # Use the 'document' handler to fetch a specific document by id
      #   e.g., http://SERVER:PORT/solr/CORE/select?qt=document&id=1234
      params = { qt: 'document', id: bib_id, fl: "id,#{MARC_FIELD}"}

      response = @solr_connection.get 'select', params: params

      # May be nil if no doc not was found
      solr_doc = response['response']['docs'].first
    end

    def solr_doc_to_marcxml(solr_doc = nil)
      raise "solr_doc_to_marcxml() needs solr_doc" unless solr_doc.present?

      # May be nil if this doc doesn't have this field
      return solr_doc[MARC_FIELD]
    end

  end
end