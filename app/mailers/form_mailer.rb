class FormMailer < ApplicationMailer
  default from: 'noreply@library.columbia.edu'

  # Email request to staff
  def bearstor_request
    @params = params
    to = params[:staff_email]
    title = params[:bib_record].title
    subject = "New BearStor request [#{title}]"
    mail(to: to, subject: subject)
  end

  # Email confirmation to Patron
  def bearstor_confirm
    to = params[:patron_email]
    title = params[:bib_record].title
    subject = "BearStor Request Confirmation [#{title}]"
    mail(to: to, subject: subject)
  end


end