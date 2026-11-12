# frozen_string_literal: true

require_relative "../shared/entity"
require_relative "item"

module Executions
  # Execução de uma OS aprovada. O id é o próprio work_order_id: uma execução por OS.
  class Execution < Shared::Entity
    STATUSES = %i[queued in_progress completed].freeze

    class InvalidTransition < StandardError; end

    attr_reader :protocol, :status, :items, :queued_at, :started_at, :completed_at

    def initialize(id:, protocol:, items:, status: :queued, queued_at: nil, started_at: nil, completed_at: nil)
      super(id: id)
      raise ArgumentError, "Invalid status: #{status}" unless STATUSES.include?(status.to_sym)
      raise ArgumentError, "Execution needs at least one service" if items.empty?

      @protocol = protocol
      @items = items
      @status = status.to_sym
      @queued_at = queued_at
      @started_at = started_at
      @completed_at = completed_at
    end

    alias work_order_id id

    STATUSES.each do |state|
      define_method("#{state}?") { status == state }
    end

    def start(now)
      raise InvalidTransition, "Execution already started" unless queued?

      @status = :in_progress
      @started_at = now
    end

    def start_item(line_item_id, now)
      in_progress_item(line_item_id).start(now)
    end

    def finish_item(line_item_id, now)
      in_progress_item(line_item_id).finish(now)
    end

    def complete(now)
      raise InvalidTransition, "Execution is not in progress" unless in_progress?
      raise InvalidTransition, "All services must be finished" unless items.all?(&:finished?)

      @status = :completed
      @completed_at = now
    end

    def duration_minutes
      return nil unless started_at && completed_at

      ((completed_at - started_at) / 60.0).round(2)
    end

    private

    def in_progress_item(line_item_id)
      raise InvalidTransition, "Execution is not in progress" unless in_progress?

      items.find { |item| item.line_item_id == line_item_id.to_i } ||
        raise(InvalidTransition, "Service not found in this execution")
    end
  end
end
