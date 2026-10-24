module AgentBoards
  # The Groq models the demo agents run on. Set GROQ_WORKER_MODEL / GROQ_MENTOR_MODEL to change them.
  module Models
    DEFAULT_WORKER = "openai/gpt-oss-20b"
    DEFAULT_MENTOR = "openai/gpt-oss-120b"

    module_function

    def worker(env: ENV)
      env["GROQ_WORKER_MODEL"].presence || DEFAULT_WORKER
    end

    def mentor(env: ENV)
      env["GROQ_MENTOR_MODEL"].presence || DEFAULT_MENTOR
    end
  end
end
