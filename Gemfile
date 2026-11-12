source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.1.3"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"

# Banco NoSQL deste serviço (RFC-005)
gem "mongoid", "~> 9.0"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
# gem "jbuilder"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]

# JSON Web Token authentication
gem "jwt", "~> 3.3"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin Ajax possible
# gem "rack-cors"

# Required for Ruby 4.0+ compatibility (used by rswag-ui)
gem "ostruct"

# API documentation engines — served in all environments so /api-docs is available in production
gem "rswag-api"
gem "rswag-ui"

# APM (latência, throughput, erros, distributed tracing) — ver config/newrelic.yml
gem "newrelic_rpm"

# Mensageria entre microsserviços (RabbitMQ) — RFC-005
gem "bunny"

# Estrutura os logs de requisição como uma linha JSON por request (latência, status,
# controller/action, request_id) — ver config/initializers/lograge.rb
gem "lograge"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Audits gems for known security defects (use config/bundler-audit.yml to ignore issues)
  gem "bundler-audit", require: false

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false
  gem "rubocop-rspec", require: false

  # Generates swagger.json from request specs — test-only tooling
  gem "rswag-specs"

  # Testing framework and helpers
  gem "rspec-rails", "~> 8.0"
  gem "faker"
end

group :test do
  gem "simplecov", require: false
end
