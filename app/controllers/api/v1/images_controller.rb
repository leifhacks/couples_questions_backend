# frozen_string_literal: true

module Api
  module V1
    #---------------------------------------------------------------------------
    # A controller class for image requests
    #---------------------------------------------------------------------------
    class ImagesController < GenericController
      include ::UserAuthentication
      before_action :authenticate_user!
      
      def initialize
        super(Validate::Noop, Base64Decoder.new)
        @image_service = ImageStorageService.new(Base64FileStorageService.new, mini_magick_service: nil, moderation_service: ModerationService.new)
      end

      #-------------------------------------------------------------------------
      # params: id_token, file_path, image_data
      #-------------------------------------------------------------------------
      def up
        return render json: { error: 'no image_data provided' } unless params.include?(:image_data)

        image_data = params[:image_data]

        file_path = relative_path
        return render json: { error: 'invalid_filename' }, status: :bad_request if file_path.nil?

        @image_service.call(image_data, file_path)
      rescue => e
        Rails.logger.info("#{self.class}.#{__method__}: Failed: #{e}")
        render json: { error: 'failed' }
      else
        render json: { status: 'ok', file_name: file_path }
      end

      private

      def relative_path
        Pathname.new(File.join(IMAGES_SUB_DIR, current_user.uuid, 'profile_pic_' + Time.now.to_i.to_s + '.jpg')).cleanpath.to_s
      end
    end
  end
end
