# frozen_string_literal: true

class Current < ActiveSupport::CurrentAttributes
  attribute :initiator_device_token

  def skip_broadcast_device?(device)
    return false if initiator_device_token.blank?

    device.device_token == initiator_device_token
  end
end

