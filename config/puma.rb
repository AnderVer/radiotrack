# Puma is a fast, concurrent web server for Ruby & Rack
# https://puma.io

# Set the number of worker processes to run.
max_threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }
min_threads_count = ENV.fetch("RAILS_MIN_THREADS") { 5 }
threads min_threads_count, max_threads_count

# Set the environment that the server will run in.
rails_env = ENV.fetch("RAILS_ENV") { "development" }

# Set the port that the server will bind to.
port ENV.fetch("PORT") { 3000 }

# Set the environment that the server will run in.
environment rails_env

# Prefetch the application before spawning workers.
preload_app!

# Set the number of workers to run.
workers ENV.fetch("WEB_CONCURRENCY") { 2 }

# Set the timeout for worker processes.
worker_timeout 30

# Use the PID file to manage the application.
pidfile ENV.fetch("PIDFILE") { "tmp/pids/server.pid" }

# Set the path for the state file.
state_path ENV.fetch("STATE_PATH") { "tmp/pids/puma.state" }

# Enable early hints for faster asset loading.
plugin :early_hints

# Use systemd socket activation if available.
# plugin :systemd
