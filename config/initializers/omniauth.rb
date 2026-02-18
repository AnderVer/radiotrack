# Be sure to restart your server when you modify this file.

# OmniAuth configuration for VK, Yandex, Telegram
Rails.application.config.middleware.use OmniAuth::Builder do
  # VK OAuth - configure with your app credentials
  # provider :vk, ENV['VK_APP_ID'], ENV['VK_APP_SECRET']
  
  # Yandex OAuth
  # provider :yandex, ENV['YANDEX_APP_ID'], ENV['YANDEX_APP_SECRET']
end

# Allow OAuth in test mode
OmniAuth.config.test_mode = Rails.env.test?
