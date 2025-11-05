# frozen_string_literal: true

#-------------------------------------------------------------------------------
# This class sends push messages via APNS
#-------------------------------------------------------------------------------
class ApnsPushService
  def initialize(store_service = nil, app_name = ENV['APNS_APP_NAME'], cert_path = ENV['APNS_CERTIFICATE_FILE_PATH'], key_id = ENV['APNS_KEY_ID'], team_id = ENV['APNS_TEAM_ID'])
    @store_service = store_service
    @app_name = app_name
    @connection = Apnotic::Connection.new(auth_method: :token, cert_path: cert_path, key_id: key_id, team_id: team_id)
  end

  def call(tokens, title, body, collapse_key = nil, data = {})
    alert = {'title' => title, 'body' => body}

    tokens.each do |token|
      send_alert(alert, token)
    end

    @connection.join
    @connection.close
  end

  private

  def send_alert(alert, token)
    notification = Apnotic::Notification.new(token)
    notification.alert = alert
    notification.topic = @app_name

    push = @connection.prepare_push(notification)
    push.on(:response) do |response|
      @store_service.call({token => {'body' => response.body, 'headers' => response.headers}})
    end

    @connection.push_async(push)
  end
end
