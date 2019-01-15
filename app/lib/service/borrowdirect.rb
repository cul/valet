# module Service
#   class XBorrowdirect < Service::Base
# 
#     # Borrow Direct service requires:
#     # - unexpired patron record
#     # - not blocked for fines
#     # - no overdue recalls
#     # - active patron barcode
#     # Also, must either
#     # or
#     def patron_eligible?(current_user = nil)
#       return false unless current_user
# 
#       # WIP
#       # return false if current_user.expired_patron_record?
#       # return false if current_user.patron_blocked?
#       # return false if current_user.patron_has_recalls?
#       # 
#       # # two different kinds of eligible patrons...
#       # on-campus:  patron_group list && 9-digit barcode
#       # 
#       # 2cul: patron-group && patron-stat && barcode prefix
#       
# 
#       # No disqualifying conditions?  Then yes, patron is eligible.
#       return true
#     end
# 
# 
#     # Borrow Direct bounces to Relais D2D,
#     # with the following fields:
#     # LS - Library Symbol (hardcoded:  COLUMBIA)
#     # PI - Patron Identifier (Voyager Barcode)
#     # query - query by isbn, issn, or title/author, see:
#     # https://relais.atlassian.net/wiki/spaces/ILL/pages/132579329/Using+other+discovery+tools
#     # A full example is: https://bd.relaisd2d.com/?LS=COLUMBIA&PI=123456789&query=ti%3D%22Piotr%22+and+au%3D%22Sokorski%2C+Wodzimierz%22
#     #
#     def build_service_url(_params, bib_record, current_user)
#       url = 'https://bd.relaisd2d.com/'
#       url += '?LS=COLUMBIA'
#       url += '&PI=' + current_user.barcode
#       url += '&query=' + build_query(bib_record)
#       url
#     end
# 
#     def build_query(bib_record)
#       query = ''
#       if bib_record.issn.present?
#         query = 'issn=' + bib_record.issn.first
#       elsif bib_record.isbn.present?
#         query = 'isbn=' + bib_record.isbn.first
#       else
#         query = 'ti="' + bib_record.title + '"'
#         if bib_record.author.present?
#           query += ' and au="' + bib_record.author + '"'
#         end
#       end
#       relais_escape(query)
#     end
# 
#     def relais_escape(string)
#       # standard Rails CGI param escaping...
#       string = CGI.escape(string)
#       # ...but then also use %20 instead of + for spaces
#       string.gsub!(/\+/, '%20')
#       string
#     end
# 
#   end
# end
