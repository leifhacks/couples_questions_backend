#-------------------------------------------------------------------------------
# This is a service which stores base 64 to a local file
#-------------------------------------------------------------------------------
class Base64FileStorageService
  def call(data, path)
    if File.exist?(path)
      File.delete(path)
      Rails.logger.info("#{self.class}.#{__method__}: Removed existing file #{path}")
    end

    decoded_data = Base64.decode64(data)

    dir_name = File.dirname(path)
    unless File.directory?(dir_name)
      FileUtils.mkdir_p(dir_name)
    end

    File.open(path, 'wb') do |f|
      f.write(decoded_data)
    end
  end
end
