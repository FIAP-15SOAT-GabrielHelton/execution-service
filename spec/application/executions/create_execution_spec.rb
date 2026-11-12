# frozen_string_literal: true

require "rails_helper"

RSpec.describe Executions::CreateExecution do
  let(:repository) { Persistence::Executions::MongoExecutionRepository.new }
  let(:use_case) { described_class.new(execution_repository: repository) }
  let(:line_items) do
    [ { "id" => 1, "item_type" => "service", "name" => "Oil change" },
      { "id" => 2, "item_type" => "part", "name" => "Oil filter" } ]
  end

  it "queues the work order with only its services" do
    result = use_case.call(work_order_id: 42, protocol: "ABC12345", line_items: line_items)

    expect(result.value).to be_queued
    expect(repository.find(42).items.map(&:name)).to eq([ "Oil change" ])
  end

  it "is idempotent when the same event is delivered twice" do
    use_case.call(work_order_id: 42, protocol: "ABC12345", line_items: line_items)
    execution = repository.find(42)
    execution.start(Time.now.utc)
    repository.save(execution)

    result = use_case.call(work_order_id: 42, protocol: "ABC12345", line_items: line_items)

    expect(result.value).to be_in_progress
  end

  it "fails when the work order has no services" do
    result = use_case.call(work_order_id: 42, protocol: "ABC12345", line_items: [ line_items.last ])

    expect(result.error).to match(/at least one service/)
  end
end
