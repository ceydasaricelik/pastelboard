# PastelBoard

[![CI](https://github.com/ceydasaricelik/pastelboard/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/ceydasaricelik/pastelboard/actions/workflows/ci.yml)

PastelBoard, Kanban tarzı iş takip uygulamalarından (özellikle **Trello**) ilham alınarak Ruby on Rails 8 ile geliştirilmiş bir proje yönetim panosudur. Proje, bir kurumsal SaaS ürününün çekirdek iş akışını ("aort dilimi") yeniden inşa etmeyi ve bu akışa Trello'da bulunmayan otomatik bir SLA eskalasyon kuralı eklemeyi amaçlar. PastelBoard, Trello veya Atlassian ile bağlantılı değildir.

## Özellikler

- **Kanban panosu:** Yatay kaydırılan listeler, SortableJS ile kartları liste içinde ve listeler arasında sürükle-bırak.
- **Durum yönetimi:** "Done" listesine bırakılan kart otomatik olarak `completed`, oradan çıkarılan kart tekrar `normal` olur.
- **Kart detay paneli:** Başlık, açıklama, teslim tarihi, etiketler, üye atama, kontrol listesi (ilerleme çubuğuyla) ve kart silme.
- **Etiketler:** Her panoya altı renkli varsayılan etiket (Acil, Tasarım, Geliştirme, Pazarlama, Test, Doküman); kart yüzünde renkli şeritler.
- **Üyeler ve görev atama:** Panoya üye eklenir, kartlara bir veya birden çok üye atanır; kartta baş harfli avatarlar görünür.
- **Liste yönetimi:** Liste ekleme, yeniden adlandırma ve silme. Yeni listeye panodaki diğer listelerden farklı, rastgele bir pastel renk atanır.
- **Teslim tarihi rozetleri:** Takvim ikonlu tarih; tarihi geçmiş ve tamamlanmamış kartlarda pastel kırmızı rozet.
- **Otomatik eskalasyon:** Solid Queue ile saatlik çalışan arka plan görevi, gecikmiş kartları "Gecikenler" listesine taşır (ayrıntılar aşağıda).
- **Anında arayüz güncellemesi:** Formlar ve sürükle-bırak sonrası sayfa, Turbo 8 morphing ile kaydırma konumu korunarak yenilenir.

## Ödev Faz 1 — Araştırma: Kurumsal SaaS Kullanımı

Büyük ölçekli şirketler (Fortune 500 düzeyi) yüzlerce SaaS uygulamasını aynı anda kullanır ve bunlara on milyonlarca dolarlık yıllık bütçe ayırır. Fortune 500 listesi ciroya göre sıralanır; bu şirketlerin piyasa değerleri kabaca **1 milyar $ ile 500 milyar $'ın üzerine** uzanan çok geniş bir aralığa yayılır.

| Gösterge | Değer | Kaynak |
| --- | --- | --- |
| Şirket başına ortalama SaaS uygulaması (tüm ölçekler, 2021) | 254 | Productiv, *State of SaaS Sprawl* (2021) |
| 10.000+ çalışanlı şirketlerde ortalama SaaS uygulaması (2021) | 364 | Productiv (2021) |
| Ortalama SaaS uygulaması (2023) | 371 | Productiv, *2023 State of SaaS* |
| Kurum başına yıllık ortalama SaaS harcaması | ≈ 55,7 milyon $ (medyan ≈ 20,6 milyon $) | Zylo, *SaaS Management Index* (ikincil kaynak üzerinden) |
| Kurumsal SaaS pazarının toplam büyüklüğü | 195 milyar $ (2023) → ≈ 300 milyar $ (2025 tahmini) | Gartner (SaaStr aktarımı) |

**Yorum:** Bir kurumun kullandığı SaaS sayısı, ölçeğe ve ölçüm yöntemine bağlı olarak 150 ile 370 arasında değişmektedir. Ortalama yıllık harcama ise yaklaşık 50 milyon $ düzeyindedir. Productiv'in 2021 raporuna göre bu uygulamaların yarısından azı çalışanlar tarafından düzenli olarak kullanılmaktadır. Bu da iş takip araçları gibi yatay (departmanlar arası) SaaS ürünlerinin kurumsal maliyet içinde önemli ama verimi sorgulanan bir kalem olduğunu gösterir.

> Not: Gartner'ın yayımladığı rakamlar şirket başına ortalama değil, toplam pazar büyüklüğüdür. Şirket başına harcama ve uygulama sayısı verileri SaaS yönetim platformlarından (Productiv, Zylo) gelmektedir.

## SaaS Seçimi ve Kanıt: Neden Trello?

Klonlanacak ürün olarak Trello seçilmiştir, çünkü:

1. **Kurumsal yaygınlık:** Atlassian, Trello'nun **Fortune 500 şirketlerinin %80'inde** kullanıldığını beyan etmektedir ([Trello Enterprise](https://trello.com/enterprise)). Bu oran 2016'da şirket CEO'su tarafından %74 olarak açıklanmıştı ([Fortune, 2016](https://fortune.com/2016/10/31/trello-project-management)). Her iki rakam da üreticinin kendi beyanıdır; bağımsız bir denetimden geçmemiştir.
2. **Net bir çekirdek iş akışı:** Pano → liste → kart hiyerarşisi ve kartın listeler arasında ilerlemesi, sınırlı sürede uçtan uca inşa edilebilecek kadar net bir "aort dilimi" sunar.
3. **Somut bir ağrı noktası:** Trello'da teslim tarihi geçen kart yalnızca renk değiştirir; bu, kurumsal ekiplerde SLA ihlallerinin fark edilmemesine yol açar. PastelBoard bu boşluğu hedefler.

## Ödev Faz 2 — Maliyet Analizi

### Çekirdek satır sayısı

Bu depodaki PastelBoard kodu (boş satırlar hariç) yaklaşık şu büyüklüktedir:

| Katman | Satır |
| --- | --- |
| Modeller | 100 |
| Controller'lar | 206 |
| View'lar (ERB + Tailwind) | 372 |
| Helper | 44 |
| Arka plan görevi (eskalasyon) | 31 |
| JavaScript (Stimulus + SortableJS) | 49 |
| Migration + seed | 125 |
| Testler + fixture'lar | 301 |
| CI yapılandırması | 92 |
| **Toplam** | **≈ 1.320** |

Uygulama çekirdeği (model, controller, view, helper, job, JS) yaklaşık **800 satırdır**. Trello'nun tamamı (gerçek zamanlı senkronizasyon, mobil istemciler, entegrasyonlar, otomasyon, yetkilendirme, faturalandırma vb.) bunun yüzlerce katı büyüklükte bir kod tabanıdır; kamuya açık kesin bir satır sayısı bulunmadığından bu proje yalnızca çekirdek iş akışını kapsar.

### Yapay zekâ (Claude) ile geliştirme maliyeti

Proje, Claude Code üzerinde **Claude Opus 5.5** modeliyle, insan gözetiminde yinelemeli olarak geliştirilmiştir. Kesin token sayıları oturum faturasından alınmadığı için aşağıdaki değerler bir **tahmindir**:

| Kalem | Varsayım | Birim fiyat (Opus 5.5) | Tahmini maliyet |
| --- | --- | --- | --- |
| Önbellekten okunan girdi | ≈ 8 milyon token (her adımda bağlamın yeniden gönderilmesi) | 0,20 $ / 1M | ≈ 1,6 $ |
| Önbelleğe alınmamış girdi | ≈ 1 milyon token | 4 $ / 1M | ≈ 4 $ |
| Çıktı (kod + akıl yürütme) | ≈ 300–500 bin token | 20 $ / 1M | ≈ 6–10 $ |
| **Toplam** | | | **≈ 12–16 $** |

- **Süre:** Altyapıdan CI'a kadar tüm fazlar birkaç oturumda, toplamda yaklaşık bir iş günü içinde tamamlanmıştır.
- **Karşılaştırma:** Aynı kapsamın (≈ 1.300 satır, test ve CI dâhil) deneyimli bir Rails geliştiricisi tarafından yazılması kabaca 1–2 iş haftası sürer.
- **Önemli not:** Token maliyeti düşüktür, ancak asıl maliyet kalemi insan zamanıdır: gereksinim yazma, ara sonuçları tarayıcıda doğrulama ve yön verme. Yapay zekâ kodlama süresini kısaltır, ancak doğrulama sorumluluğunu ortadan kaldırmaz.

## 100 Puanlık Çözümümüz (Aort Dilimi)

**Trello'da süresi geçen kartların yalnızca rengi değişir ve dikkatten kaçar; PastelBoard'da ise Solid Queue her saat gecikmiş kartları bulur, panonun en başındaki kırmızı/turuncu "Gecikenler" listesine taşır ve durumlarını `escalated` yaparak SLA ihlalini görmezden gelinemez hâle getirir.**

Kural ayrıntıları ([`EscalateOverdueCardsJob`](app/jobs/escalate_overdue_cards_job.rb), [`config/recurring.yml`](config/recurring.yml)):

- Teslim tarihi bugünden önce olan, durumu `normal` olan ve "Done" ya da "Gecikenler" listesinde bulunmayan kartlar seçilir.
- "Gecikenler" listesi yalnızca böyle bir kart varsa, `position: 0` ile oluşturulur.
- Kartlar listenin sonuna eklenir, ayrıldıkları listeler yeniden numaralandırılır; her pano tek bir transaction içinde işlenir.
- Kural, `travel_to` ile zamanı ileri saran Minitest testleriyle doğrulanır ([`test/jobs/escalate_overdue_cards_job_test.rb`](test/jobs/escalate_overdue_cards_job_test.rb)).

## Kurulum ve Çalıştırma

Gereksinimler: Ruby 4.0.7, PostgreSQL.

```bash
bundle install
bin/rails db:prepare     # veritabanını oluşturur, migration'ları ve seed'i çalıştırır
bin/dev                  # Rails sunucusu + Tailwind izleyicisi → http://localhost:3000
```

Eskalasyon görevini elle tetiklemek için:

```bash
bin/rails runner "EscalateOverdueCardsJob.perform_now"
```

Periyodik görev, Solid Queue'nun kullanıldığı `production` ortamında saatlik çalışır.

## Testler ve Sürekli Entegrasyon

```bash
bin/rails db:test:prepare test
```

GitHub Actions iş akışı ([`.github/workflows/ci.yml`](.github/workflows/ci.yml)) her push ve pull request'te şunları çalıştırır:

- **scan_ruby:** Brakeman (statik güvenlik analizi) ve bundler-audit (gem güvenlik açıkları).
- **scan_js:** importmap audit (JavaScript bağımlılıkları).
- **lint:** RuboCop (Rails Omakase stili).
- **test:** PostgreSQL servisini ayağa kaldırır, veritabanını hazırlar, önce `EscalateOverdueCardsJobTest`'i ayrı bir adımda, ardından tüm test paketini (`bin/rails test`) koşturur.

## Yapamadıklarım

Bu bölüm projenin bilinçli olarak dışarıda bıraktığı veya tamamlanamayan kısımlarını açıkça belirtir:

- **Kullanıcı yetkilendirmesi yapılmadı (Devise/Login yok):** Panolar herkese açıktır. "Üyeler" yalnızca isimden oluşan kayıtlardır, oturum açan kullanıcılar değildir.
- **Gerçek zamanlı WebSocket (ActionCable) yerine Turbo Morphing kullanıldı:** Değişiklikler, işlemi yapan kullanıcının ekranında anında görünür. Aynı panoyu açık tutan diğer kullanıcılar ise sayfayı yenileyene kadar değişikliği görmez.
- **Etiket yönetimi arayüzü yok:** Her pano altı varsayılan etiketle gelir. Yeni etiket oluşturma veya etiket düzenleme yapılamaz.
- **Yorumlar, aktivite geçmişi, dosya ekleri, arama/filtreleme ve arşivleme** gibi Trello özellikleri uygulanmadı.
- **Tarayıcı (system) testleri yok:** Sürükle-bırak etkileşimi elle test edildi. Otomatik testler, sunucu tarafındaki `move` uç noktasını doğrular.

## Kaynaklar

- Productiv (2021), *Less than Half of Company SaaS Applications Are Regularly Used by Employees* — [Business Wire](https://www.businesswire.com/news/home/20210915005244/en/Less-than-Half-of-Company-SaaS-Applications-Are-Regularly-Used-by-Employees)
- Productiv (2023), *2023 State of SaaS Series* — [Business Wire](https://businesswire.com/news/home/20230621237630/en/2023-State-of-SaaS-Series-While-Companies-Make-Progress-Cutting-Costs-Previous-Investments-and-Growth-of-Shadow-Apps-like-ChatGPT-Challenge-Efforts-to-Manage-SaaS-Spend)
- Zylo *SaaS Management Index* verilerinin derlemesi — [CloudNuro, SaaS Statistics](https://www.cloudnuro.ai/blog/saas-statistics)
- Gartner kurumsal SaaS harcama tahminleri — [SaaStr (2023)](https://www.saastr.com/gartner-saas-spend-in-the-enterprise-will-grow-17-to-195-billion-in-2023), [SaaStr (2025)](https://saastr.com/gartner-saas-spend-is-actually-accelerating-will-hit-300-billion-in-2025)
- Trello kurumsal kullanım beyanı — [Trello Enterprise](https://trello.com/enterprise), [Fortune (2016)](https://fortune.com/2016/10/31/trello-project-management), [VentureBeat](https://venturebeat.com/ai/trello-reaches-50-million-users-introduces-new-automation-and-template-features)
- Claude model fiyatlandırması — Anthropic API fiyat listesi (Opus 5.5: girdi 4 $, çıktı 20 $, önbellek okuma 0,20 $ / milyon token)
