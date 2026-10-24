module AgentBoards
  # GroqLlm when a key is set, otherwise the simulation.
  module LlmFactory
    module_function

    def build(env: ENV)
      key = env["GROQ_API_KEY"].presence
      key ? GroqLlm.new(api_key: key) : FakeLlm.new
    end
  end
end
