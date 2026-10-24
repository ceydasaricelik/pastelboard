require "test_helper"

class AgentBoards::PromptsTest < ActiveSupport::TestCase
  setup do
    @board = create_agent_board
    @card = create_agent_card(@board)
  end

  test "the worker prompt makes feedback and notebook rules binding and limits BİLGİ EKSİK to missing content" do
    prompt = AgentBoards::Prompts.write(@card, @board.members.worker.first)

    assert_includes prompt, "Mentor geri bildirimindeki ve ders defterindeki kurallar kesindir. Bunları soru konusu yapma, uygula."
    assert_includes prompt, "BİLGİ EKSİK yalnızca kartta olmayan içerik bilgisi (ürün adı, özellik vb.) için kullanılır."
  end

  test "the mentor prompt asks for every field in Turkish" do
    prompt = AgentBoards::Prompts.review(@card)

    assert_includes prompt, "Tüm alanları (reason, feedback, lesson, guideline_violations) Türkçe yaz."
  end
end
