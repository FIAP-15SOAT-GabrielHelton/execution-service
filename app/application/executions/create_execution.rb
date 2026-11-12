# frozen_string_literal: true

require_relative "../shared/result"
require_relative "../shared/use_case"

module Executions
  # Coloca a OS na fila ao receber o evento work_order.approved (RFC-005).
  class CreateExecution < Shared::UseCase
    def initialize(execution_repository:, clock: Time.method(:now))
      @repository = execution_repository
      @clock = clock
    end

    private

    def perform(work_order_id:, protocol:, line_items:)
      # Idempotência: o broker pode reentregar o mesmo evento.
      existing = @repository.find(work_order_id)
      return Shared::Result.success(existing) if existing

      services = line_items.select { |item| item.fetch("item_type") == "service" }
      execution = Execution.new(
        id: work_order_id,
        protocol: protocol,
        queued_at: @clock.call,
        items: services.map { |item| Item.new(line_item_id: item.fetch("id"), name: item.fetch("name")) }
      )

      Shared::Result.success(@repository.save(execution))
    end
  end
end
