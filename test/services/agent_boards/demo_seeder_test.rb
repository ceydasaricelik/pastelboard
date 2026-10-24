require "test_helper"

class AgentBoards::DemoSeederTest < ActiveSupport::TestCase
  test "builds the demo board: fixed lists, two workers, a mentor and four cards in the pool" do
    board = AgentBoards::DemoSeeder.call

    assert board.agent?
    assert_equal List::AGENT_STATE_LISTS.values, board.lists.map(&:name)
    assert_equal [ AgentBoards::Models.worker ] * 2, board.members.worker.map(&:model)
    assert_equal [ AgentBoards::Models.mentor ], board.members.mentor.map(&:model)

    cards = board.agent_list(:open).cards
    assert_equal 4, cards.size
    assert cards.all?(&:agent_open?)
    assert cards.all? { |card| card.checklist_items.size >= 3 }
    assert_includes cards.map(&:title), AgentBoards::DemoSeeder::MISSING_INFO_TITLE
  end

  test "the missing-information card has no product in its description and forbids invention" do
    board = AgentBoards::DemoSeeder.call
    card = board.agent_list(:open).cards.find_by!(title: AgentBoards::DemoSeeder::MISSING_INFO_TITLE)

    assert_not_includes card.description, "Ürün:"
    assert_not_includes card.description, "Özellikler:"
    assert_not_includes card.description, "TL"
    assert_includes card.checklist_items.map(&:content), "Ürün adı ve özellikleri karttaki bilgiye dayanmalı, uydurma bilgi olmamalı"
  end

  test "two cards carry facts and criteria that are easy to miss but countable" do
    board = AgentBoards::DemoSeeder.call
    cards = board.agent_list(:open).cards.where(title: [ "Kablosuz kulaklık açıklaması", "Termos şişe açıklaması" ])

    assert_equal 2, cards.size
    cards.each do |card|
      assert_includes card.description, "Ürün:"
      assert card.checklist_items.any? { |item| item.content.start_with?("Tam olarak") }, "#{card.title} has no exact-count criterion"
    end
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
