module Service
  class Paging < Service::Base

    def build_service_url(params, bib_record, current_user)

      illiad_params = get_illiad_params(bib_record)

      illiad_full_url = get_illiad_full_url(illiad_params)
      
      return illiad_full_url
    end


    private

    def get_illiad_full_url(illiad_params)
      # Base URL to CUL's hosted Illiad - for ZCU (not ZCH / HSL)
      illiad_base_url   = APP_CONFIG[:paging][:illiad_base_url]
      illiad_url = illiad_base_url + '?' + illiad_params.to_query
      
      # Patrons always access Illiad through our CUL EZproxy
      ezproxy_url = APP_CONFIG[:paging][:ezproxy_url]

      illiad_full_url = ezproxy_url + '?url=' + illiad_url
      
      return illiad_full_url
    end
    
    
    def get_illiad_params(bib_record)
      illiad_params = {}
      
      # Illiad param keys need to match the Illiad form field names
      illiad_params['Action']   = '10'
      illiad_params['Form']     = '99'
      
      illiad_params['title']    = bib_record.title
      illiad_params['author']   = bib_record.author
      
      return illiad_params
    end

    # def setup_form_locals(bib_record)
    #   bib_record.fetch_voyager_availability
    #
    #   locals = { bib_record: bib_record }
    #   locals
    # end

    # def send_emails(params, bib_record, current_user)
    #   mail_params = {
    #     bib_record: bib_record,
    #     barcodes:  params[:itemBarcodes],
    #     patron_uni: current_user.uid,
    #     patron_email: current_user.email,
    #     staff_email: APP_CONFIG[:paging][:staff_email]
    #   }
    #   # mail request to staff
    #   FormMailer.with(mail_params).paging.deliver_now
    # end

    # def get_extra_log_params(params)
    #   call_number = params[:call_number] || ''
    #   callnumber_sortable = Lcsort.normalize(call_number)
    #
    #   extra_log_params = {
    #     barcodes:      params[:itemBarcodes].join('/ '),
    #     callnumber:    call_number,
    #     callnumber_sortable:  callnumber_sortable,
    #     volumne_note:  params[:volume_note],
    #     note:          params[:note],
    #   }
    # end

    # def get_confirmation_locals(params, bib_record, current_user)
    #   confirm_locals = {
    #     bib_record: bib_record,
    #     barcodes:  params[:itemBarcodes],
    #     patron_uni: current_user.uid,
    #     patron_email: current_user.email,
    #   }
    #   confirm_locals
    # end

  end
end

