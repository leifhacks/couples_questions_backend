#-------------------------------------------------------------------------------
# This is the downloader service for local files.
#-------------------------------------------------------------------------------
class LocalFileDownloader
  def initialize(file_utils, http_api, downloader_service)
    @file_utils = file_utils
    @http_api = http_api
    @downloader_service = downloader_service
  end

  def call(link, path)
    if @file_utils.exist?(path)
      @file_utils.delete(path)
      Rails.logger.info("#{self.class}.#{__method__}: Removed existing file #{path}")
    end

    @downloader_service.download(link, destination: path)
  end
end
