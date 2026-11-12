# frozen_string_literal: true

require "rails_helper"

RSpec.describe Executions::Execution do
  let(:now) { Time.utc(2026, 11, 12, 10, 0, 0) }
  let(:items) do
    [ Executions::Item.new(line_item_id: 1, name: "Oil change"), Executions::Item.new(line_item_id: 2, name: "Brakes") ]
  end
  let(:execution) { described_class.new(id: 42, protocol: "ABC12345", items: items, queued_at: now) }

  def finish_all(at)
    items.each do |item|
      execution.start_item(item.line_item_id, at)
      execution.finish_item(item.line_item_id, at)
    end
  end

  it "starts queued, identified by the work order" do
    expect(execution).to be_queued
    expect(execution.work_order_id).to eq(42)
  end

  it "rejects an unknown status or an execution without services" do
    expect { described_class.new(id: 1, protocol: "x", items: items, status: :nope) }.to raise_error(ArgumentError)
    expect { described_class.new(id: 1, protocol: "x", items: []) }.to raise_error(ArgumentError, /at least one/)
  end

  it "goes through start, item work and completion, measuring the duration" do
    execution.start(now)
    finish_all(now + 600)
    execution.complete(now + 1800)

    expect(execution).to be_completed
    expect(execution.duration_minutes).to eq(30.0)
  end

  it "has no duration before completion" do
    expect(execution.duration_minutes).to be_nil
  end

  it "does not start twice" do
    execution.start(now)

    expect { execution.start(now) }.to raise_error(described_class::InvalidTransition, /already started/)
  end

  it "does not work on items before the execution starts" do
    expect { execution.start_item(1, now) }.to raise_error(described_class::InvalidTransition, /not in progress/)
  end

  it "rejects an item that is not part of the execution" do
    execution.start(now)

    expect { execution.start_item(99, now) }.to raise_error(described_class::InvalidTransition, /not found/)
  end

  it "enforces the item order: start once, then finish once" do
    execution.start(now)

    expect { execution.finish_item(1, now) }.to raise_error(described_class::InvalidTransition, /not started/)
    execution.start_item(1, now)
    expect { execution.start_item(1, now) }.to raise_error(described_class::InvalidTransition, /already started/)
    execution.finish_item(1, now)
    expect { execution.finish_item(1, now) }.to raise_error(described_class::InvalidTransition, /already finished/)
  end

  it "does not complete with unfinished services or before starting" do
    expect { execution.complete(now) }.to raise_error(described_class::InvalidTransition, /not in progress/)
    execution.start(now)
    expect { execution.complete(now) }.to raise_error(described_class::InvalidTransition, /must be finished/)
  end
end
