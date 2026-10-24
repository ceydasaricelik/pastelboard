require "test_helper"

class AgentBoards::DemoRunTest < ActiveSupport::TestCase
  test "resets the demo board, runs one round and prints title, state and last event of every card" do
    out = StringIO.new

    AgentBoards::DemoRun.call(llm: FakeLlm.new, out: out)

    text = out.string
    assert_includes text, "Mod: simülasyon"
    assert_includes text, "Tur bitti: 2 kart ilerledi."
    AgentBoards::DemoSeeder::TASKS.each { |task| assert_includes text, task[:title] }
    assert_includes text, "[in_review]"
    assert_includes text, "[open]"
    assert_includes text, "son olay: Ece çıktıyı teslim etti (deneme 1). (simülasyon modu)"
  end

  test "a second round continues on the same board" do
    AgentBoards::DemoRun.call(llm: FakeLlm.new, out: StringIO.new)
    out = StringIO.new

    AgentBoards::DemoRun.tick(llm: FakeLlm.new, out: out)

    assert_equal 1, Board.where(name: AgentBoards::DemoSeeder::BOARD_NAME).count
    assert_includes out.string, "düzeltme istedi"
  end

  test "says so when the real model is used" do
    out = StringIO.new
    llm = FakeLlm.new
    llm.define_singleton_method(:simulated?) { false }

    AgentBoards::DemoRun.call(llm: llm, out: out)

    assert_includes out.string, "Mod: Groq (gerçek LLM)"
  end
end
