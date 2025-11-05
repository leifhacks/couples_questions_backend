# frozen_string_literal: true

#-------------------------------------------------------------------------------
# MonitorAsyncReindexWorker
#-------------------------------------------------------------------------------
class MonitorAsyncReindexWorker
  include Sidekiq::Worker

  def perform(klass, index_name)
    Searchkick.redis = Redis.new
    status = Searchkick.reindex_status(index_name)
    if status[:completed]
      Rails.logger.info("#{self.class}.#{__method__}: #{index_name} completed")
      klass.constantize.search_index.promote(index_name)
    else
      self.class.perform_in(10.seconds, klass, index_name)
    end
  end
end
