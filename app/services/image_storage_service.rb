# frozen_string_literal: true

#-------------------------------------------------------------------------------
# This is a storage service for images
#-------------------------------------------------------------------------------
class ImageStorageService
  def initialize(get_image_service, mini_magick_service: nil, moderation_service: nil, base_path: IMAGE_BASE_PATH)
    @get_image_service = get_image_service
    @mini_magick_service = mini_magick_service
    @moderation_service = moderation_service
    @base_path = base_path
  end

  def call(image, file_name)
    local_file_path = get_full_image_path(file_name)
    @get_image_service.call(image, local_file_path)
    File.chmod(4600, local_file_path)
    moderate(local_file_path)
    @mini_magick_service.create_thumbnail(local_file_path) unless @mini_magick_service.nil?
    true
  end

  def moderate(local_file_path)
    mod_result = @moderation_service.call([], [local_file_path]) unless @moderation_service.nil?
    return if mod_result.blank?

    File.delete(local_file_path)
    raise "Image contains prohibited content"
  end

  def get_full_image_path(file_name)
    "#{@base_path}/#{file_name}"
  end
end
