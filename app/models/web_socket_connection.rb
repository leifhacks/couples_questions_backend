# frozen_string_literal: true

#-------------------------------------------------------------------------------
# Model for Web Socket Connections containing info about a web socket connection
#-------------------------------------------------------------------------------
class WebSocketConnection < ApplicationRecord
  has_one :client_device
end