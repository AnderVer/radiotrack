# frozen_string_literal: true

module Api
  class RecognitionController < ApplicationController
    skip_before_action :verify_authenticity_token

    # POST /api/recognition/callback
    # Receives callbacks from AudD/ACRCloud recognition service
    def callback
      payload = request.body.read
      data = JSON.parse(payload, symbolize_names: true)

      RadioRecognitionService.process_callback(data)

      head :ok
    rescue JSON::ParserError => e
      Rails.logger.error "Invalid callback payload: #{e.message}"
      head :bad_request
    end
  end
end
