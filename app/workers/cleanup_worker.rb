class CleanupWorker
  include Sidekiq::Worker

  def perform
    devices = ClientDevice.all
    tokens = devices.reject {|d| d.platform_from_token == 'ios' }.pluck(:device_token)
    service = FcmPushService.new(FcmClientService.new, StorePushResponseService.new(ClientDevice), JSON, {})
    service.call(tokens, nil, nil)

    CleanupCaller.new(ClientDevice).call
    CleanupCaller.new(User).call
  end
end
