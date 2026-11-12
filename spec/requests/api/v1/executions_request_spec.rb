# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Executions", type: :request do
  let(:publisher) { instance_double(Messaging::RabbitmqPublisher, publish: nil) }
  let(:repository) { Persistence::Executions::MongoExecutionRepository.new }

  before do
    allow(Messaging::RabbitmqPublisher).to receive(:new).and_return(publisher)
    repository.save(
      Executions::Execution.new(id: 42, protocol: "ABC12345", queued_at: Time.now.utc,
                                items: [ Executions::Item.new(line_item_id: 1, name: "Oil change") ])
    )
  end

  it "lists the queue, optionally filtered by status" do
    get "/api/v1/executions", headers: auth_headers, as: :json
    expect(response.parsed_body.pluck("work_order_id")).to eq([ 42 ])

    get "/api/v1/executions?status=completed", headers: auth_headers, as: :json
    expect(response.parsed_body).to eq([])
  end

  it "shows one execution" do
    get "/api/v1/executions/42", headers: auth_headers, as: :json

    expect(response.parsed_body).to include("status" => "queued", "protocol" => "ABC12345")
    expect(response.parsed_body["items"].first).to include("line_item_id" => 1, "name" => "Oil change")
  end

  it "returns 404 for an unknown execution" do
    get "/api/v1/executions/999", headers: auth_headers, as: :json
    expect(response).to have_http_status(:not_found)

    patch "/api/v1/executions/999/start", headers: auth_headers, as: :json
    expect(response).to have_http_status(:not_found)
  end

  it "requires a staff token" do
    get "/api/v1/executions", as: :json
    expect(response).to have_http_status(:unauthorized)

    get "/api/v1/executions", headers: customer_auth_headers, as: :json
    expect(response).to have_http_status(:forbidden)
  end

  it "runs the whole execution and publishes the saga events" do
    patch "/api/v1/executions/42/start", headers: auth_headers, as: :json
    patch "/api/v1/executions/42/items/1/start", headers: auth_headers, as: :json
    patch "/api/v1/executions/42/items/1/finish", headers: auth_headers, as: :json
    patch "/api/v1/executions/42/complete", headers: auth_headers, as: :json

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body["status"]).to eq("completed")
    expect(publisher).to have_received(:publish).with("execution.started", { work_order_id: 42 })
    expect(publisher).to have_received(:publish).with("execution.completed", hash_including(work_order_id: 42))
  end

  it "returns 422 on an invalid transition" do
    patch "/api/v1/executions/42/complete", headers: auth_headers, as: :json

    expect(response).to have_http_status(:unprocessable_content)
  end
end
