# frozen_string_literal: true

#-------------------------------------------------------------------------------
# Model for Client Devices containing info about the devices a user owns
#-------------------------------------------------------------------------------
class ClientDevice < UuidRecord
  ISO_CODE_REGEX = /\A[a-z]{2}_[A-Z]{2}\z/

  belongs_to :user
  belongs_to :web_socket_connection, optional: true

  def self.cleanup
    response = '{"error"=>{"code"=>404, "message"=>"Requested entity was not found.", "status"=>"NOT_FOUND", "details"=>[{"@type"=>"type.googleapis.com/google.firebase.fcm.v1.FcmError", "errorCode"=>"UNREGISTERED"}]}}'

    unregistered_devices = where(last_response: response)
    result = unregistered_devices.size
    unregistered_devices.destroy_all

    result
  end

  def payload
    {
      uuid: uuid,
      platform: platform,
      iso_code: iso_code,
      timezone_name: timezone_name,
      timezone_offset_seconds: timezone_offset_seconds
    }
  end

  def platform_from_token
    device_token.include?(':') || device_token.include?('-') ? 'android' : 'ios'
  end

  def language_code
    iso_code.include?('_') ? iso_code.split('_').first : iso_code
  end
end
