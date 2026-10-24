require "test_helper"

class AgentBoards::HumanActionsTest < ActiveSupport::TestCase
  REVISE = { verdict: "revise", feedback: "Kısalt." }.freeze

  # A card the mentor gave up on: two failed attempts.
  def handed_over_card
    board = create_agent_board
    card = create_agent_card(board)
    llm = FakeLlm.new(writes: %w[ ilk ikinci ], reviews: [ REVISE, REVISE ])
    4.times { AgentBoards::Tick.new(board, llm: llm).call }
    card.reload
  end

  test "a hint sends the card back to rework with fresh attempts" do
    card = handed_over_card
    assert card.agent_needs_human?

    AgentBoards::HumanActions.give_hint(card, "Rakamla yaz.")

    card.reload
    assert card.agent_rework?
    assert_equal List::REWORK_NAME, card.list.name
    assert_equal 0, card.attempts
    assert_includes card.feedback, "Kısalt."
    assert_includes card.feedback, "İnsan ipucu: Rakamla yaz."
    assert_equal "hint_given", card.agent_events.last.kind
  end

  test "after a hint the same worker writes the card again" do
    card = handed_over_card
    owner = card.assignee
    AgentBoards::HumanActions.give_hint(card, "Rakamla yaz.")

    llm = FakeLlm.new(writes: [ "üçüncü" ])
    AgentBoards::Tick.new(card.board, llm: llm).call

    assert card.reload.agent_in_review?
    assert_equal owner, card.assignee
    assert_equal 1, card.attempts
    assert_includes llm.prompts.last[:prompt], "Rakamla yaz."
  end

  test "approving moves the card to Done and completes it" do
    card = handed_over_card

    AgentBoards::HumanActions.approve(card)

    card.reload
    assert card.agent_done?
    assert card.completed?
    assert_equal List::DONE_NAME, card.list.name
    assert card.checklist_items.all?(&:done?)
    assert_equal "approved", card.agent_events.last.kind
  end

  test "both actions are only for cards waiting for a person" do
    card = create_agent_card(create_agent_board)

    assert_raises(ArgumentError) { AgentBoards::HumanActions.give_hint(card, "ipucu") }
    assert_raises(ArgumentError) { AgentBoards::HumanActions.approve(card) }
    assert card.reload.agent_open?
  end
end
