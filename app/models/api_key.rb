#-------------------------------------------------------------------------------
# Model for API Keys
#-------------------------------------------------------------------------------
class ApiKey < ApplicationRecord
  before_create :generate_access_token

  private

  def generate_access_token
    loop do
      self.access_token = Sysrandom.hex
      break unless self.class.exists?(access_token: access_token)
    end
  end
end
