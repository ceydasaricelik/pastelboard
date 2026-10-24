# PastelBoard — Proje Durumu ve Ana Fikir

> Bu dosya yeni bir yol haritası çizmeden önceki **başlangıç noktasını** anlatır: proje ne, neden var, şu an nerede duruyor, nelerin eksik olduğu. Yol haritası bu dosyaya dayanarak ayrıca oluşturulacak.
>
> Son doğrulama: 24 Ekim 2026 · Son commit: `27d0230` (main)

---

## 1. Ana fikir

**PastelBoard**, Trello'dan *ilham alan* bir Kanban panosudur (Trello ile bağlantısı yoktur). Ürün adı ve logosu bağımsızdır; Trello yalnızca README'de "ilham kaynağı" olarak geçer.

**Çıkış noktası (üniversite ödevi):** Bir Fortune 500 SaaS ürününün çekirdek iş akışı ("aort dilimi") bugünün kodlama ajanlarıyla ucuza kopyalanabiliyor. Asıl soru kopyalamak değil, ürünün kullanıcısına **"tam ayağına gelen pası" kimin atacağı**. Yani gerçek kullanıcı şikâyetinden çıkan bir acıyı çözmek.

**Seçilen acı:** Trello'da teslim tarihi geçen kartın yalnızca tarih rozeti kırmızıya döner; kart yerinde kalır ve kalabalık panoda gözden kaçar. Kullanıcılar teslim tarihi için bildirim/uyarı bulunmamasından şikâyet ediyor (G2, Capterra yorumları README'de linkli).

**Tek cümlelik çözüm:** Süresi geçen kart sadece renk değiştirmez; Solid Queue her saat onu panonun başındaki kırmızı **"Gecikenler"** listesine taşır ve durumunu `escalated` yapar.

**Aort dilimi:** Kart oluştur → listeler arasında sürükle-bırak ile ilerlet → zaman kuralı (SLA) kartı otomatik eskale etsin.

---

## 2. Şu anki durum (özet)

| Alan | Durum |
|---|---|
| Canlı uygulama | ✅ https://pastelboard-web.onrender.com (Render, ücretsiz plan) |
| Kaynak kod | ✅ https://github.com/ceydasaricelik/pastelboard (herkese açık, `main`) |
| CI (GitHub Actions) | ✅ Son çalışma (`27d0230`) başarılı; rozet README'de |
| Testler | ✅ 24 Ekim'de yerelde yeniden çalıştırıldı: 34 test, 114 doğrulama, 0 hata (iki ardışık çalıştırma) |
| Kod büyüklüğü | ≈ 1.565 satır (boş satırlar hariç): uygulama ≈ 950, testler ≈ 340, migration/seed ≈ 270 |
| Güvenlik/kalite taramaları | ✅ Brakeman 0 uyarı, bundler-audit, importmap audit, RuboCop temiz |
| Dokümantasyon | ✅ `README.md` (Faz 1–2 araştırması, kaynaklar, yapamadıklarım), `AGENTS.md` |
| Ödev sunumu | 19 Ekim 2026'daydı; **sonucu bu dosyada yok** |

> Not: Bilgisayar yeniden başlayınca yerel PostgreSQL kapanıyor; testlerden önce açmak gerekiyor (bkz. bölüm 8). Yeniden başlatmadan sonraki **ilk** test çalıştırmasında bir kez `plpgsql.dll could not load (unknown error 4551)` hatası görüldü; Windows'un DLL'i ilk yüklemede engellemesi gibi duruyor ve sonraki iki çalıştırmada tekrarlanmadı. Kodla ilgisi yok, ama yerelde tekrar ederse ilk testi yeniden çalıştırmak yeterli.
> Repoda `odev.md` (ödev metni) **takip edilmiyor** (untracked); commit'lenmedi.

---

## 3. Teknoloji ve mimari

**Yığın:** Ruby 4.0.7 · Rails 8.1 · PostgreSQL · Hotwire (Turbo 8 + Stimulus) · Tailwind CSS 4 · SortableJS (importmap) · Solid Queue · Minitest · GitHub Actions · Render

### Veri modeli

```
Board ─┬─< List ─< Card ─┬─< CardLabel >─ Label (board'a ait)
       ├─< Label         ├─< CardMember >─ Member (board'a ait)
       └─< Member        └─< ChecklistItem
```

- **Card.status** (enum): `normal → escalated → completed`
- **Card:** `title`, `description`, `due_date`, `position`, `list_id`; `updated_at` aynı zamanda "uyuyan kart" kuralının girdisi.
- **List:** `name`, `position`, `color` (rastgele pastel renk). Adı `"Done"` ve `"Gecikenler"` olan listeler **özel anlam taşır** (sabitler `List::DONE_NAME`, `List::OVERDUE_NAME`).
- Her pano oluşturulurken 6 varsayılan etiket gelir (Acil, Tasarım, Geliştirme, Pazarlama, Test, Doküman).

### Önemli akışlar

