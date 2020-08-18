class FormMailer < ApplicationMailer
  default from: 'noreply@library.columbia.edu'

  ###
  ### BEARSTOR - staff request email and patron confirm email
  ###

  # Email request to staff
  def bearstor_request
    @params = params
    to      = params[:staff_email]
    from    = "Barnard Remote Request Service <#{params[:staff_email]}>"
    title   = params[:bib_record].title
    subject = "New BearStor request [#{title}]"
    mail(to: to, from: from, subject: subject)
  end

  # Email confirmation to Patron
  def bearstor_confirm
    to = params[:patron_email]
    from = "Barnard Remote Request Service <#{params[:staff_email]}>"
    title = params[:bib_record].title
    subject = "BearStor Request Confirmation [#{title}]"
    mail(to: to, from: from, subject: subject)
  end

  ###
  ### PRECAT - single mail to both staff and patron
  ###
  def precat
    to = params[:patron_email] + ', ' + params[:staff_email]
    from = "Butler Circulation <#{params[:staff_email]}>"
    title = params[:bib_record].title
    subject = "Precat Search Request [#{title}]"
    mail(to: to, from: from, subject: subject)
  end
  
  ###
  ### RECAP - confirmation emails to patrons
  ###
  
  def recap_loan_confirm
    to = params['emailAddress']
    from = 'recap@library.columbia.edu'
    recap_subject = 'Offsite Loan Confirmation'
    recap_subject += " [#{params['titleIdentifier']}]" if params['titleIdentifier']
    recap_subject += " (#{Rails.env})" if Rails.env != 'valet_prod'
    subject = recap_subject
    # Make params available within template by using an instance variable
    @params = params
    mail(to: to, from: from, subject: subject)
  end

  def recap_scan_confirm
    to = params['emailAddress']
    from = 'recap@library.columbia.edu'
    recap_subject = 'Offsite Scan Confirmation'
    recap_subject += " [#{params['titleIdentifier']}]" if params['titleIdentifier']
    recap_subject += " (#{Rails.env})" if Rails.env != 'valet_prod'
    subject = recap_subject
    # Make params available within template by using an instance variable
    @params = params
    mail(to: to, from: from, subject: subject)
  end

  # ###
  # ### PAGING - mail to staff
  # ###
  # def paging
  #   to = params[:staff_email]
  #   from = "Butler Circulation <#{params[:staff_email]}>"
  #   title = params[:bib_record].title
  #   subject = "Paging Request [#{title}]"
  #   mail(to: to, from: from, subject: subject)
  # end


  ###
  ### AVERY ONSITE - mail to staff
  ###
  def avery_onsite_request
    @params = params
    to      = params[:staff_email]
    from    = "Avery Onsite Request Service <#{params[:staff_email]}>"
    title   = params[:bib_record].title
    subject = "New request for Avery On-Site Access [#{title}]"
    mail(to: to, from: from, subject: subject)
  end

end
