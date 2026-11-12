# frozen_string_literal: true

require_relative "../shared/repository"

module Executions
  module ExecutionRepository
    include Shared::Repository

    # Fila de execução: mais antigas primeiro, opcionalmente filtradas por status.
    def queue(status: nil)
      raise NotImplementedError, "#{self.class}#queue not implemented"
    end
  end
end
