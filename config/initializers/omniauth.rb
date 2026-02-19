# frozen_string_literal: true

# OmniAuth OAuth 2.0 Configuration
# Providers: VK (VKontakte), Yandex

Rails.application.config.middleware.use OmniAuth::Builder do
  # VK (VKontakte) OAuth
  # App ID и Secret Key получаем здесь: https://vk.com/editapp?act=create
  # Standalone-приложение, права: email
  if ENV["VK_APP_ID"].present? && ENV["VK_APP_SECRET"].present?
    provider :vk, ENV["VK_APP_ID"], ENV["VK_APP_SECRET"], {
      scope: "email",
      display: "popup",
      response_type: "code",
      image_version: "50x50"
    }
  end

  # Yandex OAuth
  # Client ID и Secret получаем здесь: https://oauth.yandex.ru/client/new
  # Права: login:email, login:info
  if ENV["YANDEX_CLIENT_ID"].present? && ENV["YANDEX_CLIENT_SECRET"].present?
    provider :yandex, ENV["YANDEX_CLIENT_ID"], ENV["YANDEX_CLIENT_SECRET"], {
      scope: "login:email,login:info"
    }
  end
end

# OmniAuth URL endpoints:
# /users/auth/vk
# /users/auth/yandex
# /users/auth/vk/callback
# /users/auth/yandex/callback

# Настройки безопасности
OmniAuth.config.allowed_request_methods = [:post, :get]

# Логирование в development
OmniAuth.config.logger = Rails.logger if Rails.env.development?
