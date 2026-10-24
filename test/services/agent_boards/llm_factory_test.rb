require "test_helper"

class AgentBoards::LlmFactoryTest < ActiveSupport::TestCase
  test "uses the fake model without a key" do
    assert_instance_of FakeLlm, AgentBoards::LlmFactory.build(env: {})
    assert_instance_of FakeLlm, AgentBoards::LlmFactory.build(env: { "GROQ_API_KEY" => "" })
  end

  test "uses Groq when a key is set" do
    assert_instance_of GroqLlm, AgentBoards::LlmFactory.build(env: { "GROQ_API_KEY" => "test-key" })
  end

  test "GroqLlm reads its key from ENV by default" do
    original = ENV["GROQ_API_KEY"]
    ENV["GROQ_API_KEY"] = "test-key"
    assert_instance_of GroqLlm, GroqLlm.new
  ensure
    ENV["GROQ_API_KEY"] = original
  end
end
