require "test_helper"

class AgentBoardsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @board = create_agent_board(workers: 2)
    @board.update!(name: "Ajan demo", guidelines: "- Her metin PastelShop kelimesiyle bitsin.")
  end

  def with_env(values)
    originals = values.keys.to_h { |key| [ key, ENV[key] ] }
    values.each { |key, value| ENV[key] = value }
    yield
  ensure
    originals.each { |key, value| ENV[key] = value }
  end

  # Runs rounds with the default FakeLlm scenario until the first card is reviewed once.
  def run_rounds(count)
    count.times { post board_round_url(@board) }
  end

  test "an agent board opens with its mode, round button, guidelines and agents, without drag and drop" do
    create_agent_card(@board, title: "İlk görev")
    @board.members.worker.first.update!(lessons: "- Kelimeleri say.")

    get board_url(@board)

    assert_response :success
    assert_select "#agent_mode", text: /simülasyon modu/
    assert_select "button#run_round[data-turbo-submits-with=?]", "Ajanlar çalışıyor…", text: /Bir tur çalıştır/
    assert_select "[data-controller~=sortable]", count: 0
    assert_select "#guidelines", text: /Mentorun bildiği ekip kuralları/
    assert_select "#guidelines li", text: /PastelShop/
    assert_select "#agents", text: /Ders defteri/
    assert_select "#agents", text: /Kelimeleri say/
    assert_select "#agents", text: /worker-model/
    [ List::POOL_NAME, List::REVIEW_NAME, List::REWORK_NAME, List::HUMAN_NAME, List::DONE_NAME ].each do |name|
      assert_select "section h2", text: /#{name}/
    end
    assert_select "article", text: /İlk görev/
    assert_select "summary", text: /Görev ekle/
  end

  test "the mode label names the models when a Groq key is set" do
    with_env("GROQ_API_KEY" => "test-key") do
      get board_url(@board)
    end

    assert_select "#agent_mode", text: "Groq · worker-model / mentor-model"
  end

  test "the round button runs a round, shows the summary and refreshes the board" do
    first = create_agent_card(@board, title: "Birinci")
    second = create_agent_card(@board, title: "İkinci")

    post board_round_url(@board)

    assert_redirected_to board_url(@board)
    assert_equal "Tur bitti: 2 kart ilerledi.", flash[:notice]
    assert_predicate first.reload, :agent_in_review?
    assert_predicate second.reload, :agent_in_review?

    follow_redirect!
    assert_select "#notice", text: "Tur bitti: 2 kart ilerledi."
    assert_select "##{ActionView::RecordIdentifier.dom_id(@board.agent_list(:in_review))} article", count: 2
  end

  test "a failed round shows the llm errors in the summary" do
    create_agent_card(@board)
    llm = FakeLlm.new
    llm.define_singleton_method(:write) { |**| raise LlmError, "Groq HTTP 429" }

    stub_class_method(AgentBoards::LlmFactory, :build, ->(**) { llm }) do
      post board_round_url(@board)
    end

    assert_equal "Tur bitti: 0 kart ilerledi, 1 LLM hatası.", flash[:notice]
  end

  test "rounds cannot be run on a human board" do
    post board_round_url(boards(:one))

    assert_response :not_found
  end

  test "adding a task puts it in the pool and turns every criteria line into a checklist item" do
    assert_difference -> { Card.count } => 1, -> { ChecklistItem.count } => 3 do
      post board_agent_tasks_url(@board), params: { agent_task: {
        title: "Canlı görev", description: "Ürün: Test",
        criteria: "En fazla 10 kelime\n\n- Emoji olmasın\r\n  \"ücretsiz kargo\" geçsin  \n"
      } }
    end

    assert_redirected_to board_url(@board)
    card = Card.find_by!(title: "Canlı görev")
    assert_equal List::POOL_NAME, card.list.name
    assert_predicate card, :agent_open?
    assert_equal "Ürün: Test", card.description
    assert_equal [ "En fazla 10 kelime", "Emoji olmasın", "\"ücretsiz kargo\" geçsin" ], card.checklist_items.map(&:content)
    assert_equal "created", card.agent_events.sole.kind
  end

  test "a task needs a title and at least one criterion" do
    assert_no_difference -> { Card.count } do
      post board_agent_tasks_url(@board), params: { agent_task: { title: "", criteria: "Kısa olsun" } }
      assert_equal "Görev başlığı boş olamaz.", flash[:alert]

      post board_agent_tasks_url(@board), params: { agent_task: { title: "Başlık", criteria: " \n \n" } }
      assert_match(/en az bir kabul kriteri/i, flash[:alert])
    end
  end

  test "tasks cannot be added to a human board" do
    post board_agent_tasks_url(boards(:one)), params: { agent_task: { title: "x", criteria: "y" } }

    assert_response :not_found
  end

  test "the card detail shows the output, criteria results, guideline violation, feedback and timeline" do
    card = create_agent_card(@board, title: "Kulaklık")
    @board = card.board
    run_rounds(2)

    get card_url(card)

    assert_response :success
    assert_select "#card_detail", text: /Kulaklık/
    assert_select "#card_output", text: /harika bir ürün/
    assert_select "#guideline_violations", text: /Ekip rehberi ihlali/
    assert_select "#guideline_violations li", text: /PastelShop/
    assert_select "#mentor_feedback", text: /PastelShop/
    assert_select "#timeline li", count: 2
    assert_select "#timeline li", text: /çıktıyı teslim etti/
    assert_select "#timeline li", text: /düzeltme istedi/
    assert_select "#human_actions", count: 0
  end

  test "the criteria show a check or a cross with the reason once the mentor has reviewed" do
    card = create_agent_card(@board, criteria: [ "Kısa olsun", "Emoji olmasın" ])
    first, second = card.checklist_items.to_a
    @board.members.worker.first # cards need an owner before a review
    AgentBoards::Tick.new(@board, llm: FakeLlm.new(writes: [ "metin" ])).call
    review = { verdict: "revise", feedback: "Kısalt.",
               criteria: [ { item_id: first.id, met: true, reason: "kısa" }, { item_id: second.id, met: false, reason: "emoji var" } ] }
    AgentBoards::Tick.new(@board, llm: FakeLlm.new(reviews: [ review ])).call

    get card_url(card)

    assert_select "span[aria-label=Karşılandı]", count: 1
    assert_select "span[aria-label=Karşılanmadı]", count: 1
    assert_select "#card_detail", text: /emoji var/
  end

  test "llm errors show up in the timeline" do
    card = create_agent_card(@board)
    llm = FakeLlm.new
    llm.define_singleton_method(:write) { |**| raise LlmError, "Groq HTTP 429: rate limited" }
    AgentBoards::Tick.new(@board, llm: llm).call

    get card_url(card)

    assert_select "#timeline li", text: /LLM hatası \(write\): Groq HTTP 429/
  end

  test "a card waiting for a person shows the question and both human actions" do
    card = create_agent_card(@board, title: AgentBoards::DemoSeeder::MISSING_INFO_TITLE)
    run_rounds(1)
    assert_predicate card.reload, :agent_needs_human?

    get card_url(card)

    assert_select "#human_actions", text: /Ajan insana soru sordu/
    assert_select "#human_actions", text: /Ürünün adı ve özellikleri nedir/
    assert_select "#human_actions form textarea[name=hint]"
    assert_select "#human_actions input[type=submit][value=?]", "İpucu ver ve geri gönder"
    assert_select "#human_actions button", text: "Onayla, Done'a taşı"
    assert_select "section h2", text: /İnsan lazım|İnsana devredildi/
  end

  test "the agent's question and the human hint have their own headings, not the mentor's" do
    card = create_agent_card(@board, title: AgentBoards::DemoSeeder::MISSING_INFO_TITLE)
    run_rounds(1)

    get card_url(card)

    assert_select "#agent_question", text: /Ajanın sorusu.*Ürünün adı ve özellikleri nedir/m
    assert_select "#mentor_feedback", count: 0
    assert_select "#human_hint", count: 0

    post card_hint_url(card), params: { hint: "Ürün adı Nova X1." }
    get card_url(card)

    assert_select "#human_hint", text: /İnsan ipucu.*Ürün adı Nova X1/m
    assert_select "#mentor_feedback", count: 0
    assert_select "#agent_question", count: 0
  end

  test "mentor feedback shows only what the mentor said, apart from an earlier hint" do
    card = create_agent_card(@board, title: AgentBoards::DemoSeeder::MISSING_INFO_TITLE)
    run_rounds(1)
    post card_hint_url(card), params: { hint: "Ürün adı Nova X1." }
    review = { verdict: "revise", feedback: "Daha kısa yaz.",
               criteria: card.checklist_items.map { |item| { item_id: item.id, met: false, reason: "uzun" } } }
    AgentBoards::Tick.new(@board, llm: FakeLlm.new(writes: [ "Nova X1 kulaklık." ])).call
    AgentBoards::Tick.new(@board, llm: FakeLlm.new(reviews: [ review ])).call

    get card_url(card)

    assert_select "#mentor_feedback", text: /Mentor geri bildirimi.*Daha kısa yaz/m
    assert_select "#mentor_feedback", text: /İnsan ipucu/, count: 0
    assert_select "#human_hint", count: 0
  end

  test "giving a hint sends the card back to its worker" do
    card = create_agent_card(@board, title: AgentBoards::DemoSeeder::MISSING_INFO_TITLE)
    run_rounds(1)

    post card_hint_url(card), params: { hint: "Ürün adı Nova X1." }

    assert_redirected_to card_url(card)
    card.reload
    assert_predicate card, :agent_rework?
    assert_equal 0, card.attempts
    assert_includes card.feedback, "İnsan ipucu: Ürün adı Nova X1."
    assert_equal "hint_given", card.agent_events.last.kind
  end

  test "an empty hint is refused" do
    card = create_agent_card(@board, title: AgentBoards::DemoSeeder::MISSING_INFO_TITLE)
    run_rounds(1)

    post card_hint_url(card), params: { hint: "  " }

    assert_equal "İpucu boş olamaz.", flash[:alert]
    assert_predicate card.reload, :agent_needs_human?
  end

  test "approving moves the card to Done" do
    card = create_agent_card(@board, title: AgentBoards::DemoSeeder::MISSING_INFO_TITLE)
    run_rounds(1)

    post card_approval_url(card)

    assert_redirected_to card_url(card)
    card.reload
    assert_predicate card, :agent_done?
    assert_predicate card, :completed?
    assert_equal List::DONE_NAME, card.list.name
    assert card.checklist_items.all?(&:done?)
  end

  test "human actions on a card that is not waiting for a person only show an alert" do
    card = create_agent_card(@board)

    post card_hint_url(card), params: { hint: "ipucu" }
    assert_match(/not waiting for a person/, flash[:alert])
    post card_approval_url(card)
    assert_match(/not waiting for a person/, flash[:alert])

    assert_predicate card.reload, :agent_open?
  end

  test "human actions do not work on cards of a human board" do
    card = cards(:one)

    post card_approval_url(card)

    assert_response :redirect
    assert_nil card.reload.agent_state
    assert_equal List.find(card.list_id).name, "To Do"
  end

  test "resetting the demo board is not available without demo mode" do
    with_env("DEMO_MODE" => nil) do
      assert_no_difference -> { Board.count } do
        post agent_demo_url
      end
    end

    assert_response :not_found
  end

  test "in demo mode the demo board is built, and built again from scratch on a second request" do
    with_env("DEMO_MODE" => "1") do
      post agent_demo_url
      board = Board.find_by!(name: AgentBoards::DemoSeeder::BOARD_NAME)
      assert_redirected_to board_url(board)
      assert_equal 4, board.agent_list(:open).cards.size
      assert_predicate board, :agent?

      AgentBoards::Tick.new(board, llm: FakeLlm.new).call
      assert_no_difference -> { Board.where(name: AgentBoards::DemoSeeder::BOARD_NAME).count } do
        post agent_demo_url
      end
      assert_equal 4, Board.find_by!(name: AgentBoards::DemoSeeder::BOARD_NAME).agent_list(:open).cards.size
    end
  end

  test "the boards list shows the demo button only in demo mode and marks agent boards" do
    with_env("DEMO_MODE" => nil) do
      get boards_url
      assert_select "button", text: /Demo ajan panosu/, count: 0
    end

    with_env("DEMO_MODE" => "1") do
      get boards_url
      assert_select "button", text: "Demo ajan panosu oluştur/sıfırla"
    end

    assert_select "h2", text: /Ajan demo/
    assert_select "h2 span", text: "Ajan panosu"
  end

  test "the demo reset button on an agent board is hidden without demo mode" do
    with_env("DEMO_MODE" => nil) do
      get board_url(@board)
      assert_select "button", text: "Demo panoyu sıfırla", count: 0
    end
    with_env("DEMO_MODE" => "1") do
      get board_url(@board)
      assert_select "button", text: "Demo panoyu sıfırla"
    end
  end

  test "human boards and their cards open as before" do
    get board_url(boards(:one))

    assert_response :success
    assert_select "[data-controller~=sortable]"
    assert_select "#run_round", count: 0
    assert_select "#agents", count: 0
    assert_select "summary", text: /Yeni Görev Ekle/

    get card_url(cards(:one))

    assert_response :success
    assert_select "#card_detail", text: /Kontrol listesi/
    assert_select "#human_actions", count: 0
  end
end
