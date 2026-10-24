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

(ILERLEME.md'den doldurulacak)

## Zaman

İnsan zamanı: [CEYDA YAZACAK]

Agent zamanı: (ILERLEME.md'den)

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
