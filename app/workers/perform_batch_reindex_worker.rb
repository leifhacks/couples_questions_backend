# frozen_string_literal: true

#-------------------------------------------------------------------------------
# PerformBatchReindexWorker
#-------------------------------------------------------------------------------
class PerformBatchReindexWorker
  include Sidekiq::Worker

  sidekiq_options retry: false

  def perform(klass, ids)
    klass.constantize.where(id: ids).reindex
    Rails.logger.info("#{self.class}.#{__method__}: #{klass} #{ids.to_s[-30..]} completed")
  end
end
