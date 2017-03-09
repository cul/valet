module OffsiteRequestsHelper

  def toc_link(clio_record, barcode)
    if clio_record.tocs[barcode]
      link_to "Table of Contents", clio_record.tocs[barcode]
    else
      return ''
    end
  end
end
