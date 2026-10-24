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

Güncel durum: **134 test, 651 doğrulama, 0 hata**; RuboCop ve Brakeman temiz. Her adımın ayrıntısı [ILERLEME.md](ILERLEME.md)'de. Testlerin hiçbiri ağa çıkmaz: LLM çağrıları `FakeLlm` ile, `Net::HTTP` ise stub ile taklit edilir.

| Adım | Ne yapıldı | Commit | Test |
| --- | --- | --- | --- |
| 0 — Hazırlık | `AGENT.md` → `AGENTS.md`, `CLAUDE.md`, `ILERLEME.md`, bu dosya; ajan çalışma kuralları. Özellik kodu yok. | [06ae42a](https://github.com/ceydasaricelik/pastelboard/commit/06ae42a) | 34 |
| 1 — Çekirdek | Ajan panosunun veri modeli, `Tick` servisi (işçi alır, mentor pass/revise/escalate der, gözcü kuralları), `FakeLlm`, insan aksiyonları ve `DemoSeeder`. Kartın tüm geçmişi `AgentEvent`'te. | [bda5613](https://github.com/ceydasaricelik/pastelboard/commit/bda5613) | 56 |
| 2 — Gerçek LLM | `GroqLlm` (Net::HTTP, strict `json_schema`), satır kilidiyle ilerleyen `Tick`, LLM hatasında kartın yerinde kalıp `llm_error` olayı yazması, `DemoRun` komutu. | [cfe03a8](https://github.com/ceydasaricelik/pastelboard/commit/cfe03a8) | 81 |
| 2b — Model düzeltmesi | Groq'ta `llama-3.1-8b-instant` kalktığı için (HTTP 404) model adları ENV'e taşındı (`gpt-oss-20b` / `gpt-oss-120b`); tur özeti hatalı kartı "ilerledi" saymıyor. | [b5d5a4b](https://github.com/ceydasaricelik/pastelboard/commit/b5d5a4b) | 85 |
| 2c — Uydurmaya karşı | İşçi için "BİLGİ EKSİK:" akışı, katı mentor promptu, mentor pass dese bile `met=false` kriter varsa revise kuralı, ağ hatasında tek yeniden deneme. | [07ccb67](https://github.com/ceydasaricelik/pastelboard/commit/07ccb67) | 103 |
| 2d — Ekip rehberi | Panonun `guidelines` alanı yalnızca mentor promptunda; mentor `guideline_violations` döndürür, ihlal varsa pass revise'a çevrilir; ders işçinin ders defterine girer. | [7dcfdc7](https://github.com/ceydasaricelik/pastelboard/commit/7dcfdc7) | 112 |
| 3 — Arayüz | Ajan panosu ekranı: tur butonu, canlı görev ekleme, kart detayı (çıktı, ✓/✗, rehber ihlali, zaman çizelgesi), ipucu ver / onayla, ajanlar ve ders defteri, demo panoyu kur/sıfırla. İnsan panosu değişmedi. | [7e1501d](https://github.com/ceydasaricelik/pastelboard/commit/7e1501d) | 134 |
| 4 — Belgeler | Bu dosya ve README'deki "Ajan panosu" bölümü. | (bu commit) | 134 |

### Gerçek denemelerden iki bulgu

**a) İşçi eksik bilgiyi uydurdu, mentor onayladı.** İlk başarılı gerçek Groq denemesinde (ilk deneme model 404 verdi) bilgisi eksik karta ("Yeni ürün için açıklama metni") işçi ürün adını ve özelliklerini kendisi uydurdu ve mentor bunu onayladı. FakeLlm'le kurulan senaryoda bu hiç görünmemişti: simülasyon modu mentorun kör noktasını göstermez. Düzeltme üç katmanlı: işçi, bilgi kartta yoksa "BİLGİ EKSİK:" ile insana soru yazar ve kart doğrudan insana devredilir; mentor promptu kelime ve madde saymayı, kartta olmayan bilginin uydurma sayılmasını ister; kod tarafında mentor pass dese bile `met=false` kriter varsa sonuç revise'a çevrilir. "BİLGİ EKSİK" akışı bir sonraki gerçek denemede çalıştı (kart `needs_human` oldu, ajan insana soru sordu). `met=false` kuralı yalnızca testlerle doğrulandı; gerçek denemede bu kurala düşen bir durum görmedik.

**b) Güçlü model her kartı ilk denemede geçirdi, mentorluk görünmüyordu.** `gpt-oss` modelleri üç kartı da ilk denemede pass aldı; düzeltme (rework) akışı hiç görünmedi, yani demoda "mentor geri bildirim ve ders verir" vaadi gösterilemiyordu. Çözüm modeli zayıflatmak değil, bilgi asimetrisi oldu: panonun ekip rehberini (müşteriye "sen" de, ünlem kullanma, her metin "PastelShop" ile bitsin) yalnızca mentor bilir, işçi görmez. İşçi kuralı bilemeyeceği için ilk teslimde ihlal eder, mentor `guideline_violations` ile geri gönderir ve kuralı tek cümlelik bir dersle işçinin ders defterine yazar; sonraki teslimde işçi bunu uygular. **Dürüst not:** Bu düzeltme FakeLlm testleriyle doğrulandı (rehber yalnızca mentor promptunda, ders sonraki işçi promptuna giriyor, ihlalli pass revise'a dönüyor). Gerçek Groq ile rehberli denemeyi bu yazı yazılırken henüz yapmadık; sonucu buraya eklenecek.

Ayrıca gerçek denemelerde bir kez DNS hatası (`Socket::ResolutionError`) görüldü: kart yerinde kaldı, `llm_error` olayı yazıldı, sonraki turda düzeldi. Bu, tek otomatik yeniden deneme eklemesine yol açtı.

### 3 dakikalık canlı demo senaryosu

Canlı adres: https://pastelboard-web.onrender.com. Ücretsiz plan uyuyabilir; demodan bir dakika önce adresi açıp uyandır. Canlıda `GROQ_API_KEY` ve `DEMO_MODE=1` ayarlı olmalı (anahtar yoksa pano "simülasyon modu"nda çalışır).

1. **0:00 — Demo panoyu kur.** Panolar sayfasında "Demo ajan panosu oluştur/sıfırla"ya bas. Panoda üstteki mod etiketine ("Groq · openai/gpt-oss-20b / openai/gpt-oss-120b"), sağdaki "Ekip rehberi" kutusuna (işçiler görmez) ve boş ders defterlerine dikkat çek. Dört kart Havuz'da.
2. **0:30 — İlk tur.** "▶ Bir tur çalıştır": buton "Ajanlar çalışıyor…" yazar. İki işçi birer kart alır; kartlar "Mentor incelemesinde"ye geçer. Tur özeti üstte çıkar.
3. **1:00 — Düzeltme ve ders.** İkinci tur: mentor inceler. Rehbere aykırı bir kart "Düzeltmede"ye döner. Kartı aç: kriter bazında ✓/✗, kırmızı "Ekip rehberi ihlali" kutusu, mentor geri bildirimi. Sağdaki "Ajanlar"da ilgili işçinin ders defterine yeni bir ders düştü. Üçüncü tur: işçi dersle düzeltir, kart Done'a gider.
4. **1:45 — İnsana soru.** Bilgisi eksik kart ("Yeni ürün için açıklama metni") "İnsana devredildi" kolonunda kırmızı. Kartı aç: "Ajan insana soru sordu". İşçi bilgiyi uydurmadı.
5. **2:15 — İpucu ver.** Metin kutusuna ürün bilgisini yaz (ör. "Aurora masa lambası, 12 saat pil, 399 TL"), "İpucu ver ve geri gönder"e bas. Kart "Düzeltmede"ye döner; bir tur daha çalıştır, işçi ipucuyla yazar.
6. **2:40 — Canlı görev.** Havuz'da "+ Görev ekle": başlık, açıklama ve her satıra bir kabul kriteri yaz, ekle ve bir tur çalıştır. Ajanlar kartı alır.
7. **3:00 — Kanıt.** Herhangi bir kartın zaman çizelgesini göster: kim, ne yaptı, ne zaman (varsa LLM hataları da orada).

Gerçek model beklenmedik davranırsa (ör. rehberi ilk seferde tutturursa) anlatı aynı kalır: zaman çizelgesi ve ders defteri neyin olduğunu gösterir. Tur başına en fazla 3 kart ilerler, dört kartı bitirmek için birkaç tur gerekir.

### Vaat edip yapamadıklarım

- **Gerçek Groq'ta tur süresi ölçülmedi.** Ajan ortamında anahtar yoktu; süre ölçümünü Ceyda yapacak (`ruby bin/rails runner "AgentBoards::DemoRun.call"` çıktısındaki "Süre"). 30 saniyeyi aşarsa `AGENT_ROUND_LIMIT=2` ayarlanacak. Tur istek içinde senkron çalışır; çok uzarsa Render'da zaman aşımı riski var.
- **Rehberli gerçek deneme (bulgu b) henüz yapılmadı;** yalnızca FakeLlm testleriyle doğrulandı.
- **Canlı (Render) ortamda ajan panosu henüz doğrulanmadı:** ortam değişkenlerinin ve yeni migration'ların canlıda çalıştığı Ceyda'nın kontrolünde.
- **Arayüz tarayıcıda gözle incelenmedi;** HTML çıktısı controller testleriyle ve dev sunucusunda 200 yanıtıyla doğrulandı.
- **Ajanlar kendiliğinden çalışmıyor:** işler yalnızca "Bir tur çalıştır" butonuyla (ya da `DemoRun` komutuyla) ilerler; zamanlanmış otomatik tur yok.
- **Ekip rehberi için düzenleme arayüzü yok;** rehber şimdilik yalnızca demo seeder'ından geliyor.
- **Mentor bazı kriterleri hiç listelemeden pass derse** `met=false` kuralı bunu yakalamaz.

## Zaman

İnsan zamanı: [CEYDA YAZACAK]

Agent zamanı: **≈ 3 saat 15 dakika** (195 dk; duvar saati). Hesap: `ILERLEME.md`'deki ilk kayıt (Adım 0, 24 Ekim 2026 16:27:39) ile son kayıt (Adım 4, 19:42:47) arasındaki fark. Bu süre Ceyda'nın onay beklemelerini ve gerçek Groq denemelerini de içerir; saf agent çalışma süresi bundan kısadır.

| Aralık | Dakika |
| --- | --- |
| Adım 0 → 1 (16:27 → 17:04) | 36 |
| Adım 1 → 2 (17:04 → 17:32) | 29 |
| Adım 2 → 2b (17:32 → 18:39), arada Ceyda'nın ilk gerçek Groq denemesi (model 404) | 67 |
| Adım 2b → 2c (18:39 → 19:11), arada ikinci gerçek deneme (uydurma bulgusu) | 32 |
| Adım 2c → 2d (19:11 → 19:32), arada üçüncü gerçek deneme (BİLGİ EKSİK çalıştı, rework görünmedi) | 21 |
| Adım 2d → 3 (19:32 → 19:39) | 7 |
| Adım 3 → 4 (19:39 → 19:42) | 3 |

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
