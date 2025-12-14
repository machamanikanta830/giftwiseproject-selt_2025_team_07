require "rails_helper"

RSpec.describe Ai::GeminiClient do
  let(:api_key) { "test_key" }
  let(:client) { described_class.new(api_key: api_key) }

  describe "initialize" do
    it "does not raise when api key is missing (error occurs on request)" do
      expect { described_class.new(api_key: nil) }.not_to raise_error
    end
  end


  describe "generate_gift_ideas" do
    let(:http) { instance_double(Net::HTTP) }
    let(:response) { instance_double(Net::HTTPSuccess) }

    before do
      allow(Net::HTTP).to receive(:new).and_return(http)
      allow(http).to receive(:use_ssl=)
      allow(http).to receive(:read_timeout=)
      allow(http).to receive(:verify_mode=)
    end

    it "returns parsed gift ideas on success" do
      body = {
        "candidates" => [
          {
            "content" => {
              "parts" => [
                {
                  "text" => {
                    "gift_ideas" => [
                      { "title" => "Mug", "description" => "Nice mug" }
                    ]
                  }.to_json
                }
              ]
            }
          }
        ]
      }.to_json

      allow(http).to receive(:request).and_return(response)
      allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
      allow(response).to receive(:body).and_return(body)

      ideas = client.generate_gift_ideas("test prompt")

      expect(ideas).to be_an(Array)
      expect(ideas.first["title"]).to eq("Mug")
    end

    it "raises error on HTTP failure" do
      bad_response = instance_double(Net::HTTPBadRequest, body: "bad", code: "400")

      allow(http).to receive(:request).and_return(bad_response)
      allow(bad_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(false)

      expect {
        client.generate_gift_ideas("test")
      }.to raise_error(Ai::GeminiClient::Error, /Gemini HTTP error/)
    end

    it "raises error when JSON is invalid" do
      body = "not json"

      allow(http).to receive(:request).and_return(response)
      allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
      allow(response).to receive(:body).and_return(body)

      expect {
        client.generate_gift_ideas("test")
      }.to raise_error(Ai::GeminiClient::Error, /Failed to parse Gemini JSON/)
    end

    it "raises error when candidates are missing" do
      body = { "foo" => "bar" }.to_json

      allow(http).to receive(:request).and_return(response)
      allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
      allow(response).to receive(:body).and_return(body)

      expect {
        client.generate_gift_ideas("test")
      }.to raise_error(Ai::GeminiClient::Error, /no candidates/)
    end
  end
end
