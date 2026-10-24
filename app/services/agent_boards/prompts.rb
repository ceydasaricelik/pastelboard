module AgentBoards
  # The texts handed to the LLM. The acceptance criteria are the card's checklist items.
  module Prompts
    module_function

    def write(card, worker)
      sections = [ "Görev: #{card.title}" ]
      sections << "Açıklama: #{card.description}" if card.description.present?
      sections << "Kabul kriterleri:\n#{criteria(card)}"
      sections << "Önceki geri bildirim:\n#{card.feedback}" if card.feedback.present?
      sections << "Ders defterin:\n#{worker.lessons}" if worker.lessons.present?
      sections << "Görev için gereken bilgi kartta yoksa uydurma. Çıktıyı yalnızca \"BİLGİ EKSİK: \" ile başlat " \
                  "ve insana sorulacak soruyu yaz. Bilgi yeterliyse yalnızca teslim edilecek metni yaz."
      sections.join("\n\n")
    end

    def review(card)
      [
        "Görev: #{card.title}",
        "Açıklama: #{card.description}",
        "Kabul kriterleri:\n#{criteria(card)}",
        "Teslim edilen çıktı:\n#{card.output}",
        "Her kriteri harfiyen kontrol et; kelime ve madde sayılarını tek tek say. Emin değilsen met=false ver. " \
          "Kartta olmayan bir bilgi (ürün adı, özellik, fiyat vb.) çıktıda geçiyorsa bu uydurmadır: revise. " \
          "Görev karttaki bilgiyle yapılamıyorsa: escalate.",
        "Her kriter için { item_id, met, reason } ver; verdict pass, revise veya escalate olsun. " \
          "Düzeltilebilir hatalarda feedback ve işçinin ders defterine girecek kısa bir lesson yaz."
      ].join("\n\n")
    end

    def criteria(card)
      card.checklist_items.map { |item| "- [#{item.id}] #{item.content}" }.join("\n")
    end
  end
end
