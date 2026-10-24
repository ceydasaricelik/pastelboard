require "test_helper"

class EscalateOverdueCardsJobAgentBoardTest < ActiveJob::TestCase
  test "skips agent boards while still escalating overdue cards on human boards" do
    human_board = Board.create!(name: "İnsan panosu")
    human_card = human_board.lists.create!(name: "To Do", position: 1)
      .cards.create!(title: "Gecikmiş", due_date: 1.day.ago, position: 1)

    agent_board = create_agent_board
    agent_card = create_agent_card(agent_board)
    agent_card.update!(due_date: 1.day.ago)

    assert_equal 1, EscalateOverdueCardsJob.perform_now

    assert_predicate human_card.reload, :escalated?
    assert_predicate agent_card.reload, :normal?
    assert_equal List::POOL_NAME, agent_card.list.name
    assert_not agent_board.lists.exists?(name: List::OVERDUE_NAME)
  end

  test "human cards and boards have no agent state" do
    card = cards(:one)

    assert_predicate card.board, :human?
    assert_nil card.agent_state
    assert_empty card.agent_events
  end
end
