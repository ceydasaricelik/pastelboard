require "test_helper"

class AgentBoards::TickTest < ActiveSupport::TestCase
  PASS = { verdict: "pass", feedback: "Tamam." }.freeze
  REVISE = { verdict: "revise", feedback: "Kısalt.", lesson: "Kelime sayısını say." }.freeze

  def tick(board, **scenario)
    llm = FakeLlm.new(**scenario)
    AgentBoards::Tick.new(board, llm: llm).call
    llm
  end

  test "an open card is claimed atomically: only one of two workers gets it" do
    board = create_agent_board(workers: 2)
    card = create_agent_card(board)
    first, second = board.members.agent.worker.to_a

    assert AgentBoards::Tick.claim(card, first)
    assert_not AgentBoards::Tick.claim(card, second)
    assert_equal first, card.reload.assignee
  end

  test "two workers take two cards, one each, and every card is written once" do
    board = create_agent_board(workers: 2)
    cards = [ create_agent_card(board, title: "A"), create_agent_card(board, title: "B"), create_agent_card(board, title: "C") ]

    tick(board, writes: %w[ a b ])

    assert_equal [ "in_review", "in_review", "open" ], cards.map { |card| card.reload.agent_state }
    assert_equal 2, cards.first(2).map(&:assignee).uniq.size
    assert_nil cards.last.assignee
    assert_equal [ 1, 1, 0 ], cards.map(&:attempts)
    assert_equal List::REVIEW_NAME, cards.first.list.name
  end

  test "a round moves at most three cards" do
    board = create_agent_board(workers: 5)
    cards = Array.new(5) { |i| create_agent_card(board, title: "K#{i}") }

    AgentBoards::Tick.new(board, llm: FakeLlm.new(writes: %w[ a b c d e ])).call

    assert_equal 3, cards.count { |card| card.reload.agent_in_review? }
  end

  test "a passing review finishes the card and ticks its checklist" do
    board = create_agent_board
    card = create_agent_card(board)

    tick(board, writes: [ "metin" ])
    tick(board, reviews: [ PASS ])

    card.reload
    assert card.agent_done?
    assert card.completed?
    assert_equal List::DONE_NAME, card.list.name
    assert card.checklist_items.all?(&:done?)
    assert_equal %w[ written passed ], card.agent_events.pluck(:kind)
  end

  test "a revise verdict sends the card to rework with the feedback" do
    board = create_agent_board
    card = create_agent_card(board)

    tick(board, writes: [ "metin" ])
    tick(board, reviews: [ REVISE ])

    card.reload
    assert card.agent_rework?
    assert_equal List::REWORK_NAME, card.list.name
    assert_equal "Kısalt.", card.feedback
    assert_equal "revised", card.agent_events.last.kind
  end

  test "rework goes back to the same worker, who sees its own feedback and lessons" do
    board = create_agent_board(workers: 2)
    card = create_agent_card(board)

    tick(board, writes: [ "ilk" ])
    owner = card.reload.assignee
    tick(board, reviews: [ REVISE ])
    llm = tick(board, writes: [ "ikinci" ])

    assert_equal owner, card.reload.assignee
    assert card.agent_in_review?
    assert_equal 2, card.attempts
    prompt = llm.prompts.last
    assert_equal owner.id, prompt[:worker_id]
    assert_includes prompt[:prompt], "Kısalt."
    assert_includes prompt[:prompt], "- Kelime sayısını say."
  end

  test "a worker handles at most one card per round, rework before new cards" do
    board = create_agent_board(workers: 1)
    first = create_agent_card(board, title: "Birinci")
    tick(board, writes: [ "ilk" ])
    tick(board, reviews: [ REVISE ])
    second = create_agent_card(board, title: "İkinci")

    tick(board, writes: [ "düzeltilmiş" ])

    assert first.reload.agent_in_review?
    assert second.reload.agent_open?
  end

  test "a lesson is saved on the worker and goes into its next prompt" do
    board = create_agent_board
    card = create_agent_card(board)

    tick(board, writes: [ "ilk" ])
    worker = card.reload.assignee
    assert_nil worker.lessons

    tick(board, reviews: [ REVISE ])
    assert_equal "- Kelime sayısını say.", worker.reload.lessons

    llm = tick(board, writes: [ "ikinci" ])
    assert_includes llm.prompts.last[:prompt], "Ders defterin:\n- Kelime sayısını say."
  end

  test "a second failed review hands the card to a person" do
    board = create_agent_board
    card = create_agent_card(board)

    tick(board, writes: [ "ilk" ])
    tick(board, reviews: [ REVISE ])
    tick(board, writes: [ "ikinci" ])
    tick(board, reviews: [ REVISE ])

    card.reload
    assert card.agent_needs_human?
    assert_equal List::HUMAN_NAME, card.list.name
    assert_equal 2, card.attempts
    assert_equal "watchdog", card.agent_events.last.kind
  end

  test "the same output twice hands the card to a person" do
    board = create_agent_board
    card = create_agent_card(board)

    tick(board, writes: [ "aynı metin" ])
    tick(board, reviews: [ REVISE ])
    tick(board, writes: [ "Aynı  metin" ])

    card.reload
    assert card.agent_needs_human?
    assert_equal "loop", card.agent_events.last.kind
  end

  test "an escalate verdict hands the card to a person" do
    board = create_agent_board
    card = create_agent_card(board)

    tick(board, writes: [ "metin" ])
    tick(board, reviews: [ { verdict: "escalate", feedback: "Bilgi yok." } ])

    assert card.reload.agent_needs_human?
    assert_equal "escalated", card.agent_events.last.kind
  end

  test "a scenario that runs out fails loudly instead of falling back to the default" do
    board = create_agent_board
    create_agent_card(board)

    assert_raises(FakeLlm::ScenarioExhausted) { tick(board, writes: []) }
    assert_nil Card.last.assignee
  end

  test "the default scenario plays the demo: revise first, pass second, escalate for missing info" do
    board = AgentBoards::DemoSeeder.call
    llm = FakeLlm.new
    3.times { AgentBoards::Tick.new(board, llm: llm).call }
    5.times { AgentBoards::Tick.new(board, llm: llm).call }

    cards = board.lists.flat_map(&:cards)
    missing = cards.find { |card| card.title == AgentBoards::DemoSeeder::MISSING_INFO_TITLE }
    others = cards - [ missing ]

    assert missing.agent_needs_human?
    assert others.all?(&:agent_done?)
    assert others.all? { |card| card.agent_events.pluck(:kind).include?("revised") }
    assert_equal [ 2 ], others.map(&:attempts).uniq
  end

  test "a tick refuses a human board" do
    assert_raises(ArgumentError) { AgentBoards::Tick.new(boards(:one), llm: FakeLlm.new) }
  end
end
