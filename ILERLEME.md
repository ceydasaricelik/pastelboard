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

## Adım 2 — Gerçek LLM istemcisi (Groq) ve Tick sağlamlaştırması
- Tarih/saat: 2026-10-24 17:32:46 +03:00
- Ne yapıldı: `GroqLlm` eklendi (Net::HTTP, yeni gem yok; `https://api.groq.com/openai/v1/chat/completions`; anahtar yalnızca `ENV["GROQ_API_KEY"]`; open_timeout 5 sn, read_timeout 20 sn). `write`: işçinin modeli, düz metin, `max_tokens: 300`. `review`: mentorun modeli, `max_tokens: 1000` (gpt-oss akıl yürütme token'ları için), `response_format` `json_schema` + `strict: true`, tüm alanlar `required`, tüm objelerde `additionalProperties: false`, `openai/gpt-oss*` modellerine `reasoning_effort: "low"`; `finish_reason: "length"` LLM hatası sayılır. 429/5xx, zaman aşımı, bağlantı hatası, bozuk JSON ve kesik cevap `LlmError` fırlatır. `AgentBoards::LlmFactory`: anahtar varsa GroqLlm, yoksa FakeLlm; FakeLlm iken olay mesajlarına "(simülasyon modu)" ve `data.simulation: true` yazılır. `Tick`: her kart `card.with_lock` içinde (LLM çağrısı dahil) ilerler, kilit içinde `agent_state` yeniden kontrol edilir, değişmişse kart atlanır ve tur sayacına girmez. `LlmError` ve geçersiz verdict'te kartın değişikliği geri alınır (open kartın sahipliği de), `attempts` artmaz, "llm_error" olayı yazılır, tur sürer; hatalı kart tur sınırına (3) sayılır. Mentor `criteria`'sında kartın kontrol listesine ait olmayan `item_id`'ler yok sayılır. `AgentBoards::DemoRun`: demo panoyu kurar, bir tur çalıştırır, her kartın başlığını, `agent_state`'ini ve son olayını yazdırır (`DemoRun.tick` aynı panoda bir tur daha). Prompt'ta boş açıklama satırı atlanır.
- Eklenen/değişen dosyalar: app/services/{groq_llm,llm_error,fake_llm}.rb, app/services/agent_boards/{tick,prompts,llm_factory,demo_run}.rb, test/test_helper.rb (`stub_class_method`), test/services/groq_llm_test.rb, test/services/agent_boards/{tick_resilience,llm_factory,demo_run}_test.rb
- Testler: 81 test, 346 doğrulama, 0 hata (56 eski + 25 yeni; RuboCop ve Brakeman temiz). Testler ağa çıkmıyor.
- Commit mesajı: Adım 2: Groq LLM istemcisi, satır kilidiyle Tick, LLM hatası olayı ve demo runner
- Açık kalanlar / notlar: (1) Gerçek Groq çağrısı henüz denenmedi (anahtar ajanın ortamında yok); `reasoning_effort: "low"` ile ilk elle denemede 400 alınırsa alan kaldırılacak ve buraya not düşülecek. (2) Minitest 6'da `minitest/mock` ayrı gem olduğu için gem eklememek adına `test_helper.rb`'ye küçük bir `stub_class_method` yardımcısı yazıldı; Net::HTTP bununla taklit ediliyor. (3) Eşzamanlılık testi, testlerin tek bağlantılı işlem içinde çalışması yüzünden kilidin gerçek bekleme davranışını değil, kilit içindeki durum yeniden kontrolünü doğruluyor (eski anlık görüntüyle ilerleme atlanıyor, LLM çağrılmıyor). (4) `write` için `finish_reason: "length"` hata sayılmıyor; kesik metni mentor değerlendirir. (5) Kilit LLM çağrısını kapsadığı için bir işlem ve bağlantı çağrı süresince (en fazla ~25 sn) açık kalır. (6) Runner komutu: `ruby bin/rails runner "AgentBoards::DemoRun.call"` (simülasyon modunda dev veritabanında denendi: 2 kart ilerledi).
- Ceyda'nın süresi:

## Adım 2b — Model düzeltmesi
- Tarih/saat: 2026-10-24 18:39:27 +03:00
- Ne yapıldı: Groq'ta `llama-3.1-8b-instant` kalktığı (HTTP 404 model_not_found) için model adları ENV'e taşındı: `AgentBoards::Models` (`GROQ_WORKER_MODEL`, varsayılan `openai/gpt-oss-20b`; `GROQ_MENTOR_MODEL`, varsayılan `openai/gpt-oss-120b`). `DemoSeeder` ajanların `model` alanını buradan dolduruyor; `app/` altında varsayılan adlar yalnızca `models.rb`'de, `GroqLlm`'de yalnızca `openai/gpt-oss` ön ek kontrolü (reasoning_effort için) kaldı. `GroqLlm#write` artık gpt-oss modellerine `reasoning_effort: "low"` gönderiyor ve `max_tokens` 800; boş cevap (akıl yürütmede token bitmesi) `LlmError`. `review` aynen: `max_tokens` 1000, `finish_reason: "length"` hata. `Tick#call` artık `Tick::Summary(advanced, errors)` döner; `to_s` örneği "1 kart ilerledi, 2 LLM hatası"; hatalı kart tur sınırına (3) sayılır ama "ilerledi"ye girmez. `DemoRun` çıktısı "Tur bitti: 1 kart ilerledi, 2 LLM hatası." biçiminde. AGENTS.md'ye kural eklendi: adım commit'inden sonra test/rubocop/brakeman temizse `git push` (force push asla; başarısızsa dur ve bildir).
- Eklenen/değişen dosyalar: AGENTS.md, app/services/groq_llm.rb, app/services/agent_boards/{models,demo_seeder,tick,demo_run}.rb, test/services/groq_llm_test.rb, test/services/agent_boards/{models,demo_seeder,tick_resilience}_test.rb
- Testler: 85 test, 361 doğrulama, 0 hata (RuboCop ve Brakeman temiz)
- Commit mesajı: Adım 2b: Model adları ENV'den (gpt-oss), write için reasoning_effort ve tur özetinde LLM hatası sayısı
- Açık kalanlar / notlar: Gerçek Groq denemesi Ceyda'da; sonucu bekleniyor. Dev veritabanındaki eski demo panosunda ajanların model alanı hâlâ `llama-3.1-8b-instant` olabilir; `DemoRun.call` (ya da seeder) panoyu sıfırlayıp yeniden kurduğu için düzelir, `DemoRun.tick` düzeltmez. Bu commit ile Adım 2 ve 2b uzak depoya gitti (Adım 0 ve 1 daha önce push edilmişti).
- Ceyda'nın süresi:

## Adım 2c — Uydurmaya karşı önlemler ve ağ hatasında yeniden deneme
- Tarih/saat: 2026-10-24 19:11:23 +03:00
- Ne yapıldı: Gerçek Groq denemesinde dört kartın hepsi ilk denemede pass aldı ve bilgisi eksik kartta işçi ürün bilgisini uydurup mentordan onay aldı; bunlara karşı üç katman eklendi. (1) İşçi: prompt'a "bilgi kartta yoksa uydurma, çıktıyı 'BİLGİ EKSİK: ' ile başlat ve soruyu yaz" talimatı; `Tick`, böyle bir teslimi (büyük/küçük harf, ASCII I, baştaki işaretler tolere edilir; yalnızca metnin başında) mentora göndermeden `needs_human` yapar, soruyu karta `feedback` olarak ve `question` olayına ("Ajan insana soru sordu: ...") yazar. (2) Mentor: prompt ve sistem rolü daha katı (her kriteri harfiyen kontrol et, kelime/madde say, emin değilsen met=false, kartta olmayan bilgi uydurmadır → revise, görev karttaki bilgiyle yapılamıyorsa escalate); `reasoning_effort` "medium", `max_tokens` 2000 (işçi: low, 800). (3) Kod kuralı: mentor pass dese bile geçerli kriterlerden biri met=false ise sonuç revise'a çevrilir (`overridden_from: "pass"`, feedback boşsa karşılanmayan kriterler yazılır); `attempts >= 2` ise gözcü kuralıyla insana devredilir. `GroqLlm`: ağ hatalarında (DNS, bağlantı, zaman aşımı, EHOSTUNREACH/ENETUNREACH dahil) 1 sn beklemeyle tek yeniden deneme; HTTP hata kodlarında (4xx/5xx) yeniden deneme yok. `DemoSeeder`: eksik bilgili kartın açıklamasında ürün bilgisi yok ve kriterlerine uydurmayı yasaklayan madde eklendi; kulaklık ve termos kartlarına gerçek ürün bilgisi ve kolay kaçırılan sayılabilir kriterler eklendi (tam olarak 3 madde, her madde en fazla 6 kelime, "harika" hiç geçmesin; tam olarak 2 cümle, 25-30 kelime). `FakeLlm` varsayılan senaryosu yeni akışa uydu: eksik bilgili kartta işçi ilk denemede "BİLGİ EKSİK:" yazar (mentorun özel escalate dalı kalktı). Adım 2b kaydındaki "ilk kez push edildi" notu düzeltildi.
- Eklenen/değişen dosyalar: app/services/groq_llm.rb, app/services/fake_llm.rb, app/services/agent_boards/{tick,prompts,demo_seeder}.rb, test/services/groq_llm_test.rb, test/services/agent_boards/{tick_quality,demo_seeder}_test.rb, ILERLEME.md
- Testler: 103 test, 449 doğrulama, 0 hata (RuboCop ve Brakeman temiz)
- Commit mesajı: Adım 2c: BİLGİ EKSİK çıktısı, katı mentor, met=false kuralı, ağ hatasında tek yeniden deneme
- Açık kalanlar / notlar: Gerçek Groq denemesi Ceyda'da; sonucu bekleniyor (özellikle: eksik bilgili kart needs_human oluyor mu, kartlardan en az biri revise görüyor mu). Mentor bazı kriterleri hiç listelemeden pass derse kod kuralı bunu yakalamıyor (yalnızca met=false olanları yakalar). Yeniden deneme ve medium akıl yürütme bir kartta kilidin tutulma süresini ve token kullanımını artırır; ücretsiz kotada 429 görülürse llm_error olarak düşer.
- Ceyda'nın süresi:
