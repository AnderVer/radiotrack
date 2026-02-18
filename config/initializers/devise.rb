# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data.
# Generate with: openssl rand -hex 64
Rails.application.credentials.secret_key_base ||= ENV["SECRET_KEY_BASE"]

# Devise secret key for token generation
Devise.secret_key ||= ENV["DEVISE_SECRET_KEY"] || Rails.application.credentials.secret_key_base
