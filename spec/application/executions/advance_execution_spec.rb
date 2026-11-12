# frozen_string_literal: true

require "rails_helper"

RSpec.describe Executions::AdvanceExecution do
  let(:repository) { Persistence::Executions::MongoExecutionRepository.new }
  let(:publisher) { double("publisher", publish: nil) } # rubocop:disable RSpec/VerifiedDoubles
  let(:now) { Time.utc(2026, 11, 12, 10, 0, 0) }
  let(:use_case) { described_class.new(execution_repository: repository, publisher: publisher, clock: -> { now }) }

  before do
    repository.save(
      Executions::Execution.new(id: 42, protocol: "ABC12345", queued_at: now,
                                items: [ Executions::Item.new(line_item_id: 1, name: "Oil change") ])
    )
  end

  it "starts the execution and publishes execution.started" do
    result = use_case.call(work_order_id: 42, action: :start)

    expect(result.value).to be_in_progress
    expect(repository.find(42)).to be_in_progress
    expect(publisher).to have_received(:publish).with("execution.started", { work_order_id: 42 })
  end

  it "works on items without publishing" do
    use_case.call(work_order_id: 42, action: :start)
    use_case.call(work_order_id: 42, action: :start_item, line_item_id: "1")
    use_case.call(work_order_id: 42, action: :finish_item, line_item_id: "1")

    expect(repository.find(42).items.first).to be_finished
    expect(publisher).to have_received(:publish).once
  end

  it "completes and publishes execution.completed with the duration" do
    %i[start start_item finish_item].each { |action| use_case.call(work_order_id: 42, action: action, line_item_id: (1 unless action == :start)) }

    result = use_case.call(work_order_id: 42, action: :complete)

    expect(result.value).to be_completed
    expect(publisher).to have_received(:publish).with(
      "execution.completed",
      { work_order_id: 42, duration_minutes: 0.0,
        items: [ { line_item_id: 1, started_at: "2026-11-12T10:00:00Z", finished_at: "2026-11-12T10:00:00Z" } ] }
    )
  end

  it "marks the execution as failed and publishes execution.failed with the reason" do
    result = use_case.call(work_order_id: 42, action: :fail_with, reason: "Elevador quebrado")

    expect(result.value).to be_failed
    expect(repository.find(42).failure_reason).to eq("Elevador quebrado")
    expect(publisher).to have_received(:publish).with("execution.failed", { work_order_id: 42, reason: "Elevador quebrado" })
  end

  it "fails for an unknown execution or an invalid transition" do
    expect(use_case.call(work_order_id: 999, action: :start).error).to eq("Execution not found")
    expect(use_case.call(work_order_id: 42, action: :complete).error).to match(/not in progress/)
  end

  it "does not save the change when publishing fails" do
    allow(publisher).to receive(:publish).and_raise(StandardError, "broker down")

    expect(use_case.call(work_order_id: 42, action: :start)).to be_failure
    expect(repository.find(42)).to be_queued
  end
end
