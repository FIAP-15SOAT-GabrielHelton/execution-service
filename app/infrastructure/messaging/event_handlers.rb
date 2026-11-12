# frozen_string_literal: true

module Messaging
  # Eventos da Saga (RFC-005) que este serviço consome.
  module EventHandlers
    QUEUE = "execution-service"

    def self.build(execution_repository: Persistence::Executions::MongoExecutionRepository.new)
      {
        "work_order.approved" => lambda do |data|
          result = Executions::CreateExecution.new(execution_repository: execution_repository).call(
            work_order_id: data.fetch("work_order_id"),
            protocol: data.fetch("protocol"),
            line_items: data.fetch("line_items")
          )
          raise result.error if result.failure?
        end
      }
    end
  end
end
