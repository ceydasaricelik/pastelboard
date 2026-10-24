require "test_helper"

class AgentBoards::TickResilienceTest < ActiveSupport::TestCase
  class FailFirstWriteLlm < FakeLlm
    def write(**)
      return super if @failed

      @failed = true
      raise LlmError, "Groq HTTP 429: rate limited"
    end
  end

  def tick(board, llm)
    AgentBoards::Tick.new(board, llm: llm).call
  end

  test "a failed write leaves the card in place, releases it and writes an llm_error event" do
    board = create_agent_board
    card = create_agent_card(board)

    assert_equal 1, tick(board, FailFirstWriteLlm.new(writes: [ "x" ]))

    card.reload
    assert card.agent_open?
    assert_nil card.assignee
    assert_equal 0, card.attempts
    assert_equal List::POOL_NAME, card.list.name
    event = card.agent_events.sole
    assert_equal "llm_error", event.kind
    assert_includes event.message, "429"
    assert_equal "write", event.data["stage"]
  end

  test "after a failure the next round takes the card again" do
    board = create_agent_board
    card = create_agent_card(board)
    llm = FailFirstWriteLlm.new(writes: [ "metin" ])

    tick(board, llm)
    tick(board, llm)

    assert card.reload.agent_in_review?
    assert_equal 1, card.attempts
  end

  test "a failed round does not crash: the other cards still move and the failed card counts toward the limit" do
    board = create_agent_board(workers: 3)
    cards = Array.new(4) { |i| create_agent_card(board, title: "K#{i}") }

    assert_equal 3, tick(board, FailFirstWriteLlm.new(writes: %w[ a b ]))

    assert_equal %w[ open in_review in_review open ], cards.map { |card| card.reload.agent_state }
  end

  test "a failed review keeps the card in review and does not touch attempts or the worker's lessons" do
    board = create_agent_board
    card = create_agent_card(board)
    tick(board, FakeLlm.new(writes: [ "metin" ]))

    tick(board, FakeLlm.new(reviews: [ { verdict: "banana", lesson: "yok say" } ]))

    card.reload
    assert card.agent_in_review?
    assert_equal 1, card.attempts
    assert_nil card.assignee.lessons
    event = card.agent_events.last
    assert_equal "llm_error", event.kind
    assert_equal "review", event.data["stage"]
    assert_includes event.message, "geçersiz verdict"
  end

  test "an invalid verdict is not retried in the same round" do
    board = create_agent_board
    create_agent_card(board)
    tick(board, FakeLlm.new(writes: [ "metin" ]))
    llm = FakeLlm.new(reviews: [ { verdict: "banana" } ])

    assert_equal 1, tick(board, llm)
    assert_equal 1, llm.prompts.count { |entry| entry[:kind] == :review }
  end

  test "criteria that are not on the card's checklist are ignored" do
    board = create_agent_board
    card = create_agent_card(board)
    foreign = create_agent_card(board, title: "Başka").checklist_items.first
    own = card.checklist_items.first
    tick(board, FakeLlm.new(writes: [ "metin" ]))

    criteria = [ { item_id: own.id, met: true, reason: "ok" }, { item_id: foreign.id, met: false, reason: "yabancı" },
                 { item_id: 0, met: true, reason: "yok" }, "bozuk" ]
    tick(board, FakeLlm.new(reviews: [ { verdict: "pass", criteria: criteria } ]))

    assert card.reload.agent_done?
    assert_equal [ own.id ], card.agent_events.last.data["criteria"].map { |c| c["item_id"] }
  end

  test "a mentor answer that is not an object is an llm error" do
    board = create_agent_board
    card = create_agent_card(board)
    tick(board, FakeLlm.new(writes: [ "metin" ]))

    tick(board, FakeLlm.new(reviews: [ [ "pass" ] ]))

    assert card.reload.agent_in_review?
    assert_equal "llm_error", card.agent_events.last.kind
  end

  test "a card another round already moved is skipped: no second model call, no duplicate event" do
    board = create_agent_board
    card = create_agent_card(board)
    snapshot = AgentBoards::Tick.new(board, llm: FakeLlm.new).candidates
    assert_equal [ card.id ], snapshot.map(&:id)

    tick(board, FakeLlm.new(writes: [ "ilk" ]))

    late = FakeLlm.new(writes: [ "ikinci" ])
    assert_equal 0, AgentBoards::Tick.new(board, llm: late).call(snapshot)

    assert_empty late.prompts
    card.reload
    assert card.agent_in_review?
    assert_equal 1, card.attempts
    assert_equal "ilk", card.output
    assert_equal 1, card.agent_events.where(kind: "written").count
  end

  test "a snapshot taken while the card was in review does not review it a second time" do
    board = create_agent_board
    card = create_agent_card(board)
    tick(board, FakeLlm.new(writes: [ "ilk" ]))
    snapshot = AgentBoards::Tick.new(board, llm: FakeLlm.new).candidates
    assert_equal [ "in_review" ], snapshot.map(&:agent_state)
    tick(board, FakeLlm.new(reviews: [ { verdict: "pass" } ]))

    late = FakeLlm.new(reviews: [ { verdict: "revise" } ])
    assert_equal 0, AgentBoards::Tick.new(board, llm: late).call(snapshot)

    assert_empty late.prompts
    assert card.reload.agent_done?
    assert_equal 1, card.agent_events.where(kind: "passed").count
  end

  test "events say simulation mode when the fake model is used" do
    board = create_agent_board
    card = create_agent_card(board)

    tick(board, FakeLlm.new(writes: [ "metin" ]))

    event = card.agent_events.last
    assert_includes event.message, "(simülasyon modu)"
    assert_equal true, event.data["simulation"]
  end

  test "an end-to-end failure through GroqLlm keeps the card in place and the round alive" do
    board = create_agent_board
    card = create_agent_card(board)
    llm = GroqLlm.new(api_key: "test-key")
    response = Struct.new(:code, :body).new("429", "rate limited")
    http = Object.new
    http.define_singleton_method(:request) { |_request| response }

    stub_class_method(Net::HTTP, :start, ->(*, **, &block) { block.call(http) }) do
      assert_equal 1, tick(board, llm)
    end

    card.reload
    assert card.agent_open?
    event = card.agent_events.sole
    assert_equal "llm_error", event.kind
    assert_includes event.message, "429"
    assert_not_includes event.message, "(simülasyon modu)"
    assert_nil event.data["simulation"]
  end
end
