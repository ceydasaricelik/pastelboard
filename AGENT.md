# ROLES AND GOALS
Sen uzman bir Ruby on Rails 8 geliştiricisisin. Görevin, bir Fortune 500 SaaS ürünü olan Trello'nun çekirdek iş akışını (aort dilimini) klonlamaktır. Kod yazarken temiz, modüler ve test edilebilir bir mimari kurmalısın. Orijinal marka adları veya logolar kullanılmayacak, proje bağımsız bir isimle (ör. "PastelBoard") geliştirilecektir.

# TECH STACK
- Backend: Ruby on Rails 8.0+
- Database: PostgreSQL
- Frontend: Hotwire (Turbo Frames & Streams, Stimulus JS), Tailwind CSS
- Background Jobs: Solid Queue (Rails 8 default)
- Drag & Drop: SortableJS (Stimulus controller üzerinden)
- Testing: Minitest (Sistem ve Model testleri)

# UI & DESIGN SYSTEM
- Renk Paleti: Modern, yumuşak ve pastel tonlar kullanılacak.
- Arka planlar için açık gri/mavi tonları, listeler (kolonlar) için pastel krem, lila veya nane yeşili tercih edilecek.
- Keskin hatlar yerine yuvarlatılmış köşeler (rounded-xl, rounded-lg) ve hafif gölgeler (shadow-sm) kullanılacak.

# DATABASE MODELS & RELATIONS
1. Board (Pano): `name:string` `description:text` (has_many :lists)
2. List (Liste): `name:string` `position:integer` `board_id:references` (belongs_to :board, has_many :cards)
3. Card (Kart): `title:string` `description:text` `due_date:datetime` `position:integer` `status:integer(enum: normal, escalated, completed)` `list_id:references` (belongs_to :list)

# CORE WORKFLOW (AORT DİLİMİ)
1. Kanban Akışı: Board içinde List'ler yatay olarak dizilir. List içinde Card'lar dikey olarak listelenir.
2. Drag & Drop: Kullanıcı kartları listeler arasında veya aynı liste içinde sürükleyip bırakabilir. İşlem Turbo/Stimulus ile sayfa yenilenmeden veritabanındaki `list_id` ve `position` değerlerini günceller.
3. 100 Puanlık Acı Çözümü (Otomatik Eskalasyon): Kartlara atanan `due_date` (bitiş tarihi) geçmişse ve kart "Done/Completed" listesinde değilse, arka planda çalışan bir sistem (Solid Queue) bu kartı otomatik olarak panonun en başındaki "Gecikenler (Escalated)" isimli listeye taşır ve durumunu günceller.

# TESTING CONSTRAINTS
- CI/CD: GitHub Actions için `.github/workflows/ci.yml` dosyası oluşturulacak. Testlerin yeşil olması ve README'ye rozet eklenmesi zorunludur.
- Zaman Kuralları: Minitest'te `travel_to` kullanılarak zamanın ileri sarıldığı (ör. 2 gün sonrasına) ve due_date'i geçen kartların Escalated listesine otomatik düştüğü senaryo test edilmelidir.
- Durum Akışı Testleri: Kartın bir listeden diğerine geçerken position ve list_id güncellemelerinin doğru çalıştığı test edilmelidir.

# GELİŞTİRME SIRASINDA VERİLEN KARARLAR (planın değişen kısımları)
Bu bölüm, başlangıç planından sapılan yerleri ve nedenlerini kaydeder.

- Turbo Streams / ActionCable yerine Turbo 8 Morphing: Her işlemden sonra sayfa `turbo_refreshes_with method: :morph, scroll: :preserve` ile yenilenir. Yayın (broadcast) için Redis veya ayrı bir Solid Cable veritabanı gerekirdi; Render'ın ücretsiz planı tek PostgreSQL veriyor. Bedeli: başka sekmedeki kullanıcı değişikliği sayfayı yenileyince görür.
- Sürükle-bırak "sayfa yenilenmeden" değil: Kart anında taşınır, istek başarılı olunca pano morph ile tazelenir (sayaçlar ve durum rozetleri güncellensin diye). Hata olursa kart eski yerine döner.
- Durum akışı: Done listesine giren kart `completed` olur ve kontrol listesi işaretlenir; Done'dan çıkan kart `normal` olur. Bu kural `Card#status_in` metodunda tek yerde tutulur.
- Ek özellikler (Trello'nun temel iş birliği özellikleri): etiketler, üyeler/görev atama, kontrol listesi, kart detay paneli, liste yönetimi, listeye rastgele pastel renk.
- Kart yaşlandırma (pano kirliliği): 2 günden uzun süredir dokunulmamış açık kartlar soluklaşır; her etkileşim `updated_at`'i günceller ve kartı uyandırır.
- Canlı demo: `travel_to` yalnızca testte çalıştığından, job'a `at:` parametresi ve panoya "SLA kontrolü" ile "⏩ 2 gün ileri sar" butonları eklendi. Zamanı ileri sarma butonu yalnızca geliştirme ortamında veya `DEMO_MODE` açıkken görünür.
- Tek veritabanı deploy: Rails 8 production'da dört veritabanı bekler; Render tek `DATABASE_URL` verir. Solid Queue tabloları migration ile ana veritabanına taşındı, Solid Queue Puma içinde çalışır (`SOLID_QUEUE_IN_PUMA`), önbellek bellek içinde, Action Cable `async`.
- Testler: Sistem (tarayıcı) testleri yazılmadı; sürükle-bırak elle doğrulandı. Model, controller ve job testleri GitHub Actions'ta çalışır.

# AJANLA ÇALIŞMA KURALLARI
- Ajan "yaptım" dediğinde sonuç tarayıcıda veya test çıktısıyla kontrol edilir; doğrulanmamış iddia README'ye yazılmaz.
- README'deki her rakamın yanında kaynağı olur; kaynak bulunamayan rakam "tahmin" olarak işaretlenir veya yazılmaz.
- Gizli dosyalar (`config/master.key`, `.env`) commit edilmez; anahtarlar Render ortam değişkeni olarak verilir.