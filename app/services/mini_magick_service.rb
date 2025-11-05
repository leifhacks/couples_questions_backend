# frozen_string_literal: true

#-------------------------------------------------------------------------------
# This is a storage service for image thumbnails
#-------------------------------------------------------------------------------
class MiniMagickService
  def initialize(thumb_size: THUMBNAIL_SIZE)
    @thumb_size = thumb_size
  end

  def create_thumbnail(local_file_path)
    image = MiniMagick::Image.open(local_file_path)
    image.resize "#{@thumb_size}x#{@thumb_size}"
    image.write("#{local_file_path}.thumb")
    File.chmod(4600, "#{local_file_path}.thumb")
  end

  def convert(input_file_path, output_file_path, remove_input: false)
    MiniMagick::Tool::Convert.new do |convert|
      convert << input_file_path
      convert << output_file_path
    end
    File.chmod(4600, output_file_path)
    File.delete(input_file_path) if remove_input
  end
end