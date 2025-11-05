#-------------------------------------------------------------------------------
# This service class decodes Base64 encoded Strings containing a hash of
# Strings.
#-------------------------------------------------------------------------------
class Base64Decoder
  def call(encoded_string)
    JSON.parse(Base64.decode64(encoded_string))
  end
end
