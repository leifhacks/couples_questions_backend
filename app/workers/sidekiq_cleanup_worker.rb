require 'sidekiq/api'

#-------------------------------------------------------------------------------
# Worker class which performs a cleanup of all Sidekiq Queues
#-------------------------------------------------------------------------------
class SidekiqCleanupWorker
  include Sidekiq::Worker

  def perform
    Sidekiq::Queue.all.each &:clear
    Sidekiq::DeadSet.new.clear
    Sidekiq::RetrySet.new.clear
    Sidekiq::ScheduledSet.new.clear
  end
end
