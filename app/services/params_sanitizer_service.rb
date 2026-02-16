# frozen_string_literal: true

#-------------------------------------------------------------------------------
# Service class which sanitizes the parameters
#-------------------------------------------------------------------------------
class ParamsSanitizerService
  def sanitize(params)
    msg_params = params.clone
    msg_params['id_token'] = msg_params['id_token'].truncate(10) unless msg_params['id_token'].nil?
    msg_params['device_token'] = msg_params['device_token'].truncate(10) unless msg_params['device_token'].nil?
    msg_params['access_token'] = msg_params['access_token'].truncate(10) unless msg_params['access_token'].nil?
    msg_params['refresh_token'] = msg_params['refresh_token'].truncate(10) unless msg_params['refresh_token'].nil?
    msg_params['item_data'] = msg_params['item_data'].to_s.truncate(30) unless msg_params['item_data'].nil?
    msg_params['image_data'] = msg_params['image_data'].to_s.truncate(10) unless msg_params['image_data'].nil?
    msg_params['audio_data'] = msg_params['audio_data'].to_s.truncate(10) unless msg_params['audio_data'].nil?
    msg_params['receipt_data'] = msg_params['receipt_data'].to_s.truncate(30) unless msg_params['receipt_data'].nil?
    
    msg_params
  end
end