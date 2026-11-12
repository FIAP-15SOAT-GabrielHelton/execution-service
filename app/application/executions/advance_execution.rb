# frozen_string_literal: true

require_relative "../shared/result"
require_relative "../shared/use_case"

module Executions
  # Aplica uma ação do mecânico à execução e publica o evento da Saga correspondente.
  class AdvanceExecution < Shared::UseCase
    EVENTS = { start: "execution.started", complete: "execution.completed", fail_with: "execution.failed" }.freeze

    def initialize(execution_repository:, publisher:, clock: Time.method(:now))
      @repository = execution_repository
      @publisher = publisher
      @clock = clock
    end

    private

    def perform(work_order_id:, action:, line_item_id: nil, reason: nil)
      execution = @repository.find(work_order_id)
      return Shared::Result.failure("Execution not found") unless execution

      extra = { start_item: [ line_item_id ], finish_item: [ line_item_id ], fail_with: [ reason ] }.fetch(action, [])
      execution.public_send(action, *extra, @clock.call)

      # Publica antes de gravar: se o broker falhar, nada muda e o mecânico pode
      # tentar de novo, em vez de a OS nunca ficar sabendo da mudança.
      publish(action, execution)
      Shared::Result.success(@repository.save(execution))
    end

    def publish(action, execution)
      event = EVENTS[action]
      return unless event

      @publisher.publish(event, payload(action, execution))
    end

    def payload(action, execution)
      return { work_order_id: execution.work_order_id, reason: execution.failure_reason } if action == :fail_with
      return { work_order_id: execution.work_order_id } unless action == :complete

      # O OS Service grava estes horários para o histórico e as métricas da OS.
      { work_order_id: execution.work_order_id,
        duration_minutes: execution.duration_minutes,
        items: execution.items.map do |item|
          { line_item_id: item.line_item_id, started_at: item.started_at.iso8601, finished_at: item.finished_at.iso8601 }
        end }
    end
  end
end
