# frozen_string_literal: true

module Persistence
  module Executions
    class MongoExecutionRepository
      include ::Executions::ExecutionRepository

      def find(id)
        document = ExecutionDocument.where(_id: id.to_i).first
        document && to_entity(document)
      end

      def save(execution)
        ExecutionDocument.new(to_attributes(execution)).upsert
        execution
      end

      def all
        queue
      end

      def queue(status: nil)
        scope = status ? ExecutionDocument.where(status: status.to_s) : ExecutionDocument.all
        scope.order_by(queued_at: :asc).map { |document| to_entity(document) }
      end

      def delete(id)
        ExecutionDocument.where(_id: id.to_i).delete
      end

      private

      def to_entity(document)
        ::Executions::Execution.new(
          id: document.id,
          protocol: document.protocol,
          status: document.status,
          items: document.items.map { |item| ::Executions::Item.new(**item.symbolize_keys) },
          queued_at: document.queued_at,
          started_at: document.started_at,
          completed_at: document.completed_at,
          failure_reason: document.failure_reason
        )
      end

      def to_attributes(execution)
        {
          _id: execution.id,
          protocol: execution.protocol,
          status: execution.status.to_s,
          items: execution.items.map { |item| item_attributes(item) },
          queued_at: execution.queued_at,
          started_at: execution.started_at,
          completed_at: execution.completed_at,
          failure_reason: execution.failure_reason
        }
      end

      def item_attributes(item)
        { line_item_id: item.line_item_id, name: item.name,
          started_at: item.started_at, finished_at: item.finished_at }
      end
    end
  end
end
