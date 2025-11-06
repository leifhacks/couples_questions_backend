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

        # sanitize relative path (allow subdirectories, deny traversal/backslashes)
        rel_path = sanitized_relative_path(file_path)
        return render json: { error: 'invalid_filename' }, status: :bad_request if rel_path.nil?

        @image_service.call(image_data, rel_path)
      rescue => e
        Rails.logger.info("#{self.class}.#{__method__}: Failed: #{e}")
        render json: { error: 'failed' }
      else
        render json: { status: 'ok', file_name: rel_path }
      end

      private

      def sanitized_relative_path(path)
        raw = path.to_s
        return nil if raw.blank?
        return nil if raw.include?("\\")

        # ensure each segment is safe
        segments = raw.split('/')
        return nil if segments.any? { |s| s.blank? || s == '.' || s == '..' || !(s =~ /\A[\w\-\.]+\z/) }

        rel = Pathname.new(File.join(IMAGES_SUB_DIR, raw)).cleanpath.to_s
        return nil unless rel.start_with?("#{IMAGES_SUB_DIR}/") || rel == IMAGES_SUB_DIR
        rel
      end
    end
  end
end