| Akış | Nerede | Ne yapar |
|---|---|---|
| Sürükle-bırak | `app/javascript/controllers/sortable_controller.js` → `PATCH /cards/:id/move` → `CardsController#move` | Transaction içinde liste/sıra günceller, durumu ayarlar, kartı "uyandırır". Hata olursa kart eski yerine döner |
| Durum geçişi | `Card#status_in(list)` | Done'a giren → `completed` (+ kontrol listesi işaretlenir); Done'dan çıkan → `normal` |
| **SLA eskalasyonu** | `app/jobs/escalate_overdue_cards_job.rb`, `config/recurring.yml` (saatlik) | `due_date` bugünden önce + `normal` + Done/Gecikenler dışında olan kartları "Gecikenler" listesine taşır |
| Elle/demo tetikleme | `EscalationsController` | "SLA kontrolü" ve "⏩ 2 gün ileri sar" butonları. İkincisi yalnızca development veya `DEMO_MODE` açıkken görünür |
| **Kart yaşlandırma** | `Card#dormant?` (`DORMANT_AFTER = 2.days`) | 2+ gün dokunulmamış açık kart soluklaşır, "Uyuyan kart" rozeti alır; her etkileşim `updated_at`'i günceller |
| Anlık arayüz | `turbo_refreshes_with method: :morph` | WebSocket yok; her işlemden sonra Turbo morph ile sayfa tazelenir |

### Deploy kurgusu (Render)

- Rails 8 production'da 4 veritabanı bekler; Render tek `DATABASE_URL` verir → **tek veritabanı** kurgusu: Solid Queue tabloları migration ile ana DB'de, önbellek bellek içinde, Action Cable `async`.
- Arka plan görevleri web sunucusunun içinde: `SOLID_QUEUE_IN_PUMA=true` (`config/puma.rb`).
- Render ortam değişkenleri: `DATABASE_URL`, `RAILS_MASTER_KEY`, `SOLID_QUEUE_IN_PUMA`, `DEMO_MODE`.
- Repoda Render'a özel dosya (`render.yaml`) **yok**; build/start komutları Render panelinde. `Dockerfile`, `config/deploy.yml` ve `.kamal/` Rails'in varsayılanlarıdır, kullanılmıyor.

---

## 4. Çalışan özellikler

- Pano listesi/oluşturma/düzenleme/silme
- Liste ekleme, yeniden adlandırma, silme; her yeni listeye farklı rastgele pastel renk
- Kart ekleme (başlık + teslim tarihi), kart detay paneli (başlık, açıklama, tarih), kart silme
- Sürükle-bırak (liste içi ve listeler arası; döndürme/büyütme efekti, bırakma alanı vurgusu)
- Etiketler (6 varsayılan, kartlara atanır), üyeler (isimden ibaret) ve görev atama, avatarlar
- Kontrol listesi (ilerleme çubuğu, kartta "2/3" rozeti); kart Done'a girince hepsi işaretlenir
- Teslim tarihi rozeti (geçmişse pastel kırmızı), "Gecikenler" kolonu (nabız animasyonu, "SLA ihlali" rozeti)
- Kart yaşlandırma, ince/modern kaydırma çubukları
- Saatlik otomatik SLA kontrolü + elle tetikleme butonları

---

## 5. Test kapsamı

34 test (`bin/rails test`): modeller (Board varsayılan etiketler, Card uyuyan kart kuralı), controller'lar (kart taşıma/durum geçişi, kart detayı, liste, üye, eskalasyon), job (`travel_to` ile zaman kuralı, Done istisnası, pano sınırı).
**Tarayıcı (system) testi yok.**

---

## 6. Bilinen eksikler ve teknik borç

Bunlar README'nin "Yapamadıklarım" bölümünde de var; ek olarak çalışırken fark edilenler işaretli (🔎):

**Ürün kapsamı**
- Kullanıcı girişi/yetkilendirme yok; panolar herkese açık, "üyeler" gerçek kullanıcı değil
- Gerçek zamanlı çok kullanıcılı güncelleme yok (Turbo morph; diğer sekme yenilenince görür)
- Yorumlar, aktivite geçmişi, dosya eki, arama/filtre, arşivleme yok
- Etiket oluşturma/düzenleme arayüzü yok; üye/pano düzenleme arayüzü sınırlı
- Teslim tarihi için e-posta/bildirim yok (şikâyetin bir yarısı bildirimdi)

**Zaman kuralı**
- SLA hafta sonlarını sayıyor (iş günü takvimi yok). Çözüm tasarımı hazır: `escalate_overdue_cards_job.rb` satır 37 + `sla_cutoff` metodu
- Eşik "gün" bazlı; saat bazlı SLA yok, panoya/karta özel SLA ayarı yok
- 🔎 `escalated` durumundaki kart Gecikenler'den başka listeye sürüklenirse durumu `escalated` **kalır** (`Card#status_in`); yeniden gecikme kontrolüne girmez
- 🔎 "Gecikenler" listesi boşalınca otomatik silinmez
- 🔎 Kırmızı tarih rozeti (`Card#overdue?`) ile job aynı mantığı ayrı ayrı uyguluyor; kural değişirse ikisi birlikte güncellenmeli

