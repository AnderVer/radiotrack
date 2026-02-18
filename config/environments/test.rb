# frozen_string_literal: true

# The test environment is used for running tests.
Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = ENV["CI"].present?
  config.public_file_server.enabled = true
  config.public_file_server.headers = {
    "Cache-Control" => "public, max-age=3600"
  }

  # Show full error reports.
  config.consider_all_requests_local = true
  config.cache_store = :null_store
  config.action_controller.perform_caching = false
  config.action_controller.enable_fragment_cache_logging = false

  # Disable caching for Action Mailer templates.
  config.action_mailer.perform_caching = false

  # Tell Action Mailer not to deliver emails to the real world.
  config.action_mailer.delivery_method = :test

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  config.active_record.schema_format = :sql

  # Print deprecation notices to the stderr.
  config.active_support.deprecation = :stderr

  # Raise exceptions for disallowed deprecations.
  config.active_support.disallowed_deprecation = :raise

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = []

  # Raise error when a before_action's only/except options reference missing actions.
  config.action_controller.raise_on_missing_callback_keys = true
end
