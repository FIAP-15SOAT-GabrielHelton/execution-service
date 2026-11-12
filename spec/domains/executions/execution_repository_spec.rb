# frozen_string_literal: true

require "rails_helper"

RSpec.describe Executions::ExecutionRepository do
  it "requires implementers to define #queue" do
    expect { Class.new { include Executions::ExecutionRepository }.new.queue }.to raise_error(NotImplementedError)
  end
end
