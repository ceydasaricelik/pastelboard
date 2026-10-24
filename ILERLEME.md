# ILERLEME

Ajan panosu çalışmasının adım adım kayıt defteri. Her adımın sonunda buraya bir kayıt eklenir; yeni bir oturum önce son kaydı okuyarak başlar. Kurallar: [AGENTS.md](AGENTS.md).

## Kayıt şablonu

```
## Adım N — Başlık
- Tarih/saat: (date komutuyla)
- Ne yapıldı:
- Eklenen/değişen dosyalar:
- Testler: X test, Y doğrulama, 0 hata
- Commit mesajı:
- Açık kalanlar / notlar:
- Ceyda'nın süresi: (boş bırak)
```

## Adım 0 — Hazırlık
- Tarih/saat: 2026-10-24 16:27:39 +03:00
- Ne yapıldı: Çalışma düzeni kuruldu, özellik kodu yazılmadı. `AGENT.md` → `AGENTS.md` olarak yeniden adlandırıldı (`git mv`); kökte tek satırlık `CLAUDE.md` (`@AGENTS.md`) oluşturuldu; AGENTS.md'ye "Ajan panosu çalışma kuralları" bölümü eklendi; `ILERLEME.md` ve `CHALLENGE_LOG.md` oluşturuldu. README ve PROJE_DURUMU'ndaki `AGENT.md` bağlantıları `AGENTS.md`'ye güncellendi.
- Eklenen/değişen dosyalar: AGENTS.md (eski AGENT.md), CLAUDE.md, ILERLEME.md, CHALLENGE_LOG.md, README.md, PROJE_DURUMU.md
- Testler: 34 test, 114 doğrulama, 0 hata (RuboCop ve Brakeman temiz)
- Commit mesajı: Adım 0: Hazırlık — AGENTS.md, CLAUDE.md, ILERLEME.md ve CHALLENGE_LOG.md ile çalışma düzeni kuruldu
- Açık kalanlar / notlar: `PROJE_DURUMU.md` ve `odev.md` önceden takip edilmiyordu (untracked); bu commit'e yalnızca çalışma düzeni dosyaları alındı, ikisi dışarıda bırakıldı.
- Ceyda'nın süresi:

## Adım 1 — Ajan panosunun çekirdeği
- Tarih/saat: 2026-10-24 17:04:06 +03:00
- Ne yapıldı: Ajan panosunun veri modeli ve çekirdek akışı eklendi; gerçek LLM yok, her şey FakeLlm ile. `Board.kind`; `Member.kind/role/model/lessons`; `Card.agent_state/assignee_id/attempts/output/feedback`; yeni `AgentEvent`. `List`'e ajan panosunun sabit listeleri eklendi (Havuz, Mentor incelemesinde, Düzeltmede, İnsana devredildi, Done). `AgentBoards::Tick` (tur başına en fazla 3 kart, işçi başına en fazla 1 kart; `open` kartı koşullu UPDATE ile atomik alma, `rework` kartı aynı sahibine döner; mentor pass/revise/escalate; gözcü: ikinci denemede yine revise ve aynı çıktı tekrarı insana devreder). `AgentBoards::HumanActions` (ipucu ver ve geri gönder, onayla). `FakeLlm`: varsayılan senaryo demo gibi (ilk teslime revise, ikinciye pass, `DemoSeeder::MISSING_INFO_TITLE` başlıklı kartta escalate); testler `writes:` / `reviews:` ile kendi senaryosunu verir, senaryo biterse `ScenarioExhausted` fırlatır. `AgentBoards::DemoSeeder` ("Ajan Panosu (Demo)": 2 işçi llama-3.1-8b-instant, 1 mentor openai/gpt-oss-120b, 4 görev; panoyu sıfırlayıp kurar). `EscalateOverdueCardsJob` ajan panolarını atlıyor. Bilgi eksik kartın işareti açıklamada değil, yalnızca başlık sabitinde; şemada ek kolon yok.
- Eklenen/değişen dosyalar: db/migrate/20261024170000_add_agent_board.rb, db/schema.rb, app/models/{agent_event,board,card,list,member}.rb, app/jobs/escalate_overdue_cards_job.rb, app/services/fake_llm.rb, app/services/agent_boards/{tick,prompts,human_actions,demo_seeder}.rb, test/test_helper.rb, test/services/agent_boards/{tick,human_actions,demo_seeder}_test.rb, test/jobs/escalate_overdue_cards_job_agent_board_test.rb, AGENTS.md (Windows komut kuralı), PROJE_DURUMU.md (git'e eklendi; odev.md takip dışı kaldı)
- Testler: 56 test, 209 doğrulama, 0 hata (34 eski + 22 yeni; RuboCop ve Brakeman temiz)
- Commit mesajı: Adım 1: Ajan panosunun çekirdeği — Tick servisi, FakeLlm, insan aksiyonları ve demo seeder
- Açık kalanlar / notlar: Toplam test sayısı 50'yi geçince Rails testleri otomatik paralel (thread) çalıştırıyor ve bu Windows makinede takılıyor; eski 34 testle zorla paralel çalıştırınca da takıldığı doğrulandı (sorun yeni kodda değil). `test_helper.rb`'de paralel eşiği 500'e çıkarıldı. Linux CI'da paralel çalışma denenmedi. Tick, aynı kartı eşzamanlı iki Tick'in ilerletmesine karşı yalnızca `open` için korumalı (koşullu UPDATE); `in_review` ve `rework` için kilit yok. Arayüz Adım 3'te.
- Ceyda'nın süresi:
