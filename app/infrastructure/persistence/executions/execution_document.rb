# frozen_string_literal: true

module Persistence
  module Executions
    # Um documento por OS, com os serviços embutidos — lido e gravado sempre inteiro.
    class ExecutionDocument
      include Mongoid::Document

      store_in collection: "executions"

      field :_id, type: Integer # work_order_id
      field :protocol, type: String
      field :status, type: String
      field :items, type: Array, default: []
      field :queued_at, type: Time
      field :started_at, type: Time
      field :completed_at, type: Time
      field :failure_reason, type: String

      index({ status: 1, queued_at: 1 })
    end
  end
end
