# frozen_string_literal: true

module Telegram
  class WebhookController < ApplicationController
    skip_before_action :verify_authenticity_token

    # POST /telegram/webhook
    def receive
      payload = request.body.read
      data = JSON.parse(payload, symbolize_names: true)

      # Handle Telegram Mini App auth
      if data[:message] && data[:message][:text] == "/start"
        handle_start_command(data[:message])
      end

      head :ok
    end

    private

    def handle_start_command(message)
      # Extract initData from Telegram Mini App
      # This would be sent separately from the frontend
      Rails.logger.info("Telegram start command received: #{message}")
    end

    def validate_telegram_init_data(init_data)
      # Validate Telegram initData signature
      # Implementation depends on Telegram Bot API
      true
    end
  end
end
