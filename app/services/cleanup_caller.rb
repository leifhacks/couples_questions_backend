#-------------------------------------------------------------------------------
# Service class for calling the cleanup method of the model
#-------------------------------------------------------------------------------
class CleanupCaller
  def initialize(model)
    @model = model
  end

  def call
    destroyed = @model.cleanup
    return if destroyed.blank?

    msg = "#{self.class}.#{__method__}: Destroyed #{destroyed} #{@model}(s)."
    Rails.logger.info(msg)
  end
end
