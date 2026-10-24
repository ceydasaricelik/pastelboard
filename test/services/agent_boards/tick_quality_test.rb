require "test_helper"

class AgentBoards::TickQualityTest < ActiveSupport::TestCase
  def tick(board, **scenario)
    AgentBoards::Tick.new(board, llm: FakeLlm.new(**scenario)).call
  end

  def criteria_for(card, met:)
    card.checklist_items.map { |item| { item_id: item.id, met: met, reason: "gerekçe" } }
  end

  test "a BİLGİ EKSİK delivery hands the card to a person with the question" do
    board = create_agent_board
    card = create_agent_card(board)

    summary = tick(board, writes: [ "BİLGİ EKSİK: Ürünün adı nedir?\nFiyatı da lazım." ])

    card.reload
    assert_equal 1, summary.advanced
    assert card.agent_needs_human?
    assert_equal List::HUMAN_NAME, card.list.name
    assert_equal "Ürünün adı nedir? Fiyatı da lazım.", card.feedback
    assert_equal 1, card.attempts
    event = card.agent_events.last
    assert_equal "question", event.kind
    assert_equal "Ajan insana soru sordu: Ürünün adı nedir? Fiyatı da lazım. (simülasyon modu)", event.message
    assert_equal "Ürünün adı nedir? Fiyatı da lazım.", event.data["question"]
    assert_equal card.assignee, event.actor
  end

  test "the prefix is recognised in other spellings" do
    [ "bilgi eksik: soru", "BILGI EKSIK: soru", "  Bilgi Eksik : soru", "**BİLGİ EKSİK: soru" ].each do |text|
      board = create_agent_board
      card = create_agent_card(board)

      tick(board, writes: [ text ])

      assert card.reload.agent_needs_human?, "#{text.inspect} was not recognised"
      assert_equal "soru", card.feedback
    end
  end

  test "the phrase in the middle of a text is not a question" do
    board = create_agent_board
    card = create_agent_card(board)

    tick(board, writes: [ "Metin. BİLGİ EKSİK: değil, sadece geçiyor." ])

    assert card.reload.agent_in_review?
  end

  test "a question without text still hands the card over" do
    board = create_agent_board
    card = create_agent_card(board)

    tick(board, writes: [ "BİLGİ EKSİK:" ])

    assert card.reload.agent_needs_human?
    assert_equal "Eksik bilgi belirtilmedi.", card.feedback
  end

  test "after the person's hint the worker writes the card again" do
    board = create_agent_board
    card = create_agent_card(board)
    tick(board, writes: [ "BİLGİ EKSİK: Ürün adı?" ])

    AgentBoards::HumanActions.give_hint(card.reload, "Ürün adı Nova X1.")
    llm = FakeLlm.new(writes: [ "Nova X1 harika." ])
    AgentBoards::Tick.new(board, llm: llm).call

    assert card.reload.agent_in_review?
    assert_includes llm.prompts.last[:prompt], "Nova X1"
  end

  test "a pass with an unmet criterion becomes a revise" do
    board = create_agent_board
    card = create_agent_card(board)
    tick(board, writes: [ "metin" ])
    criteria = criteria_for(card, met: true)
    criteria.last[:met] = false

    tick(board, reviews: [ { verdict: "pass", criteria: criteria, feedback: "Olur.", lesson: "Say." } ])

    card.reload
    assert card.agent_rework?
    assert_not card.completed?
    assert card.checklist_items.none?(&:done?)
    assert_equal "Olur.", card.feedback
    assert_equal "Say.", card.assignee.lessons.delete_prefix("- ")
    event = card.agent_events.last
    assert_equal "revised", event.kind
    assert_equal "pass", event.data["overridden_from"]
    assert_equal "revise", event.data["verdict"]
    assert_includes event.message, "pass dedi ama karşılanmayan kriter var"
  end

  test "an overridden pass without feedback names the unmet criteria" do
    board = create_agent_board
    card = create_agent_card(board, criteria: [ "Kısa olsun", "Emoji olmasın" ])
    tick(board, writes: [ "metin" ])
    first, second = card.checklist_items.to_a

    tick(board, reviews: [ { verdict: "pass", criteria: [ { item_id: first.id, met: true, reason: "" },
                                                            { item_id: second.id, met: false, reason: "emoji var" } ] } ])

    assert_equal "Karşılanmayan kriterler: Emoji olmasın", card.reload.feedback
  end

  test "an overridden pass on the second attempt hands the card to a person" do
    board = create_agent_board
    card = create_agent_card(board)
    tick(board, writes: [ "ilk" ])
    tick(board, reviews: [ { verdict: "revise", feedback: "Kısalt." } ])
    tick(board, writes: [ "ikinci" ])

    tick(board, reviews: [ { verdict: "pass", criteria: criteria_for(card, met: false) } ])

    card.reload
    assert card.agent_needs_human?
    assert_equal "watchdog", card.agent_events.last.kind
  end

  test "a pass with every criterion met, or with only foreign unmet ones, stays a pass" do
    board = create_agent_board
    card = create_agent_card(board)
    foreign = create_agent_card(board, title: "Başka").checklist_items.first
    tick(board, writes: [ "metin" ])
    criteria = criteria_for(card, met: true) + [ { item_id: foreign.id, met: false, reason: "yabancı" } ]

    tick(board, reviews: [ { verdict: "pass", criteria: criteria } ])

    assert card.reload.agent_done?
    assert_nil card.agent_events.last.data["overridden_from"]
  end

  test "an escalate verdict is left alone even with unmet criteria" do
    board = create_agent_board
    card = create_agent_card(board)
    tick(board, writes: [ "metin" ])

    tick(board, reviews: [ { verdict: "escalate", criteria: criteria_for(card, met: false) } ])

    assert card.reload.agent_needs_human?
  end

  test "the write prompt tells the worker not to invent missing information" do
    board = create_agent_board
    create_agent_card(board)
    llm = FakeLlm.new(writes: [ "metin" ])

    AgentBoards::Tick.new(board, llm: llm).call

    prompt = llm.prompts.last[:prompt]
    assert_includes prompt, "uydurma"
    assert_includes prompt, "BİLGİ EKSİK: "
  end

  test "the review prompt is strict about counting and invention" do
    board = create_agent_board
    create_agent_card(board)
    tick(board, writes: [ "metin" ])
    llm = FakeLlm.new(reviews: [ { verdict: "pass" } ])

    AgentBoards::Tick.new(board, llm: llm).call

    prompt = llm.prompts.last[:prompt]
    [ "tek tek say", "met=false", "uydurma", "escalate" ].each { |phrase| assert_includes prompt, phrase }
  end
end
