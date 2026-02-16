# frozen_string_literal: true

module Api
  module V1
    #---------------------------------------------------------------------------
    # A controller class for transcription audio uploads
    #---------------------------------------------------------------------------
    class TranscriptionsController < GenericController
      def initialize
        super(Validate::Noop, Base64Decoder.new)
        @open_ai_service = OpenAiService.new
      end

      #-------------------------------------------------------------------------
      # params: id_token, audio_data
      #-------------------------------------------------------------------------
      def get
        return render json: { error: 'no audio_data provided' } unless params.include?(:audio_data)

        audio_data = params[:audio_data]
        prompt = 'Transcribe short spoken license plate letters and digits in varying languages. Return uppercase letters and digits.'
        transcription = @open_ai_service.transcribe_audio(audio_data, prompt: prompt)
      rescue => e
        Rails.logger.info("#{self.class}.#{__method__}: Failed: #{e}")
        render json: { error: 'failed' }
      else
        render json: { status: 'ok', file_name: transcription }
      end
    end
  end
end
