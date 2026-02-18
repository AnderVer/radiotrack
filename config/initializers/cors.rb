# Be sure to restart your server when you modify this file.

# Configure CORS for API access from different origins
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins '*'

    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: true,
      max_age: 12.hours
  end
end
