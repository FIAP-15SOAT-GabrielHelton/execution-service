# frozen_string_literal: true

require "rails_helper"

RSpec.describe Persistence::Executions::MongoExecutionRepository do
  let(:repository) { described_class.new }
  let(:now) { Time.utc(2026, 11, 12, 10, 0, 0) }

  def build(id:, queued_at: now, status: :queued)
    Executions::Execution.new(id: id, protocol: "P#{id}", status: status, queued_at: queued_at,
                              items: [ Executions::Item.new(line_item_id: 1, name: "Oil change") ])
  end

  it "round-trips an execution with its items" do
    execution = build(id: 42)
    execution.start(now)
    execution.start_item(1, now + 60)
    repository.save(execution)

    found = repository.find(42)

    expect(found).to have_attributes(work_order_id: 42, protocol: "P42", status: :in_progress, started_at: now)
    expect(found.items.first).to have_attributes(line_item_id: 1, name: "Oil change", started_at: now + 60)
  end

  it "updates the same document on a second save" do
    repository.save(build(id: 42))
    repository.save(build(id: 42, status: :in_progress))

    expect(Persistence::Executions::ExecutionDocument.count).to eq(1)
    expect(repository.find(42)).to be_in_progress
  end

  it "returns nil when not found" do
    expect(repository.find(999)).to be_nil
  end

  it "lists the queue oldest first, optionally by status" do
    repository.save(build(id: 2, queued_at: now + 60))
    repository.save(build(id: 1, queued_at: now))
    repository.save(build(id: 3, queued_at: now + 120, status: :in_progress))

    expect(repository.all.map(&:id)).to eq([ 1, 2, 3 ])
    expect(repository.queue(status: :queued).map(&:id)).to eq([ 1, 2 ])
  end

  it "deletes an execution" do
    repository.save(build(id: 42))
    repository.delete(42)

    expect(repository.find(42)).to be_nil
  end
end
