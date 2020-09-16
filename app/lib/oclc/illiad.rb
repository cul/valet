# Common logic for interacting with the OCLC ILLiad system
module Oclc
  class Illiad
    
    # LIBSYS-3273 - some special characters choke ILLiad.
    # I can't get escaping to work, so just remove them.
    def self.clean_hash_values(hash)
      hash.each do |key, value|
        next unless key && value
        # strip problematic angle-bracket chars from the value
        value.gsub!(/\>/,'')
        value.gsub!(/\</,'')
        # other chars that shouldn't be in bib fields 
        value.gsub!(/\&/,'')
        value.gsub!(/\%/,'')
        value.gsub!(/\#/,'')
      end
      return hash
    end
    
  end
end
