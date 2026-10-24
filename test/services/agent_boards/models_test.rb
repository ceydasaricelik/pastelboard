require "test_helper"

class AgentBoards::ModelsTest < ActiveSupport::TestCase
  test "defaults to the gpt-oss models" do
    assert_equal "openai/gpt-oss-20b", AgentBoards::Models.worker(env: {})
    assert_equal "openai/gpt-oss-120b", AgentBoards::Models.mentor(env: { "GROQ_MENTOR_MODEL" => "" })
  end

  test "reads the model names from ENV" do
    env = { "GROQ_WORKER_MODEL" => "worker-x", "GROQ_MENTOR_MODEL" => "mentor-y" }

    assert_equal "worker-x", AgentBoards::Models.worker(env: env)
    assert_equal "mentor-y", AgentBoards::Models.mentor(env: env)
  end

  test "the demo seeder fills the agents' model from ENV" do
    originals = %w[ GROQ_WORKER_MODEL GROQ_MENTOR_MODEL ].to_h { |key| [ key, ENV[key] ] }
    ENV["GROQ_WORKER_MODEL"] = "worker-x"
    ENV["GROQ_MENTOR_MODEL"] = "mentor-y"

    board = AgentBoards::DemoSeeder.call

    assert_equal [ "worker-x" ] * 2, board.members.worker.map(&:model)
    assert_equal [ "mentor-y" ], board.members.mentor.map(&:model)
  ensure
    originals.each { |key, value| ENV[key] = value }
  end
end
