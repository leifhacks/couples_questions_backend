redis = { url: 'redis://localhost:6379/4' }

Sidekiq.configure_client do |config|
  config.redis = redis
end

Sidekiq.configure_server do |config|
  config.redis = redis
end

Sidekiq.configure_server do |config|
  config.on(:startup) do
    SidekiqCleanupWorker.new.perform
  end
end
