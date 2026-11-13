require 'rails_helper'

RSpec.configure do |config|
  # During swagger generation the rake task sets SWAGGER_GENERATION=1, which lifts
  # the openapi_spec exclusion set in rails_helper so rswag can discover all specs.
  # Without this guard the filter would be removed on every normal rspec run too,
  # causing rswag specs to leak into the test suite and fail.
  config.exclusion_filter.delete(:openapi_spec) if ENV["SWAGGER_GENERATION"] == "1"
  # Specify a root folder where Swagger JSON files are generated
  # NOTE: If you're using the rswag-api to serve API descriptions, you'll need
  # to ensure that it's configured to serve Swagger from the same folder
  config.openapi_root = Rails.root.join('swagger').to_s

  # Define one or more Swagger documents and provide global metadata for each one
  # When you run the 'rswag:specs:swaggerize' rake task, the complete Swagger will
  # be generated at the provided relative path under openapi_root
  # By default, the operations defined in spec files are added to the first
  # document below. You can override this behavior by adding an openapi_spec tag to the
  # the root example_group in your specs, e.g. describe '...', openapi_spec: 'v2/swagger.json'
  config.openapi_specs = {
    'v1/swagger.json' => {
      openapi: '3.0.1',
      info: {
        title: 'Execution Service API',
        version: 'v1'
      },
      paths: {},
      components: {
        schemas: {
          Execution: {
            type: :object,
            properties: {
              work_order_id: { type: :integer },
              protocol: { type: :string },
              status: { type: :string, enum: %w[queued in_progress completed failed] },
              queued_at: { type: :string, format: :date_time },
              started_at: { type: :string, format: :date_time, nullable: true },
              completed_at: { type: :string, format: :date_time, nullable: true },
              duration_minutes: { type: :integer, nullable: true },
              failure_reason: { type: :string, nullable: true },
              items: {
                type: :array,
                items: {
                  type: :object,
                  properties: {
                    line_item_id: { type: :integer },
                    name: { type: :string },
                    started_at: { type: :string, format: :date_time, nullable: true },
                    finished_at: { type: :string, format: :date_time, nullable: true }
                  }
                }
              }
            },
            required: %w[work_order_id status items]
          },
          Error: {
            type: :object,
            properties: {
              error: { type: :string }
            },
            required: %w[error]
          }
        },
        securitySchemes: {
          bearerAuth: {
            type: :http,
            scheme: :bearer
          }
        }
      },
      security: [ { bearerAuth: [] } ]
    }
  }

  # Specify the format of the output Swagger file when running 'rswag:specs:swaggerize'.
  # The openapi_specs configuration option has the filename including format in
  # the key, this may want to be changed to avoid putting json at the end of the file
  # by changing the following set
  config.openapi_format = :json
end
