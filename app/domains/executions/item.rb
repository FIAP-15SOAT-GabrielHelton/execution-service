# frozen_string_literal: true

module Executions
  # Um serviço da OS a ser executado pelo mecânico.
  class Item
    attr_reader :line_item_id, :name, :started_at, :finished_at

    def initialize(line_item_id:, name:, started_at: nil, finished_at: nil)
      @line_item_id = line_item_id
      @name = name
      @started_at = started_at
      @finished_at = finished_at
    end

    def finished?
      !finished_at.nil?
    end

    def start(now)
      raise Execution::InvalidTransition, "Service already started" if started_at

      @started_at = now
    end

    def finish(now)
      raise Execution::InvalidTransition, "Service not started" unless started_at
      raise Execution::InvalidTransition, "Service already finished" if finished?

      @finished_at = now
    end
  end
end
