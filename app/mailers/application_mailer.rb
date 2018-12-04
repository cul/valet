# app/mailers/application_mailer.rb
class ApplicationMailer < ActionMailer::Base
  default from: 'noreply@library.columbia.edu'
  layout 'mailer'
end
