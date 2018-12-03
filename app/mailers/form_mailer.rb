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
end
