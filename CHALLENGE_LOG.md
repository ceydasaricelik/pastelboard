# CHALLENGE_LOG

## Başlangıç noktası

Trello'dan ilham alan **PastelBoard**: Kanban panosu, sürükle-bırak ve süresi geçen kartları otomatik "Gecikenler" listesine taşıyan SLA eskalasyonu.

- Canlı URL: https://pastelboard-web.onrender.com
- Geçen haftanın son commit'i: https://github.com/ceydasaricelik/pastelboard/commit/27d0230
- Bu ürüne kim, neden para ödüyor? [CEYDA YAZACAK]

## Acı

Ajanlarla çalışan ekiplerde ajan görevden sapar, adım tekrarlar, yanlış çıktıyı bitmiş gibi teslim eder; kalabalık panoda bu fark edilmez.

Kaynak: [Why Do Multi-Agent LLM Systems Fail? (MAST)](https://arxiv.org/abs/2503.13657) — çoklu-ajan sistemlerinde 14 hata türü.

**Önceki acı (geçen hafta, Trello):**
- G2, Aralık 2025: *"teslim tarihi olan kartlar için bildirim vermeli"* — [G2 yorumu](https://www.g2.com/survey_responses/trello-review-4563927)
- G2: panolar büyüdükçe karmaşıklaşıyor ve gezinmek zorlaşıyor — [G2 yorumu](https://www.g2.com/survey_responses/trello-review-4834123)
- Capterra: tutarsız bildirimler — [Capterra Trello yorumları](https://www.capterra.com/p/211559/Trello/reviews/Capterra___6168793/)
- Chrome Web Store: geciken kartların listenin altına gömüldüğünü söyleyen üçüncü taraf eklenti — [eklenti sayfası](https://chrome.google.com/webstore/detail/njfjeliolopojmdcpaoncmdkoencgepf)

## Bu haftanın vaadi

Geçen hafta insanlar için SLA eskalasyonlu bir Kanban panosu vardı. Bu hafta panonun işçilerini ajanlara çeviriyorum: işçi ajanlar havuzdan iş alacak, mentor ajan teslimleri kabul kriterlerine göre inceleyip geri bildirim ve ders verecek, iki denemede düzelmeyen ya da döngüye giren kart insana devredilecek. Hepsi testlerle ve canlı demoda gösterilecek.

## Yapılanlar ve kanıt

Güncel durum: **139 test, 672 doğrulama, 0 hata**; RuboCop, Brakeman, bundler-audit ve importmap audit temiz. Her adımın ayrıntısı [ILERLEME.md](ILERLEME.md)'de. Testlerin hiçbiri ağa çıkmaz: LLM çağrıları `FakeLlm` ile, `Net::HTTP` ise stub ile taklit edilir.

| Adım | Ne yapıldı | Commit | Test |
| --- | --- | --- | --- |
| 0 — Hazırlık | `AGENT.md` → `AGENTS.md`, `CLAUDE.md`, `ILERLEME.md`, bu dosya; ajan çalışma kuralları. Özellik kodu yok. | [06ae42a](https://github.com/ceydasaricelik/pastelboard/commit/06ae42a) | 34 |
| 1 — Çekirdek | Ajan panosunun veri modeli, `Tick` servisi (işçi alır, mentor pass/revise/escalate der, gözcü kuralları), `FakeLlm`, insan aksiyonları ve `DemoSeeder`. Kartın tüm geçmişi `AgentEvent`'te. | [bda5613](https://github.com/ceydasaricelik/pastelboard/commit/bda5613) | 56 |
| 2 — Gerçek LLM | `GroqLlm` (Net::HTTP, strict `json_schema`), satır kilidiyle ilerleyen `Tick`, LLM hatasında kartın yerinde kalıp `llm_error` olayı yazması, `DemoRun` komutu. | [cfe03a8](https://github.com/ceydasaricelik/pastelboard/commit/cfe03a8) | 81 |
| 2b — Model düzeltmesi | Groq'ta `llama-3.1-8b-instant` kalktığı için (HTTP 404) model adları ENV'e taşındı (`gpt-oss-20b` / `gpt-oss-120b`); tur özeti hatalı kartı "ilerledi" saymıyor. | [b5d5a4b](https://github.com/ceydasaricelik/pastelboard/commit/b5d5a4b) | 85 |
| 2c — Uydurmaya karşı | İşçi için "BİLGİ EKSİK:" akışı, katı mentor promptu, mentor pass dese bile `met=false` kriter varsa revise kuralı, ağ hatasında tek yeniden deneme. | [07ccb67](https://github.com/ceydasaricelik/pastelboard/commit/07ccb67) | 103 |
| 2d — Ekip rehberi | Panonun `guidelines` alanı yalnızca mentor promptunda; mentor `guideline_violations` döndürür, ihlal varsa pass revise'a çevrilir; ders işçinin ders defterine girer. | [7dcfdc7](https://github.com/ceydasaricelik/pastelboard/commit/7dcfdc7) | 112 |
| 3 — Arayüz | Ajan panosu ekranı: tur butonu, canlı görev ekleme, kart detayı (çıktı, ✓/✗, rehber ihlali, zaman çizelgesi), ipucu ver / onayla, ajanlar ve ders defteri, demo panoyu kur/sıfırla. İnsan panosu değişmedi. | [7e1501d](https://github.com/ceydasaricelik/pastelboard/commit/7e1501d) | 134 |
| 4 — Belgeler | Bu dosya ve README'deki "Ajan panosu" bölümü. | [6d09809](https://github.com/ceydasaricelik/pastelboard/commit/6d09809) | 134 |
| 5 — CI düzeltmesi | GitHub CI'daki bundler-audit adımı `crass` 1.0.7 için GHSA-pq4g-8rxf-4g29 ilanını yakaladı; `crass` 1.0.8'e güncellendi, CI'ın tüm adımları yerelde temiz çalıştı. | [16e6332](https://github.com/ceydasaricelik/pastelboard/commit/16e6332) | 134 |
| 6 — Prompt ve arayüz | İşçi promptuna "mentor kuralları kesindir, BİLGİ EKSİK yalnızca eksik içerik için" eklendi; mentor alanları Türkçe; kart detayında "Mentor geri bildirimi", "Ajanın sorusu" ve "İnsan ipucu" ayrı başlıklarda; `db:seed` tekrarının kopya üretmediği testle doğrulandı; README'ye Windows komutları. | [30af5cd](https://github.com/ceydasaricelik/pastelboard/commit/30af5cd) | 139 |
| 7 — Son hali | Bu dosya: gerçek deneme kanıtları, CI notu, deploy ve fark katmanı bölümleri. | (bu commit) | 139 |

### CI teslimden önce yeni bir güvenlik ilanı yakaladı

Teslimden önce GitHub Actions kırmızıya döndü: `bundler-audit` adımı `crass` 1.0.7'de [GHSA-pq4g-8rxf-4g29](https://github.com/advisories/GHSA-pq4g-8rxf-4g29) açığını buldu (çözüm: `>= 1.0.8`). `bundle update crass --conservative` ile yalnızca bu gem güncellendi (`Gemfile.lock`'ta iki satır), `ci.yml`'deki tüm adımlar (bundler-audit, importmap audit, RuboCop, Brakeman, testler) yerelde temiz çalıştı ve düzeltme push'landı (Adım 5). CI'ın görevi tam olarak buydu: kod değişmediği hâlde dışarıdan gelen yeni bir ilanı teslimden önce yakaladı.

### Gerçek denemelerden iki bulgu

**a) İşçi eksik bilgiyi uydurdu, mentor onayladı.** İlk başarılı gerçek Groq denemesinde (ilk deneme model 404 verdi) bilgisi eksik karta ("Yeni ürün için açıklama metni") işçi ürün adını ve özelliklerini kendisi uydurdu ve mentor bunu onayladı. FakeLlm'le kurulan senaryoda bu hiç görünmemişti: simülasyon modu mentorun kör noktasını göstermez. Düzeltme üç katmanlı: işçi, bilgi kartta yoksa "BİLGİ EKSİK:" ile insana soru yazar ve kart doğrudan insana devredilir; mentor promptu kelime ve madde saymayı, kartta olmayan bilginin uydurma sayılmasını ister; kod tarafında mentor pass dese bile `met=false` kriter varsa sonuç revise'a çevrilir. "BİLGİ EKSİK" akışı bir sonraki gerçek denemede çalıştı (kart `needs_human` oldu, ajan insana soru sordu). `met=false` kuralı yalnızca testlerle doğrulandı; gerçek denemede bu kurala düşen bir durum görmedik.

**b) Güçlü model her kartı ilk denemede geçirdi, mentorluk görünmüyordu.** `gpt-oss` modelleri üç kartı da ilk denemede pass aldı; düzeltme (rework) akışı hiç görünmedi, yani demoda "mentor geri bildirim ve ders verir" vaadi gösterilemiyordu. Çözüm modeli zayıflatmak değil, bilgi asimetrisi oldu: panonun ekip rehberini (müşteriye "sen" de, ünlem kullanma, her metin "PastelShop" ile bitsin) yalnızca mentor bilir, işçi görmez. İşçi kuralı bilemeyeceği için ilk teslimde ihlal eder, mentor `guideline_violations` ile geri gönderir ve kuralı tek cümlelik bir dersle işçinin ders defterine yazar; sonraki teslimde işçi bunu uygular. Düzeltme önce FakeLlm testleriyle doğrulandı (rehber yalnızca mentor promptunda, ders sonraki işçi promptuna giriyor, ihlalli pass revise'a dönüyor), sonra gerçek Groq ile denendi.

**Gerçek Groq denemesi (yerel, demo pano, `gpt-oss-20b` işçi / `gpt-oss-120b` mentor):**

- **Kulaklık kartı:** mentor düzeltmesinden sonra Done'a geçti; yani düzeltme (rework) akışı gerçek modelle de görüldü.
- **Termos kartı:** tüm kabul kriterleri ✓ olmasına rağmen ekip rehberi ihlali yüzünden iki kez revise aldı ve insana devredildi. Kriter listesi yeşil olduğu hâlde mentorun rehberi uygulaması, bilgi asimetrisinin gerçekten çalıştığını gösteriyor. **Dürüst not:** işçi dersi iki denemede uygulayamadı; kart Done olmadı, insana düştü. Bu yüzden Adım 6'da işçi promptuna "mentor geri bildirimindeki ve ders defterindeki kurallar kesindir, uygula" cümlesi eklendi. Bu değişiklik gerçek Groq'ta henüz denenmedi.
- **Eksik bilgili kart:** ajan bilgiyi uydurmadı, insana soru sordu; ipucu verilince kart "Düzeltmede"ye döndü.
- **Tur süresi:** 1–7 sn. Kart sınırı 3 olarak kaldı (`AGENT_ROUND_LIMIT` ile ayarlanır).
- Arayüz kontrolü ve insan panosu / sürükle-bırak yerelde çalıştı. Render'da `6d09809` canlıydı (sonraki commit'lerin canlıya çıkışı ayrıca doğrulanmadı).

Ayrıca gerçek denemelerde bir kez DNS hatası (`Socket::ResolutionError`) görüldü: kart yerinde kaldı, `llm_error` olayı yazıldı, sonraki turda düzeldi. Bu, tek otomatik yeniden deneme eklemesine yol açtı.

### 3 dakikalık canlı demo senaryosu

Canlı adres: https://pastelboard-web.onrender.com. Ücretsiz plan uyuyabilir; demodan bir dakika önce adresi açıp uyandır. Canlıda `GROQ_API_KEY` ve `DEMO_MODE=1` ayarlı olmalı (anahtar yoksa pano "simülasyon modu"nda çalışır).

1. **0:00 — Demo panoyu kur.** Panolar sayfasında "Demo ajan panosu oluştur/sıfırla"ya bas. Panoda üstteki mod etiketine ("Groq · openai/gpt-oss-20b / openai/gpt-oss-120b"), sağdaki "Ekip rehberi" kutusuna (işçiler görmez) ve boş ders defterlerine dikkat çek. Dört kart Havuz'da.
2. **0:30 — İlk tur.** "▶ Bir tur çalıştır": buton "Ajanlar çalışıyor…" yazar. İki işçi birer kart alır; kartlar "Mentor incelemesinde"ye geçer. Tur özeti üstte çıkar.
3. **1:00 — Düzeltme ve ders.** İkinci tur: mentor inceler. Rehbere aykırı bir kart "Düzeltmede"ye döner. Kartı aç: kriter bazında ✓/✗, kırmızı "Ekip rehberi ihlali" kutusu, mentor geri bildirimi. Sağdaki "Ajanlar"da ilgili işçinin ders defterine yeni bir ders düştü. Üçüncü tur: işçi dersle düzeltir; kulaklık kartı Done'a gider. Termos kartı gerçek denemede dersi iki denemede uygulayamayıp "İnsana devredildi"ye düştü; bu da anlatının parçası: düzelmeyen kart insana gider.
4. **1:45 — İnsana soru.** Bilgisi eksik kart ("Yeni ürün için açıklama metni") "İnsana devredildi" kolonunda kırmızı. Kartı aç: "Ajan insana soru sordu". İşçi bilgiyi uydurmadı.
5. **2:15 — İpucu ver.** Metin kutusuna ürün bilgisini yaz (ör. "Aurora masa lambası, 12 saat pil, 399 TL"), "İpucu ver ve geri gönder"e bas. Kart "Düzeltmede"ye döner; bir tur daha çalıştır, işçi ipucuyla yazar.
6. **2:40 — Canlı görev.** Havuz'da "+ Görev ekle": başlık, açıklama ve her satıra bir kabul kriteri yaz, ekle ve bir tur çalıştır. Ajanlar kartı alır.
7. **3:00 — Kanıt.** Herhangi bir kartın zaman çizelgesini göster: kim, ne yaptı, ne zaman (varsa LLM hataları da orada).

Gerçek model beklenmedik davranırsa (ör. rehberi ilk seferde tutturursa) anlatı aynı kalır: zaman çizelgesi ve ders defteri neyin olduğunu gösterir. Tur başına en fazla 3 kart ilerler, dört kartı bitirmek için birkaç tur gerekir.

### Vaat edip yapamadıklarım

- **Termos kartı Done olmadı.** Gerçek denemede işçi mentorun dersini iki denemede uygulayamadı ve kart insana devredildi. Adım 6'daki prompt düzeltmesi bunu hedefliyor ama gerçek modelle henüz denenmedi.
- **Tur senkron çalışır:** tur istek içinde yürür; gerçek turlar 1–7 sn sürdü ama çok uzarsa Render'da zaman aşımı riski var.
- **Canlıda son commit'ler doğrulanmadı:** Render'da `6d09809` canlıydı ve çalıştı; Adım 5–7'nin canlıya çıkışı ayrıca kontrol edilmedi. GitHub CI'ın bu commit'lerden sonraki yeşil sonucu Actions sayfasından görülmeli.
- **Ajanlar kendiliğinden çalışmıyor:** işler yalnızca "Bir tur çalıştır" butonuyla (ya da `DemoRun` komutuyla) ilerler; zamanlanmış otomatik tur yok.
- **Ekip rehberi için düzenleme arayüzü yok;** rehber şimdilik yalnızca demo seeder'ından geliyor.
- **Mentor bazı kriterleri hiç listelemeden pass derse** `met=false` kuralı bunu yakalamaz.

### Deploy ve coding agent kuralları

**Render.** Canlı adres https://pastelboard-web.onrender.com. Build komutu:

```
bundle install && bin/rails assets:precompile && bin/rails db:migrate && bin/rails db:seed
```

`db:migrate` yeni ajan tablolarını ve kolonlarını (`boards.kind`, `members.kind/role/model/lessons`, `cards.agent_state` vb., `agent_events`, `boards.guidelines`) canlıya taşır. `db:seed` her deploy'da çalışır; seed yalnızca insan panosunu `find_or_create_by` ile kurduğu ve ajan panosuna dokunmadığı için tekrar çalışınca kopya pano, üye veya kart oluşmaz (Adım 6'da `test/integration/seeds_test.rb` ile doğrulandı). Start komutu repoda tutulmuyor, Render panelinde.

**Ortam değişkenleri.**

| Değişken | Ne için |
| --- | --- |
| `DATABASE_URL`, `RAILS_MASTER_KEY` | Render'ın tek PostgreSQL'i ve Rails sırları |
| `SOLID_QUEUE_IN_PUMA=true` | Solid Queue arka plan görevleri web sunucusunun (Puma) içinde çalışır |
| `GROQ_API_KEY` | Gizli. Yoksa ajan panosu "simülasyon modu"nda (`FakeLlm`) çalışır |
| `DEMO_MODE=1` | Demo pano butonları ve "⏩ 2 gün ileri sar" görünür ve çalışır |
| `GROQ_WORKER_MODEL`, `GROQ_MENTOR_MODEL` | İsteğe bağlı; varsayılan `openai/gpt-oss-20b` ve `openai/gpt-oss-120b` |
| `AGENT_ROUND_LIMIT` | İsteğe bağlı; tur başına kart sınırı, varsayılan 3 (1–10) |

**Tek veritabanı.** Rails 8 production'da dört veritabanı bekler (ana, cache, queue, cable); Render ücretsiz planı tek PostgreSQL veriyor. Bu yüzden Solid Queue tabloları migration ile ana veritabanına taşındı, önbellek bellek içinde, Action Cable `async`, Solid Queue Puma içinde (`SOLID_QUEUE_IN_PUMA`). Ajan panosu bu düzene ek servis getirmedi: `GroqLlm` yalnızca `Net::HTTP` kullanır, yeni gem yok.

**Coding agent kuralları.** Claude Code oturum başında kökteki `CLAUDE.md`'yi okur; dosyanın tek satırı `@AGENTS.md`, yani asıl kurallar `AGENTS.md`'de tek yerde tutulur (başka bir agent de aynı dosyayı okur). `AGENTS.md`'nin sonundaki "Ajan panosu çalışma kuralları" şunları dayatır: oturuma `ILERLEME.md`'nin son kaydını okuyarak başla; Windows'ta `ruby bin/rails ...`; her adımın sonunda test, RuboCop ve Brakeman temiz olmadan adım bitmiş sayılmaz; testler ağa çıkmaz (LLM = `FakeLlm`); API anahtarı koda, commit'e veya log'a girmez, yalnızca `ENV["GROQ_API_KEY"]` okunur; insan panosunun davranışı bozulmaz; her adım tek commit ("Adım N: ..."), temizse push, force push yok. Agent özerk çalışır ama yalnızca veri silme, yeni gem/dış servis, insan panosu davranışı değişikliği ve 3 denemede çözülmeyen hata için durup sorar.

**İlerleme kaydı.** Her adım sonunda `ILERLEME.md`'ye aynı şablonla kayıt düşülür (tarih/saat, ne yapıldı, dosyalar, test sayısı, commit mesajı, açık kalanlar, Ceyda'nın süresi). Yeni oturum bu dosyanın son kaydından devam eder; bu dosya aynı zamanda aşağıdaki agent zamanının kaynağıdır.

### Fark katmanı

**Agent-first.** Geçen haftaki panoda kartları insanlar sürüklüyordu. Bu hafta ajan panosunda sürükle-bırak yok: kartları ajanlar taşır. İşçi havuzdan atomik bir `UPDATE ... WHERE assignee_id IS NULL` ile iş alır, teslimi "Mentor incelemesinde"ye koyar, mentor kabul eder ya da "Düzeltmede"ye geri gönderir; insan yalnızca devredilen kartta ipucu verir veya onaylar. Kartın bütün geçmişi `AgentEvent` zaman çizelgesindedir.

**LLM zekâsı, anahtar kelime değil.** Mentor `openai/gpt-oss-120b`'dir ve her kriter için `{ item_id, met, reason }` ile verdict (`pass`, `revise`, `escalate`), `feedback`, `lesson` ve `guideline_violations` döndürür. Çıktı Groq'un strict `json_schema`'sıyla tipli JSON'dur; geçersiz yanıt kartı değiştirmez, `llm_error` olarak kaydedilir. Karar mentorun, **politika kodun**: mentor pass dese bile `met=false` kriter ya da rehber ihlali varsa kod sonucu revise'a çevirir; iki denemede düzelmeyen ya da aynı çıktıyı tekrar eden kart insana devredilir; "BİLGİ EKSİK:" soruları doğrudan insana gider. Modelin ürettiği ders işçinin ders defterine yazılır ve sonraki işçi promptuna girer.

**Slop testi.** Benimkinde kartları insanlar değil ajanlar taşıyor; raydan çıkan ajanı mentor ajan yakalayıp düzeltiyor, düzelmezse insana devrediyor ve mentorun dersi işçinin ders defterine yazılıyor.

## Zaman

İnsan zamanı: [CEYDA YAZACAK]

Agent zamanı: **≈ 4 saat 28 dakika** (268 dk; duvar saati). Hesap: `ILERLEME.md`'deki ilk kayıt (Adım 0, 24 Ekim 2026 16:27:39) ile son kayıt (Adım 7, 20:55:38) arasındaki fark. Bu süre Ceyda'nın onay beklemelerini, gerçek Groq denemelerini ve yerel arayüz kontrolünü de içerir; saf agent çalışma süresi bundan kısadır.

| Aralık | Dakika |
| --- | --- |
| Adım 0 → 1 (16:27 → 17:04) | 36 |
| Adım 1 → 2 (17:04 → 17:32) | 29 |
| Adım 2 → 2b (17:32 → 18:39), arada Ceyda'nın ilk gerçek Groq denemesi (model 404) | 67 |
| Adım 2b → 2c (18:39 → 19:11), arada ikinci gerçek deneme (uydurma bulgusu) | 32 |
| Adım 2c → 2d (19:11 → 19:32), arada üçüncü gerçek deneme (BİLGİ EKSİK çalıştı, rework görünmedi) | 21 |
| Adım 2d → 3 (19:32 → 19:39) | 7 |
| Adım 3 → 4 (19:39 → 19:42) | 3 |
| Adım 4 → 5 (19:42 → 20:52), arada Ceyda'nın gerçek Groq denemeleri ve arayüz kontrolü | 69 |
| Adım 5 → 6 (20:52 → 20:55) | 3 |
| Adım 6 → 7 (20:55 → 20:55) | 1 |

### İlk prompt

````
Bu hafta PastelBoard'a "ajan panosu" ekleyeceğiz: işçi ajanlar havuzdan iş alacak, mentor ajan teslimleri kabul kriterlerine göre inceleyip geri bildirim ve ders verecek, düzelmeyen kart insana devredilecek. Bu adımda özellik kodu YAZMA, sadece çalışma düzenini kur. Bu adım için plan onayı beklemeden uygula.

1. PROJE_DURUMU.md, README.md ve AGENT.md dosyalarını oku.
2. `git mv AGENT.md AGENTS.md` yap. Kökte tek satırı `@AGENTS.md` olan bir CLAUDE.md oluştur.
3. AGENTS.md'nin sonuna "Ajan panosu çalışma kuralları" bölümü ekle:
   - Yeni bir oturuma başlarken önce ILERLEME.md'nin son kaydını oku.
   - Kod yazmadan önce kısa bir plan çıkar ve onayımı bekle.
   - Testlerden önce PostgreSQL kapalıysa PROJE_DURUMU.md bölüm 8'deki komutla aç.
   - Her adımın sonunda `bin/rails test`, `bin/rubocop`, `bin/brakeman --no-pager` çalıştır; hepsi temiz olmadan adım bitmiş sayılmaz.
   - Testler asla ağa çıkmaz; LLM çağrıları testlerde FakeLlm ile yapılır.
   - API anahtarı koda, commit'e veya log dosyalarına yazılmaz; yalnızca ENV["GROQ_API_KEY"] okunur.
   - Mevcut insan panosunun davranışı ve testleri bozulmaz; değişiklikler eklemeli yapılır.
   - Her adımın sonunda ILERLEME.md'ye kayıt ekle, sonra tek commit at. Commit mesajı Türkçe ve "Adım N: ..." ile başlar.
4. ILERLEME.md oluştur. Kısa bir açıklama ve şu kayıt şablonu:
   ## Adım N — Başlık
   - Tarih/saat: (date komutuyla)
   - Ne yapıldı:
   - Eklenen/değişen dosyalar:
   - Testler: X test, Y doğrulama, 0 hata
   - Commit mesajı:
   - Açık kalanlar / notlar:
   - Ceyda'nın süresi: (boş bırak)
   İlk kayıt olarak "Adım 0 — Hazırlık"ı yaz.
5. Kökte CHALLENGE_LOG.md oluştur. Başlıklar tam olarak: "# CHALLENGE_LOG", "## Başlangıç noktası", "## Acı", "## Bu haftanın vaadi", "## Yapılanlar ve kanıt", "## Zaman", "## Karar".
   - Başlangıç noktası: Trello'dan ilham alan PastelBoard, canlı URL https://pastelboard-web.onrender.com, geçen haftanın son commit'i https://github.com/ceydasaricelik/pastelboard/commit/27d0230. "Bu ürüne kim, neden para ödüyor?" için [CEYDA YAZACAK] bırak.
   - Acı: Ajanlarla çalışan ekiplerde ajan görevden sapar, adım tekrarlar, yanlış çıktıyı bitmiş gibi teslim eder; kalabalık panoda bu fark edilmez. Kaynak: https://arxiv.org/abs/2503.13657 (MAST, çoklu-ajan sistemlerinde 14 hata türü). README'deki geçen haftanın Trello şikâyet linklerini de "önceki acı" olarak aktar.
   - Bu haftanın vaadi: "Geçen hafta insanlar için SLA eskalasyonlu bir Kanban panosu vardı. Bu hafta panonun işçilerini ajanlara çeviriyorum: işçi ajanlar havuzdan iş alacak, mentor ajan teslimleri kabul kriterlerine göre inceleyip geri bildirim ve ders verecek, iki denemede düzelmeyen ya da döngüye giren kart insana devredilecek. Hepsi testlerle ve canlı demoda gösterilecek."
   - Yapılanlar ve kanıt: "(ILERLEME.md'den doldurulacak)"
   - Zaman: "İnsan zamanı: [CEYDA YAZACAK]", "Agent zamanı: (ILERLEME.md'den)", ardından "İlk prompt" alt başlığı. Bu mesajın tamamını o başlığın altına olduğu gibi, kod bloğu içinde kopyala.
   - Karar: [CEYDA YAZACAK] bırak.
6. Testleri çalıştır (mevcut 34 test geçmeli) ve commit at.
````

## Karar

[CEYDA YAZACAK]
