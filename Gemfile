source "https://rubygems.org"
ruby "3.3.0"

gem "rails", "~> 8.0.0"
gem "bootsnap", require: false
gem "pg", "~> 1.5"
gem "puma", ">= 5.0"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "jbuilder"
gem "propshaft"
gem "solid_queue"

# HTML parsing for playlists
gem "nokogiri"

# HTTP client
gem "httparty"

# Authentication
gem "devise", require: "devise"
gem "omniauth-rails_csrf_protection"
gem "omniauth"
gem "omniauth-vkontakte"
gem "omniauth-yandex"

# Authorization
gem "pundit"

# CORS
gem "rack-cors"

group :development, :test do
  gem "debug", platforms: %i[mri windows]
  gem "rubocop-rails-omakase", require: false
end

group :development do
  gem "web-console"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
end

gem "dotenv-rails", "~> 3.2"

gem "tzinfo-data", "~> 1.2025"
