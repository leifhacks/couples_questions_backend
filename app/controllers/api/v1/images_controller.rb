# frozen_string_literal: true

module Api
  module V1
    #---------------------------------------------------------------------------
    # A controller class for image requests
    #---------------------------------------------------------------------------
    class ImagesController < GenericController
      def initialize
        super(Validate::ImageVerification, Base64Decoder.new)
        @image_service = ImageStorageService.new(Base64FileStorageService.new, mini_magick_service: nil, moderation_service: ModerationService.new)
      end

      #-------------------------------------------------------------------------
      # params: id_token, file_path, image_data
      #-------------------------------------------------------------------------
      def up
        return render json: { error: 'no image_data provided' } unless params.include?(:image_data)

        file_path = params[:file_path]
        image_data = params[:image_data]

        file_name = "#{IMAGES_SUB_DIR}/#{file_path}"
        @image_service.call(image_data, file_name)
      rescue => e
        Rails.logger.info("#{self.class}.#{__method__}: Failed: #{e}")
        render json: { error: 'failed' }
      else
        render json: { status: 'ok', file_name: file_name }
      end

      #-------------------------------------------------------------------------
      # params: id_token, file_path
      #-------------------------------------------------------------------------
      def down
        file_path = params[:file_path]
        full_path = @image_service.get_full_image_path(file_path)

        if File.exist?(full_path)
          send_file full_path, type: 'image', disposition: 'inline'
        else
          render json: { error: 'failed' }
        end
      end
    end
  end
end
