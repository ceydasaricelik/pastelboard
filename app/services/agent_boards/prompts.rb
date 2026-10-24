module AgentBoards
  # The texts handed to the LLM. The acceptance criteria are the card's checklist items.
  module Prompts
    module_function

    def write(card, worker)
      sections = [
        "Görev: #{card.title}",
        "Açıklama: #{card.description}",
        "Kabul kriterleri:\n#{criteria(card)}"
      ]
      sections << "Önceki geri bildirim:\n#{card.feedback}" if card.feedback.present?
      sections << "Ders defterin:\n#{worker.lessons}" if worker.lessons.present?
      sections << "Yalnızca teslim edilecek metni yaz."
      sections.join("\n\n")
    end

    def review(card)
      [
        "Görev: #{card.title}",
        "Açıklama: #{card.description}",
        "Kabul kriterleri:\n#{criteria(card)}",
        "Teslim edilen çıktı:\n#{card.output}",
        "Her kriter için { item_id, met, reason } ver; verdict pass, revise veya escalate olsun. " \
          "Düzeltilebilir hatalarda feedback ve işçinin ders defterine girecek kısa bir lesson yaz."
      ].join("\n\n")
    end

    def criteria(card)
      card.checklist_items.map { |item| "- [#{item.id}] #{item.content}" }.join("\n")
    end
  end
end
