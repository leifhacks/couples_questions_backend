# frozen_string_literal: true

#-------------------------------------------------------------------------------
# PerformAsyncReindexWorker
#-------------------------------------------------------------------------------
class PerformAsyncReindexWorker
  include Sidekiq::Worker

  sidekiq_options retry: false

  def perform(klass, style = 'async', start_id = 0)
    if style == 'async'
      result = klass.constantize.reindex(mode: :async, refresh_interval: '30s')
      index_name = result[:index_name]
      MonitorAsyncReindexWorker.perform_in(5.seconds, klass, index_name)
    else
      klass.constantize.in_batches do |models|
        next if models.last.id < start_id

        PerformBatchReindexWorker.perform_async(klass, models.pluck(:id))
      end
    end
  end
end
