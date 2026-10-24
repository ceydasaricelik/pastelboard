require "test_helper"

class AgentBoards::DemoSeederTest < ActiveSupport::TestCase
  test "builds the demo board: fixed lists, two workers, a mentor and four cards in the pool" do
    board = AgentBoards::DemoSeeder.call

    assert board.agent?
    assert_equal List::AGENT_STATE_LISTS.values, board.lists.map(&:name)
    assert_equal [ "llama-3.1-8b-instant" ] * 2, board.members.worker.map(&:model)
    assert_equal [ "openai/gpt-oss-120b" ], board.members.mentor.map(&:model)

    cards = board.agent_list(:open).cards
    assert_equal 4, cards.size
    assert cards.all?(&:agent_open?)
    assert cards.all? { |card| card.checklist_items.size == 3 }
    assert_includes cards.map(&:title), AgentBoards::DemoSeeder::MISSING_INFO_TITLE
  end

  test "running it again resets the same board" do
    AgentBoards::DemoSeeder.call
    board = AgentBoards::DemoSeeder.call
    AgentBoards::Tick.new(board, llm: FakeLlm.new).call

    assert_no_difference -> { Board.where(name: AgentBoards::DemoSeeder::BOARD_NAME).count } do
      board = AgentBoards::DemoSeeder.call
    end

    assert_equal 4, board.agent_list(:open).cards.size
    assert_equal 3, board.members.size
    assert_equal 4, AgentEvent.count
  end
end
