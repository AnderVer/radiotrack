# frozen_string_literal: true

module Users
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    # VK OAuth callback
    def vk
      handle_oauth("vk")
    end

    # Yandex OAuth callback
    def yandex
      handle_oauth("yandex")
    end

    # Telegram callback (handled via webhook)
    def telegram
      handle_oauth("telegram")
    end

    def failure
      redirect_to root_path, alert: "Authentication failed: #{params[:message]}"
    end

    private

    def handle_oauth(provider)
      identity = Identity.find_by(provider: provider, uid: auth.uid)

      if identity.present?
        # Existing user
        sign_in_and_redirect identity.user, event: :authentication
        set_flash_message(:notice, :success, kind: provider.capitalize) if is_navigational_format?
      else
        # Check if user with this email exists
        user = User.find_by(email: auth.info.email)

        if user
          # Add new identity to existing user
          user.identities.create!(provider: provider, uid: auth.uid, access_token: auth.credentials.token)
          sign_in_and_redirect user, event: :authentication
          set_flash_message(:notice, :success, kind: provider.capitalize) if is_navigational_format?
        else
          # Create new user
          user = User.create!(
            email: auth.info.email,
            password: Devise.friendly_token[0, 20]
          )
          user.identities.create!(
            provider: provider,
            uid: auth.uid,
            access_token: auth.credentials&.token
          )
          sign_in_and_redirect user, event: :authentication
          set_flash_message(:notice, :success, kind: provider.capitalize) if is_navigational_format?
        end
      end
    end

    def auth
      @auth ||= request.env["omniauth.auth"]
    end
  end
end
