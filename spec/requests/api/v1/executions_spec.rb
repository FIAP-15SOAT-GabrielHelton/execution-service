# frozen_string_literal: true

require 'swagger_helper'

# Descrição OpenAPI das rotas (gera swagger/v1/swagger.json). O comportamento é testado em
# executions_request_spec.rb; este arquivo só roda na geração do Swagger.
RSpec.describe 'Api::V1::Executions', openapi_spec: 'v1/swagger.json', type: :request do
  # Respostas comuns às ações que avançam a execução.
  def self.advance_responses
    response '200', 'successful' do
      schema '$ref' => '#/components/schemas/Execution'
      run_test!
    end

    response '401', 'unauthorized' do
      run_test!
    end

    response '404', 'execution not found' do
      schema '$ref' => '#/components/schemas/Error'
      run_test!
    end

    response '422', 'invalid transition for the current status' do
      schema '$ref' => '#/components/schemas/Error'
      run_test!
    end
  end

  path '/api/v1/executions' do
    get 'Execution queue, oldest first' do
      tags 'Executions'
      produces 'application/json'
      security [ { bearerAuth: [] } ]
      parameter name: :status, in: :query, required: false,
                schema: { type: :string, enum: %w[queued in_progress completed failed] }

      response '200', 'successful' do
        schema type: :array, items: { '$ref' => '#/components/schemas/Execution' }
        run_test!
      end

      response '401', 'unauthorized' do
        run_test!
      end
    end
  end

  path '/api/v1/executions/{work_order_id}' do
    get 'Get the execution of a work order' do
      tags 'Executions'
      produces 'application/json'
      security [ { bearerAuth: [] } ]
      parameter name: :work_order_id, in: :path, type: :integer, required: true

      response '200', 'successful' do
        schema '$ref' => '#/components/schemas/Execution'
        run_test!
      end

      response '401', 'unauthorized' do
        run_test!
      end

      response '404', 'execution not found' do
        schema '$ref' => '#/components/schemas/Error'
        run_test!
      end
    end
  end

  path '/api/v1/executions/{work_order_id}/start' do
    patch 'Start the execution (publishes execution.started)' do
      tags 'Executions'
      produces 'application/json'
      security [ { bearerAuth: [] } ]
      parameter name: :work_order_id, in: :path, type: :integer, required: true
      advance_responses
    end
  end

  path '/api/v1/executions/{work_order_id}/items/{line_item_id}/start' do
    patch 'Start a service item' do
      tags 'Executions'
      produces 'application/json'
      security [ { bearerAuth: [] } ]
      parameter name: :work_order_id, in: :path, type: :integer, required: true
      parameter name: :line_item_id, in: :path, type: :integer, required: true
      advance_responses
    end
  end

  path '/api/v1/executions/{work_order_id}/items/{line_item_id}/finish' do
    patch 'Finish a service item' do
      tags 'Executions'
      produces 'application/json'
      security [ { bearerAuth: [] } ]
      parameter name: :work_order_id, in: :path, type: :integer, required: true
      parameter name: :line_item_id, in: :path, type: :integer, required: true
      advance_responses
    end
  end

  path '/api/v1/executions/{work_order_id}/complete' do
    patch 'Complete the execution — all services must be finished (publishes execution.completed)' do
      tags 'Executions'
      produces 'application/json'
      security [ { bearerAuth: [] } ]
      parameter name: :work_order_id, in: :path, type: :integer, required: true
      advance_responses
    end
  end

  path '/api/v1/executions/{work_order_id}/fail' do
    patch 'Mark the execution as failed (publishes execution.failed, triggering the Saga compensation)' do
      tags 'Executions'
      consumes 'application/json'
      produces 'application/json'
      security [ { bearerAuth: [] } ]
      parameter name: :work_order_id, in: :path, type: :integer, required: true
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: { reason: { type: :string, example: 'Peça com defeito' } },
        required: %w[reason]
      }
      advance_responses
    end
  end
end
