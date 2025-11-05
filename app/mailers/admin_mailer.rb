# frozen_string_literal: true

#-------------------------------------------------------------------------------
# This class sends mails to admin
#-------------------------------------------------------------------------------
class AdminMailer < ApplicationMailer
  ADMIN_MAIL = 'support@leifhacks-apps.com'

  def send_mail(subject, body)
    delivery_options = { address: 'smtp.gmail.com',
                         port: 587,
                         user_name: ENV['ADMIN_MAIL_USER_NAME'],
                         password: ENV['ADMIN_MAIL_PASSWORD'],
                         authentication: 'plain',
                         enable_starttls_auto: true,
                         raise_delivery_errors: true }

    mail(to: ADMIN_MAIL, subject: subject, delivery_method_options: delivery_options) do |format|
      format.text { render plain: body }
    end
  end
end
