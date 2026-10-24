require "test_helper"

class AgentBoards::TickGuidelinesTest < ActiveSupport::TestCase
  RULE = "Her metin PastelShop kelimesiyle bitsin."

  def board_with_guidelines
    create_agent_board.tap { |board| board.update!(guidelines: "- #{RULE}") }
  end

  def tick(board, llm)
    AgentBoards::Tick.new(board, llm: llm).call
  end

  test "the guidelines are only in the mentor's prompt, never the worker's" do
    board = board_with_guidelines
    create_agent_card(board)
    llm = FakeLlm.new(writes: [ "metin" ], reviews: [ { verdict: "pass" } ])

    tick(board, llm)
    tick(board, llm)

    write = llm.prompts.find { |entry| entry[:kind] == :write }[:prompt]
    review = llm.prompts.find { |entry| entry[:kind] == :review }[:prompt]
    assert_not_includes write, RULE
    assert_not_includes write, "Ekip rehberi:"
    assert_includes write, "Ekip kuralları sana ayrıca bildirilmez"
    assert_includes review, "Ekip rehberi:\n- #{RULE}"
    assert_includes review, "Rehbere aykırılık varsa verdict revise olsun"
    assert_includes review, "lesson'a kuralı işçinin bir dahaki sefere uygulayabileceği tek cümle olarak yaz"
  end

  test "the guidelines are not turned into checklist items" do
    board = board_with_guidelines
    card = create_agent_card(board, criteria: [ "Kısa olsun" ])

    assert_equal [ "Kısa olsun" ], card.checklist_items.map(&:content)
    assert_not_includes AgentBoards::Prompts.review(card), "[#{card.checklist_items.first.id}] #{RULE}"
  end

  test "a board without guidelines gets no guidelines section in the mentor's prompt" do
    board = create_agent_board
    card = create_agent_card(board)

    assert_not_includes AgentBoards::Prompts.review(card), "Ekip rehberi"
  end

  test "the mentor's lesson goes into the worker's notebook and into the next card's worker prompt" do
    board = board_with_guidelines
    first = create_agent_card(board, title: "Birinci")
    lesson = "Her metni PastelShop kelimesiyle bitir."

    tick(board, FakeLlm.new(writes: [ "ilk" ]))
    review = { verdict: "revise", feedback: "Rehber ihlali: PastelShop yok.", lesson: lesson,
               guideline_violations: [ RULE ] }
    tick(board, FakeLlm.new(reviews: [ review ]))
    worker = first.reload.assignee

    assert_equal "- #{lesson}", worker.reload.lessons
    assert first.agent_rework?
    assert_equal [ RULE ], first.agent_events.last.data["guideline_violations"]

    tick(board, FakeLlm.new(writes: [ "ikinci" ]))
    tick(board, FakeLlm.new(reviews: [ { verdict: "pass" } ]))
    second = create_agent_card(board, title: "İkinci")
    llm = FakeLlm.new(writes: [ "yeni metin" ])
    tick(board, llm)

    assert_equal worker, second.reload.assignee
    prompt = llm.prompts.last[:prompt]
    assert_includes prompt, "Ders defterin:\n- #{lesson}"
    assert_not_includes prompt, RULE
  end

  test "a pass with guideline violations becomes a revise" do
    board = board_with_guidelines
    card = create_agent_card(board)
    tick(board, FakeLlm.new(writes: [ "metin" ]))
    criteria = card.checklist_items.map { |item| { item_id: item.id, met: true, reason: "ok" } }

    tick(board, FakeLlm.new(reviews: [ { verdict: "pass", criteria: criteria, guideline_violations: [ RULE ] } ]))

    card.reload
    assert card.agent_rework?
    assert_not card.completed?
    assert_equal "Ekip rehberi ihlali: #{RULE}", card.feedback
    event = card.agent_events.last
    assert_equal "pass", event.data["overridden_from"]
    assert_equal [ RULE ], event.data["guideline_violations"]
    assert_includes event.message, "ekip rehberine aykırılık var"
  end

  test "violations and unmet criteria are both named in the feedback" do
    board = board_with_guidelines
    card = create_agent_card(board, criteria: [ "Kısa olsun" ])
    tick(board, FakeLlm.new(writes: [ "metin" ]))
    item = card.checklist_items.first

    review = { verdict: "pass", criteria: [ { item_id: item.id, met: false, reason: "uzun" } ], guideline_violations: [ RULE, "  " ] }
    tick(board, FakeLlm.new(reviews: [ review ]))

    assert_equal "Karşılanmayan kriterler: Kısa olsun. Ekip rehberi ihlali: #{RULE}", card.reload.feedback
    assert_equal [ RULE ], card.agent_events.last.data["guideline_violations"]
  end

  test "an empty or missing violations list leaves a pass alone" do
    board = board_with_guidelines
    card = create_agent_card(board)
    tick(board, FakeLlm.new(writes: [ "metin" ]))

    tick(board, FakeLlm.new(reviews: [ { verdict: "pass", guideline_violations: [] } ]))

    assert card.reload.agent_done?
    assert_equal [], card.agent_events.last.data["guideline_violations"]
  end

  test "the default scenario breaks the guideline first when the board has one" do
    board = AgentBoards::DemoSeeder.call
    llm = FakeLlm.new
    10.times { tick(board, llm) }

    revised = AgentEvent.where(kind: "revised").to_a
    assert_not_empty revised
    assert revised.all? { |event| event.data["guideline_violations"].any? }
    assert_includes board.members.worker.map(&:lessons).join, "PastelShop"
  end

  test "the demo seeder gives the board its three team rules" do
    board = AgentBoards::DemoSeeder.call

    rules = board.guidelines.lines.map(&:strip)
    assert_equal 3, rules.size
    assert_includes board.guidelines, "\"sen\""
    assert_includes board.guidelines, "Ünlem işareti"
    assert_includes board.guidelines, "PastelShop"
  end
end
