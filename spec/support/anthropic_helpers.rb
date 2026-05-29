module AnthropicHelpers
  ANTHROPIC_MESSAGES_URL = "https://api.anthropic.com/v1/messages"

  def stub_anthropic_response(content:, model: "claude-haiku-4-5-20251001", input_tokens: 100, output_tokens: 50)
    stub_request(:post, ANTHROPIC_MESSAGES_URL)
      .to_return(
        status: 200,
        body: {
          id: "msg_test_#{SecureRandom.hex(8)}",
          type: "message",
          role: "assistant",
          model: model,
          content: [{ type: "text", text: content }],
          stop_reason: "end_turn",
          usage: { input_tokens: input_tokens, output_tokens: output_tokens }
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  def stub_anthropic_tool_use(tool_name:, tool_input:, model: "claude-sonnet-4-6")
    stub_request(:post, ANTHROPIC_MESSAGES_URL)
      .to_return(
        status: 200,
        body: {
          id: "msg_test_#{SecureRandom.hex(8)}",
          type: "message",
          role: "assistant",
          model: model,
          content: [{
            type: "tool_use",
            id: "toolu_#{SecureRandom.hex(8)}",
            name: tool_name,
            input: tool_input
          }],
          stop_reason: "tool_use",
          usage: { input_tokens: 150, output_tokens: 80 }
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  def stub_anthropic_error(status: 529, message: "Overloaded")
    stub_request(:post, ANTHROPIC_MESSAGES_URL)
      .to_return(
        status: status,
        body: { type: "error", error: { type: "overloaded_error", message: message } }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end
end

RSpec.configure do |config|
  config.include AnthropicHelpers
end
