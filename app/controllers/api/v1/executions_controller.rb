# frozen_string_literal: true

module Api
  module V1
    # Fila e andamento da execução — só funcionários (o token do cliente é recusado).
    class ExecutionsController < Api::V1::ApplicationController
      ACTIONS = { "start" => :start, "complete" => :complete,
                  "start_item" => :start_item, "finish_item" => :finish_item }.freeze

      before_action :require_staff!

      def index
        executions = repository.queue(status: params[:status].presence)

        render json: executions.map { |execution| Executions::Presenters::Execution.call(execution) }
      end

      def show
        execution = repository.find(params[:work_order_id])
        return render(json: { error: "Execution not found" }, status: :not_found) unless execution

        render json: Executions::Presenters::Execution.call(execution)
      end

      def advance
        result = advance_execution.call(
          work_order_id: params[:work_order_id], action: ACTIONS.fetch(action_name), line_item_id: params[:line_item_id]
        )

        if result.success?
          render json: Executions::Presenters::Execution.call(result.value)
        else
          status = result.error == "Execution not found" ? :not_found : :unprocessable_content
          render json: { error: result.error }, status: status
        end
      end

      ACTIONS.each_key { |name| alias_method name, :advance }

      private

      def repository
        @repository ||= Persistence::Executions::MongoExecutionRepository.new
      end

      def advance_execution
        Executions::AdvanceExecution.new(execution_repository: repository, publisher: Messaging::RabbitmqPublisher.new)
      end
    end
  end
end
