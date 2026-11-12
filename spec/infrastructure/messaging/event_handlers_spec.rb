# frozen_string_literal: true

require "rails_helper"

RSpec.describe Messaging::EventHandlers do
  let(:handler) { described_class.build.fetch("work_order.approved") }
  let(:data) do
    { "work_order_id" => 42, "protocol" => "ABC12345",
      "line_items" => [ { "id" => 1, "item_type" => "service", "name" => "Oil change" } ] }
  end

  it "queues the execution for an approved work order" do
    handler.call(data)

    expect(Persistence::Executions::MongoExecutionRepository.new.find(42)).to be_queued
  end

  it "raises when the execution cannot be created so the message is not acked" do
    expect { handler.call(data.merge("line_items" => [])) }.to raise_error(RuntimeError)
  end
end
