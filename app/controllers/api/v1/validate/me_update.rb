# frozen_string_literal: true

module Api
  module V1
    module Validate
      module Me
        class Update
          include ActiveModel::Validations

          attr_accessor :name, :favorite_category_uuid, :image_path

          # Both fields are optional; allow empty updates
          def initialize(params = {})
            @name = params[:name]
            @favorite_category_uuid = params[:favorite_category_uuid]
            @image_path = params[:image_path]
          end
        end
      end
    end
  end
end


