# PastelBoard

[![CI](https://github.com/ceydasaricelik/pastelboard/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/ceydasaricelik/pastelboard/actions/workflows/ci.yml)

**Canlı uygulama:** https://pastelboard-web.onrender.com
(Render ücretsiz planında çalışır; uzun süre istek gelmezse uyur ve ilk açılış 30–60 saniye sürebilir.)

PastelBoard, Kanban tarzı iş takip uygulamalarından, özellikle **Trello**'dan *ilham alınarak* Ruby on Rails 8 ile geliştirilmiş bir proje yönetim panosudur. Proje, bir kurumsal SaaS ürününün çekirdek iş akışını ("aort dilimi") yeniden inşa eder ve bu akışa kullanıcı şikâyetlerinden çıkan otomatik bir SLA eskalasyon kuralı ekler. PastelBoard'un Trello veya Atlassian ile bir bağlantısı yoktur; uygulamada orijinal markanın adı ya da logosu kullanılmaz.

Ajanla çalışma kuralları ve mimari kararlar: [AGENTS.md](AGENTS.md)

## Özellikler

- **Kanban panosu:** Yatay kaydırılan listeler; kartlar SortableJS ile liste içinde ve listeler arasında sürüklenip bırakılır.
- **Durum akışı:** `normal → escalated → completed`. "Done" listesine bırakılan kart `completed` olur ve kontrol listesinin tüm maddeleri işaretlenir. Done'dan çıkarılan kart tekrar `normal` olur.
- **SLA eskalasyonu (zaman kuralı):** Solid Queue her saat süresi geçmiş kartları panonun başındaki "Gecikenler" listesine taşır ve `escalated` yapar.
- **Kart yaşlandırma:** 2 günden uzun süredir dokunulmamış açık kartlar soluklaşır ve "Uyuyan kart" rozeti alır. Kartı taşımak, düzenlemek veya kontrol listesinde bir madde işaretlemek kartı uyandırır.
- **Kart detayı:** Başlık, açıklama, teslim tarihi, etiketler, üye atama, ilerleme çubuklu kontrol listesi ve kart silme.
- **Listeler:** Ekleme, yeniden adlandırma ve silme. Her yeni listeye panodaki diğer listelerden farklı, rastgele bir pastel renk atanır.
- **Demo tetikleyicileri:** "SLA kontrolü" butonu kuralı hemen çalıştırır. "⏩ 2 gün ileri sar" butonu aynı kuralı iki gün sonrasıymış gibi çalıştırır; bu buton yalnızca geliştirme ortamında veya `DEMO_MODE` açıkken görünür.

## Ödev Faz 1 — Araştırma: Fortune 500 Şirketlerinde SaaS

Fortune 500, ABD'nin en büyük 500 şirketini **ciroya göre** sıralar. 2025 listesi 2024 mali yılı verilerine dayanır.

| Gösterge | Değer | Kaynak |
| --- | --- | --- |
| **a. Değerleme aralığı (en büyük)** | ≈ 4–5 trilyon $ piyasa değeri (Nvidia, 2025: Temmuz'da ≈ 4,2 T$, Ekim'de ≈ 4,9 T$) | [WION, Ekim 2025](https://www.wionews.com/photos/top-7-most-valuable-companies-in-2025-nvidia-hits-5-trillion-apple-joins-4t-club-1761907215033), [Business Standard, Temmuz 2025](https://www.business-standard.com/companies/news/nvidia-set-to-become-the-world-s-most-valuable-company-in-history-125070301199_1.html) |
| **a. Değerleme aralığı (en küçük)** | Şirket bazında en küçük piyasa değerine kamuya açık bir kaynakta ulaşılamadı. Bazı liste şirketleri halka açık değildir, dolayısıyla piyasa değerleri yoktur. Alt sınır olarak listeye giriş eşiği **7,4 milyar $ ciro**dur. Listenin toplam piyasa değeri **46 trilyon $**'dır. | [Fortune, 2025 Fortune 500 duyurusu](https://fortunemedia.mediaroom.com/2025-06-02-Fortune-Announces-2025-Fortune-500-List) |
| **b. Çalışan sayısı aralığı** | ≈ **1.700** (Cheniere Energy; listede 2.000'den az çalışanı olan 8 şirket var) ile ≈ **2,1 milyon** (Walmart) arası. Listenin toplam çalışan sayısı ≈ 31 milyon. | [Fortune, Haziran 2025](https://fortune.com/2025/06/02/fortune-500-employees-headcount-workforce-largest-smallest) |
| **c. Şirket başına SaaS uygulaması** | Ortalama **254** (tüm ölçekler, 2021); 10.000+ çalışanlı şirketlerde **364** (2021); tüm şirketlerde ortalama **371** (2023) | [Productiv 2021](https://www.businesswire.com/news/home/20210915005244/en/Less-than-Half-of-Company-SaaS-Applications-Are-Regularly-Used-by-Employees), [Productiv 2023](https://businesswire.com/news/home/20230621237630/en/2023-State-of-SaaS-Series-While-Companies-Make-Progress-Cutting-Costs-Previous-Investments-and-Growth-of-Shadow-Apps-like-ChatGPT-Challenge-Efforts-to-Manage-SaaS-Spend) |
| **d. Yıllık SaaS harcaması** | Kurum başına ortalama ≈ **55,7 milyon $** (medyan ≈ 20,6 milyon $) | Zylo *SaaS Management Index* verisi, ikincil kaynaktan: [CloudNuro](https://www.cloudnuro.ai/blog/saas-statistics) |
| Bağlam: toplam kurumsal SaaS pazarı | 195 milyar $ (2023) → ≈ 300 milyar $ (2025 tahmini) | Gartner, [SaaStr 2023](https://www.saastr.com/gartner-saas-spend-in-the-enterprise-will-grow-17-to-195-billion-in-2023), [SaaStr 2025](https://saastr.com/gartner-saas-spend-is-actually-accelerating-will-hit-300-billion-in-2025) |

**Notlar:**
- Uygulama sayısı ve harcama verileri SaaS yönetim platformlarından (Productiv, Zylo) gelir ve kendi müşteri tabanlarını yansıtır; yalnızca Fortune 500'e ait değildir.
- Gartner rakamları şirket başına ortalama değil, toplam pazar büyüklüğüdür.
- Productiv'in 2021 raporuna göre şirketlerin SaaS uygulamalarının yarısından azı çalışanlar tarafından düzenli kullanılmaktadır.

## SaaS Seçimi ve Kanıt: Neden Trello?

1. **Fortune 500 kanıtı:** Atlassian, Trello'nun **Fortune 500 şirketlerinin %80'inde** kullanıldığını beyan etmektedir ([Trello Enterprise](https://trello.com/enterprise)). 2016'da şirketin CEO'su bu oranı %74 olarak açıklamıştı ([Fortune, 2016](https://fortune.com/2016/10/31/trello-project-management)). İddia ilk kez Eylül 2017'de %80 olarak dile getirildi ([VentureBeat](https://venturebeat.com/ai/trello-reaches-50-million-users-introduces-new-automation-and-template-features)). Her iki oran da üreticinin kendi beyanıdır; bağımsız bir denetimden geçmemiştir.
2. **Kurumsal ölçek:** Trello web, mobil ve masaüstü istemcileri, otomasyon motoru (Butler), entegrasyonlar (Power-Up'lar) ve kurumsal yönetim katmanı olan bir üründür (ayrıntılar Faz 2'de).
3. **Net bir aort dilimi:** Müşteri, işin pano üzerinde akmasına ve **zamanında bitmesine** para öder: kart oluştur → listeler arasında ilerlet → teslim tarihini takip et.

## Ödev Faz 2 — Maliyet Analizi

### Trello'nun yaklaşık satır sayısı ve tahmin yöntemi

Trello'nun kaynak kodu kapalı olduğundan satır sayısı **doğrudan ölçülemez**. Tahmin, karşılaştırma yoluyla yapılmıştır:

1. **Referans:** Açık kaynaklı Trello alternatifi **WeKan**, kendi bakımcılarının verdiği bilgiye göre yaklaşık **134.000 satır** koddur (316 katkıcı) ([WeKan wiki](https://github.com/wekan/wekan/wiki/Deep-Dive-Into-WeKan), [Open Hub](https://openhub.net/p/wekan)).
2. **Kapsam farkı:** WeKan yalnızca web uygulamasıdır. Trello bunlara ek olarak iOS ve Android uygulamaları, Butler otomasyon motoru, Power-Up platformu ve API'si, kurumsal yönetim (SSO, yönetici konsolu) ile ödeme altyapısı içerir.
3. **Sonuç:** Yalnızca web çekirdeği WeKan büyüklüğünde kabul edilip mobil istemciler ve kurumsal katmanlar eklendiğinde, Trello için **en az ≈ 300.000 satır** makul bir alt tahmindir. Bu sayı doğrulanmış değil, **tahmindir**.

### PastelBoard'un gerçek satır sayısı (ölçülen)

| Katman | Satır (boş satırlar hariç) |
| --- | --- |
| Modeller | 114 |
| Controller'lar | 223 |
| View'lar (ERB + Tailwind) | 413 |
| Helper, job, JavaScript ve CSS | 199 |
| Migration ve seed | 272 |
| Testler ve fixture'lar | 344 |
| **Toplam** | **1.565** |

Aort dilimi, Trello'nun tahmini büyüklüğünün yaklaşık **%0,5**'i kadar kodla çalışır hâle gelmiştir.

### Yapay zekâ ile geliştirme maliyeti: tahmin ve gerçekleşen

| | Tahmin | Gerçekleşen |
| --- | --- | --- |
| **Süre** | 2–3 gün | **≈ 3 gün** (17–19 Ekim 2026), insan gözetiminde yinelemeli olarak |
| **Araç** | Claude (kodlama ajanı) | Claude Code (Claude Opus 5.5 modeli) |
| **Token maliyeti** | ≈ 12–16 $ (aşağıdaki hesap) | Geliştirme sabit ücretli bir Claude aboneliği üzerinden yapıldı; token başına ayrı bir fatura oluşmadı. |

**Token tahmininin hesabı** (Opus 5.5 liste fiyatlarıyla: girdi 4 $, çıktı 20 $, önbellekten okuma 0,20 $ / milyon token):
- ≈ 8 milyon token önbellekten okunan bağlam → ≈ 1,6 $
- ≈ 1 milyon token önbelleğe alınmamış girdi → ≈ 4 $
- ≈ 300–500 bin token çıktı (kod ve akıl yürütme) → ≈ 6–10 $

**Değerlendirme:** Token maliyeti düşüktür. Asıl maliyet kalemi insan zamanıdır: gereksinimleri yazmak, her adımı tarayıcıda ve testlerle doğrulamak, yanlış giden kararları düzeltmek. Örneğin deploy sırasında yaşanan çok veritabanı sorunu, ancak canlı ortamda denenerek ortaya çıktı.

## 100 Puan: Kullanıcı Acısı ve Çözümü

**Tek cümle:** *Trello kullanıcıları teslim tarihi geçen kartlar için uyarı alamadıklarından ve geciken kartların kalabalık panoda gözden kaçmasından şikâyet ediyor. PastelBoard'da süresi geçen kartın sadece rengi değişmiyor: Solid Queue onu her saat otomatik olarak panonun başındaki kırmızı "Gecikenler" listesine taşıyor ve durumunu `escalated` yapıyor.*

**Kullanıcı yorumları (kanıt):**
- **G2, Aralık 2025:** Küçük işletmede çalışan bir operasyon uzmanı, Trello'nun eksiği olarak *"teslim tarihi olan kartlar için bildirim vermeli"* yazıyor ([G2 yorumu](https://www.g2.com/survey_responses/trello-review-4563927)).
- **G2:** Başka bir kullanıcı, panolar büyüdükçe karmaşıklaştığını ve gezinmenin zorlaştığını, bazı otomasyon limitlerinin ücretli planlara bağlı olduğunu belirtiyor ([G2 yorumu](https://www.g2.com/survey_responses/trello-review-4834123)).
- **Capterra:** Trello'nun eksileri arasında tutarsız bildirimler sayılıyor ([Capterra Trello yorumları](https://www.capterra.com/p/211559/Trello/reviews/Capterra___6168793/)).
- **Chrome Web Store:** Bu açığı kapatmak için yazılmış üçüncü taraf bir eklenti, Trello'nun geciken kartları listenin altına gömdüğünü belirtiyor ([eklenti sayfası](https://chrome.google.com/webstore/detail/njfjeliolopojmdcpaoncmdkoencgepf)).

**Trello'da bu neden çözülmüş değil?** Trello'da teslim tarihi geçen kartın yalnızca tarih rozeti kırmızıya döner; kart yerinde kalır. Aynı davranış Trello'da Butler otomasyonuyla kurulabilir, ancak her pano için kuralın elle yazılması gerekir ve otomasyon kullanımı ücretli planlarda genişler. PastelBoard'da kural **varsayılan olarak** her panoda çalışır.

**Kart yaşlandırma hakkında dürüstlük notu:** Trello'da benzer bir "Card Aging" Power-Up'ı bulunmaktaydı ([Atlassian belgesi](https://support.atlassian.com/trello/docs/using-the-card-aging-power-up/)); topluluk kaynaklarına göre 2023'te bir filtre özelliğiyle değiştirildi ([Atlassian topluluk](https://tnckb94959.lithium.com/forums/Trello-articles/A-new-way-to-filter-Trello-cards-saying-goodbye-to-the-Card/bc-p/2377337)). PastelBoard'daki kart yaşlandırma ayrı bir eklenti değildir: yerleşiktir, varsayılan olarak açıktır ve kartla yapılan her etkileşim kartı uyandırır. 100 puanlık çözüm olarak sunulan özellik **SLA eskalasyonudur**.

### Kodda nerede?

| Parça | Dosya |
| --- | --- |
| Kural | [`app/jobs/escalate_overdue_cards_job.rb`](app/jobs/escalate_overdue_cards_job.rb), `overdue_cards` metodu |
| Zamanlama (saatlik) | [`config/recurring.yml`](config/recurring.yml) |
| Elle / demo tetikleme | [`app/controllers/escalations_controller.rb`](app/controllers/escalations_controller.rb) |
| Durum geçişi | [`app/models/card.rb`](app/models/card.rb), `status_in` metodu |
| Zaman kuralı testi (`travel_to`) | [`test/jobs/escalate_overdue_cards_job_test.rb`](test/jobs/escalate_overdue_cards_job_test.rb) |
| Durum geçişi testleri | [`test/controllers/cards_controller_test.rb`](test/controllers/cards_controller_test.rb) |

Kuralın ayrıntıları:
- Teslim tarihi bugünden önce olan, durumu `normal` olan ve "Done" ya da "Gecikenler" listesinde bulunmayan kartlar seçilir.
- "Gecikenler" listesi yalnızca böyle bir kart varsa `position: 0` ile oluşturulur.
- Kartlar bu listenin sonuna eklenir; ayrıldıkları listeler yeniden numaralandırılır.
- Her pano tek bir veritabanı transaction'ı içinde işlenir.

## Ajan panosu

Panonun işçilerini ajanlara çeviren ikinci bir pano türü (`Board kind=agent`); insan panosu aynen çalışmaya devam eder. Gerekçe ve kanıtlar: [CHALLENGE_LOG.md](CHALLENGE_LOG.md). Acı: ajanlarla çalışan ekiplerde ajan görevden sapar, adım tekrarlar, yanlış çıktıyı bitmiş gibi teslim eder ([MAST, 14 hata türü](https://arxiv.org/abs/2503.13657)).

- **Akış:** İşçi ajanlar Havuz'dan iş alır (koşullu `UPDATE` ile atomik) ve kartın kontrol listesini kabul kriteri olarak kullanarak çıktı üretir. Mentor ajan teslimi kriter kriter inceler ve `pass`, `revise` ya da `escalate` der. `revise`'ta geri bildirim karta, ders işçinin ders defterine yazılır; işçi kendi dersiyle düzeltir. Kartlar "Havuz → Mentor incelemesinde → Düzeltmede → İnsana devredildi / Done" listeleri arasında servis üzerinden taşınır, sürükle-bırak yoktur.
- **İnsana devir:** İkinci denemede de düzelmeyen kart, işçinin öncekiyle aynı çıktıyı tekrarlaması (döngü) ve mentorun `escalate` demesi kartı insana devreder. İşçi, görev için gereken bilgi kartta yoksa uydurmaz: çıktıyı "BİLGİ EKSİK:" ile başlatıp insana soru sorar. İnsan "İpucu ver ve geri gönder" ya da "Onayla, Done'a taşı" der.
- **Güvenlik ağları (LLM'siz):** Mentor pass dese bile `met=false` kriter ya da ekip rehberi ihlali varsa sonuç revise olur. Mentorun geçersiz verdict'i, kartta olmayan `item_id`'ler, HTTP hataları ve zaman aşımı kartı yerinde bırakır ve "LLM hatası" olayı yazar; ağ hatasında tek yeniden deneme yapılır.
- **Ekip rehberi:** Panonun `guidelines` alanı yalnızca mentor promptuna girer; işçi bilmez. İhlaller `guideline_violations` olarak kaydedilir ve kart detayında görünür.
- **Eşzamanlılık:** Her kart satır kilidiyle (`with_lock`) ilerler ve kilit içinde durumu yeniden kontrol edilir; iki tur aynı anda çalışsa da kart iki kez işlenmez.
- **Geçmiş:** Kartın tüm tarihi `AgentEvent` kayıtlarında tutulur ve kart detayında zaman çizelgesi olarak görünür.
- **LLM:** Tek sağlayıcı Groq (OpenAI uyumlu API, `Net::HTTP`, yeni gem yok). Anahtar yalnızca `ENV["GROQ_API_KEY"]` üzerinden okunur. Anahtar yoksa `FakeLlm` kullanılır ve olaylara "simülasyon modu" yazılır. Mentor cevabı `json_schema` + `strict: true` ile alınır.
- **Arayüz:** "▶ Bir tur çalıştır", Havuz'da "+ Görev ekle" (her kriter satırı bir kontrol listesi maddesi olur), kart detayında çıktı, kriter bazında ✓/✗, rehber ihlali ve zaman çizelgesi, yan bölümde ekip rehberi ve ajanlar (ders defterleriyle).
- **Kodda nerede:** `app/services/agent_boards/` (`tick.rb`, `human_actions.rb`, `demo_seeder.rb`, `demo_run.rb`, `prompts.rb`), `app/services/groq_llm.rb` ve `fake_llm.rb`, `app/views/agent_boards/`, `app/controllers/{rounds,agent_tasks,hints,approvals,agent_demos}_controller.rb`.

Terminalden bir tur çalıştırmak için (anahtar ayarlıysa gerçek Groq ile, değilse simülasyonla):

```bash
bin/rails runner "AgentBoards::DemoRun.call"   # demo panoyu sıfırlar ve bir tur çalıştırır
bin/rails runner "AgentBoards::DemoRun.tick"   # aynı panoda bir tur daha
```

## Mimari ve Deploy

- **Canlı güncelleme:** WebSocket (ActionCable) yerine **Turbo 8 morphing** kullanılır. Her işlemden sonra sayfa yenilenir, ama Turbo yalnızca değişen kısımları günceller ve kaydırma konumu korunur. WebSocket ile yayın yapmak için Redis ya da ayrı bir veritabanı gerekirdi.
- **Tek veritabanı (Render):** Rails 8 varsayılan olarak production'da dört veritabanı bekler (`primary`, `cache`, `queue`, `cable`). Render yalnızca bir `DATABASE_URL` verir. Bu yüzden:
  - Solid Queue tabloları bir migration ile ana veritabanına taşındı.
  - Önbellek bellek içinde, Action Cable `async` adaptöründe çalışır.
- **Arka plan görevleri:** `SOLID_QUEUE_IN_PUMA=true` ile Solid Queue web sunucusunun (Puma) içinde çalışır; ayrı bir worker sunucusu gerekmez.

### Render ortam değişkenleri

`DATABASE_URL`, `RAILS_MASTER_KEY`, `SOLID_QUEUE_IN_PUMA=true`, demo için `DEMO_MODE=1`.

Ajan panosu için ek olarak: `GROQ_API_KEY` (yoksa pano "simülasyon modu"nda çalışır), isteğe bağlı `GROQ_WORKER_MODEL` (varsayılan `openai/gpt-oss-20b`), `GROQ_MENTOR_MODEL` (varsayılan `openai/gpt-oss-120b`) ve `AGENT_ROUND_LIMIT` (tur başına kart sınırı, varsayılan 3). `DEMO_MODE` ayarlıysa pano listesinde "Demo ajan panosu oluştur/sıfırla" butonu görünür.

## Kurulum (yerel)

Gereksinimler: Ruby 4.0.7, PostgreSQL.

```bash
bundle install
bin/rails db:prepare     # veritabanı + migration + seed
bin/dev                  # http://localhost:3000
```

Windows'ta `bin/dev` çalışmaz (Foreman Procfile'ı Unix soketleriyle çalıştırır). Windows PowerShell için:

```powershell
bundle install
ruby bin/rails db:prepare
ruby bin/rails tailwindcss:build
ruby bin/rails server    # http://localhost:3000
```

Ajan panosunu gerçek Groq modelleriyle denemek için sunucuyu başlatmadan önce aynı terminalde `$env:GROQ_API_KEY = "..."` ayarla; anahtar yoksa pano simülasyon modunda çalışır.

Eskalasyon kuralını elle çalıştırmak için:

```bash
bin/rails runner "EscalateOverdueCardsJob.perform_now"
```

## Testler ve Sürekli Entegrasyon

```bash
bin/rails db:test:prepare test
```

GitHub Actions ([`ci.yml`](.github/workflows/ci.yml)) her push ve pull request'te şunları çalıştırır:
- Brakeman ve bundler-audit (güvenlik taraması)
- importmap audit (JavaScript bağımlılıkları)
- RuboCop (kod stili)
- PostgreSQL servisi ile önce `EscalateOverdueCardsJobTest`, ardından tüm test paketi

Testler 139 senaryoyu kapsar. İlk 34'ü insan panosuna aittir: `travel_to` ile zaman kuralı, durum geçişleri, sürükle-bırak, kart yaşlandırma, liste/kart/üye işlemleri. Kalanı ajan panosunu kapsar (aşağıda). Testler ağa çıkmaz: LLM çağrıları `FakeLlm` ile, HTTP isteği stub ile taklit edilir ve test sürecinde `GROQ_API_KEY` silinir.

## Yapamadıklarım

- **Kullanıcı girişi yok (Devise yok):** Panolar herkese açıktır. "Üyeler" yalnızca isimden oluşan kayıtlardır, oturum açan kullanıcılar değildir.
- **Gerçek zamanlı WebSocket yok:** ActionCable yerine Turbo morphing kullanıldı. Aynı panoyu başka sekmede açık tutan kullanıcı, değişikliği sayfayı yenileyince görür.
- **SLA hafta sonlarını sayıyor:** İş günü takvimi uygulanmadı.
- **Render ücretsiz planı uyuyor:** Sunucu uyurken saatlik görev çalışmaz; uyandığında bir sonraki saatte çalışır. Demo için elle tetikleme butonları eklendi.
- **Trello özelliklerinin bir kısmı yok:** Yorumlar, aktivite geçmişi, dosya ekleri, arama/filtreleme, arşivleme ve etiket oluşturma/düzenleme arayüzü yok (her pano altı varsayılan etiketle gelir).
- **Tarayıcı (system) testleri yok:** Sürükle-bırak elle test edildi. Otomatik testler, sunucu tarafındaki `move` uç noktasını doğrular.
- **Gerçek token faturası ölçülmedi:** Geliştirme abonelik üzerinden yapıldığı için Faz 2'deki dolar tutarı tahmindir.
- **Ajan panosu: ajanlar kendiliğinden çalışmaz.** İşler yalnızca "Bir tur çalıştır" butonuyla (ya da `DemoRun` komutuyla) ilerler; zamanlanmış otomatik tur yok. Tur istek içinde senkron çalışır.
- **Ajan panosu: termos kartı gerçek denemede Done olmadı** (işçi mentorun dersini iki denemede uygulayamadı, kart insana devredildi); sonraki prompt düzeltmesi gerçek modelle denenmedi. Gerçek turlar yerelde 1–7 sn sürdü, ama tur istek içinde senkron çalışır. Ekip rehberi şimdilik yalnızca demo seeder'ından gelir, düzenleme arayüzü yok.
- **Ajan panosu: mentor kriterleri atlarsa yakalanmaz.** Kod kuralı yalnızca mentorun `met=false` dediği kriterleri ve rehber ihlallerini yakalar; mentor bazı kriterleri hiç listelemeden pass derse bu geçer.

## Kaynaklar

- Fortune 500 2025 duyurusu (ciro eşiği, toplam piyasa değeri): [Fortune Media](https://fortunemedia.mediaroom.com/2025-06-02-Fortune-Announces-2025-Fortune-500-List)
- Fortune 500 çalışan sayıları: [Fortune, Haziran 2025](https://fortune.com/2025/06/02/fortune-500-employees-headcount-workforce-largest-smallest)
- En değerli şirketler (piyasa değeri): [WION](https://www.wionews.com/photos/top-7-most-valuable-companies-in-2025-nvidia-hits-5-trillion-apple-joins-4t-club-1761907215033), [Business Standard](https://www.business-standard.com/companies/news/nvidia-set-to-become-the-world-s-most-valuable-company-in-history-125070301199_1.html)
- Productiv 2021 ve 2023: [Business Wire 2021](https://www.businesswire.com/news/home/20210915005244/en/Less-than-Half-of-Company-SaaS-Applications-Are-Regularly-Used-by-Employees), [Business Wire 2023](https://businesswire.com/news/home/20230621237630/en/2023-State-of-SaaS-Series-While-Companies-Make-Progress-Cutting-Costs-Previous-Investments-and-Growth-of-Shadow-Apps-like-ChatGPT-Challenge-Efforts-to-Manage-SaaS-Spend)
- Zylo verisinin derlemesi: [CloudNuro](https://www.cloudnuro.ai/blog/saas-statistics)
- Gartner pazar tahminleri: [SaaStr 2023](https://www.saastr.com/gartner-saas-spend-in-the-enterprise-will-grow-17-to-195-billion-in-2023), [SaaStr 2025](https://saastr.com/gartner-saas-spend-is-actually-accelerating-will-hit-300-billion-in-2025)
- Trello Fortune 500 beyanı: [Trello Enterprise](https://trello.com/enterprise), [Fortune 2016](https://fortune.com/2016/10/31/trello-project-management), [VentureBeat](https://venturebeat.com/ai/trello-reaches-50-million-users-introduces-new-automation-and-template-features)
- WeKan satır sayısı: [WeKan wiki](https://github.com/wekan/wekan/wiki/Deep-Dive-Into-WeKan), [Open Hub](https://openhub.net/p/wekan)
- Kullanıcı yorumları: [G2 #4563927](https://www.g2.com/survey_responses/trello-review-4563927), [G2 #4834123](https://www.g2.com/survey_responses/trello-review-4834123), [Capterra](https://www.capterra.com/p/211559/Trello/reviews/Capterra___6168793/), [Chrome Web Store eklentisi](https://chrome.google.com/webstore/detail/njfjeliolopojmdcpaoncmdkoencgepf)
- Trello Card Aging: [Atlassian belgesi](https://support.atlassian.com/trello/docs/using-the-card-aging-power-up/), [Atlassian topluluk](https://tnckb94959.lithium.com/forums/Trello-articles/A-new-way-to-filter-Trello-cards-saying-goodbye-to-the-Card/bc-p/2377337)
- Claude fiyatlandırması: Anthropic API fiyat listesi (Opus 5.5: girdi 4 $, çıktı 20 $, önbellekten okuma 0,20 $ / milyon token)
