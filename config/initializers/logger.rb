# Be sure to restart your server when you modify this file.

# Configure sensitive parameters which will be filtered from the log file.
Rails.application.config.filter_parameters += [
  :passw, :secret, :token, :_key, :crypt, :salt, :certificate, :otp, :ssn,
  :access_token, :refresh_token, :init_data
]

# Set log level
Rails.application.config.log_level = :debug if Rails.env.development?

# Log formatting
Rails.application.config.log_formatter = proc do |severity, datetime, progname, msg|
  "[#{datetime.strftime("%Y-%m-%d %H:%M:%S")}] [#{progname}] #{severity} -- #{msg}\n"
end
