module Service
  class Ill < Service::Base

    def form_handler(params, bib_record, current_user)
      openurl = bib_record.openurl
      ezproxy_url = @config[:ezproxy_url] 

      campus = params['campus']
      illiad_url = build_illiad_url(campus)

      redirect_url = ezproxy_url + 
                     '?url=' + illiad_url + 
                     '?' + openurl
      return redirect_to redirect_url
    end
    
    def build_illiad_url(campus)
      illiad_url  = 'https://columbia.illiad.oclc.org/illiad/' + 
                    campus + '/illiad.dll/OpenURL'
    end
    
  end
end