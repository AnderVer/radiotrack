# Be sure to restart your server when you modify this file.

# OmniAuth configuration for VK, Yandex, Telegram
Rails.application.config.middleware.use OmniAuth::Builder do
  # VK OAuth
  # Get credentials from: https://vk.com/editapp?act=create
  # Redirect URI: https://your-domain.com/users/auth/vk/callback
  provider :vk,
           ENV.fetch("VK_APP_ID", nil),
           ENV.fetch("VK_APP_SECRET", nil),
           scope: "email",
           display: "popup",
           image_version: "medium"

  # Yandex OAuth
  # Get credentials from: https://oauth.yandex.ru/client/new
  # Redirect URI: https://your-domain.com/users/auth/yandex/callback
  provider :yandex,
           ENV.fetch("YANDEX_CLIENT_ID", nil),
           ENV.fetch("YANDEX_CLIENT_SECRET", nil),
           scope: "login:email"
end

# Allow OAuth in test mode
OmniAuth.config.test_mode = Rails.env.test?

# OmniAuth callbacks configuration
OmniAuth.config.allowed_request_methods = [:post, :get]