**Altyapı**
- Render ücretsiz plan uyuyor (uyurken saatlik görev çalışmaz, ilk açılış 30–60 sn)
- Deploy ayarları Render panelinde; kodda (`render.yaml`) değil, tekrarlanabilir değil
- Sistem testi ve sürükle-bırak için otomatik tarayıcı testi yok
- 🔎 Dependabot'un 3 açık PR'ı vardı (`actions/cache`, `actions/checkout`, `image_processing` 1→2); durumları bu dosya hazırlanırken kontrol edilmedi
- 🔎 Faz 2'deki gerçek token faturası ölçülmedi (tahmin)

---

## 7. Yol haritası için girdiler

> Bunlar karar değil; öncelik sıralaması yapılırken değerlendirilecek **aday başlıklardır**.

**Karar verilmesi gereken sorular**
1. Bu proje **ödevden sonra** ne olacak? (Portföy parçası mı, gerçek kullanıcılı ürün mü, kapatılacak mı?)
2. Hedef kullanıcı kim? Tek ekip mi, çok kiracılı SaaS mi?
3. Ücretsiz Render'da mı kalınacak, yoksa kalıcı çalışan bir plana geçilecek mi? (Saatlik görev bunu belirliyor)
4. Ana farklılaştırıcı "SLA eskalasyonu" olarak mı kalacak, yoksa genel Trello özellik eşitliği mi hedefleniyor?

**Aday başlıklar (kabaca etki/emek ilişkisiyle)**

| Başlık | İçerik | Emek |
|---|---|---|
| SLA'yı derinleştir | Hafta sonu hariç tutma, saat bazlı eşik, pano başına SLA ayarı, `escalated` kartın yeniden değerlendirilmesi, Gecikenler listesinin boşalınca temizlenmesi | Küçük–orta |
| Bildirimler | Eskalasyonda e-posta (aynı Solid Queue kuyruğu), teslim tarihi yaklaşırken hatırlatma | Orta |
| Kimlik ve yetki | Giriş (Rails 8 kimlik doğrulama veya Devise), gerçek üyeler, panoların özel/paylaşımlı olması | Orta–büyük |
| Gerçek zamanlı iş birliği | Turbo Streams + Solid Cable (kalıcı DB gerektirir) | Orta |
| Eksik Trello özellikleri | Yorumlar, aktivite geçmişi, dosya eki, arama/filtre, arşiv, etiket yönetimi | Büyük |
| Kalite ve güvence | Tarayıcı (system) testleri, `render.yaml` ile tekrarlanabilir deploy, Dependabot PR'larının yönetimi | Küçük–orta |
| Ölçülebilirlik | SLA ihlali sayısı/ortalama gecikme gibi pano raporu, `escalated` kart geçmişi | Orta |

---

## 8. Yerel çalıştırma ve sık komutlar

```bash
bin/dev                           # sunucu + Tailwind izleyicisi → http://localhost:3000
bin/rails db:prepare              # veritabanı + migration + seed
bin/rails db:test:prepare test    # testler
bin/rails runner "EscalateOverdueCardsJob.perform_now"   # SLA kuralını elle çalıştır
bin/rubocop && bin/brakeman --no-pager                   # kalite/güvenlik
```

**Windows notu:** Bilgisayar yeniden başlayınca yerel PostgreSQL (scoop) kapanır. Başlatmak için:
`pg_ctl -D "$env:USERPROFILE\scoop\persist\postgresql\data" start`
Bu makinede `bin/rails server` `fork()` desteklemediği için `SOLID_QUEUE_IN_PUMA` yerelde denenemez (Render/Linux'ta çalışır).

---

## 9. Dosya haritası (nerede ne var)

| İhtiyaç | Dosya |
|---|---|
| SLA kuralı | `app/jobs/escalate_overdue_cards_job.rb` (`overdue_cards`: satır 31–39, tarih koşulu 37) |
| Zamanlama | `config/recurring.yml` |
| Durum geçişi | `app/models/card.rb` (`status_in`, `dormant?`, `overdue?`) |
| Kart taşıma | `app/controllers/cards_controller.rb` (`move`) |
| Özel liste adları | `app/models/list.rb` |
| Pano ekranı | `app/views/boards/show.html.erb`, `_column.html.erb`, `_kanban_card.html.erb`, `app/views/cards/_detail.html.erb` |
| Renkler/stiller | `app/helpers/boards_helper.rb`, `app/assets/tailwind/application.css` |
| Sürükle-bırak | `app/javascript/controllers/sortable_controller.js` |
| Testler | `test/jobs/`, `test/controllers/`, `test/models/` |
| Üretim ayarı | `config/database.yml`, `config/environments/production.rb`, `config/puma.rb` |
| Ajan kuralları ve kararlar | `AGENTS.md` |
