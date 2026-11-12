# frozen_string_literal: true

module Executions
  module Presenters
    module Execution
      module_function

      def call(execution)
        {
          work_order_id: execution.work_order_id,
          protocol: execution.protocol,
          status: execution.status.to_s,
          queued_at: execution.queued_at,
          started_at: execution.started_at,
          completed_at: execution.completed_at,
          duration_minutes: execution.duration_minutes,
          items: execution.items.map do |item|
            { line_item_id: item.line_item_id, name: item.name,
              started_at: item.started_at, finished_at: item.finished_at }
          end
        }
      end
    end
  end
end
