module AgentBoards
  # Builds the demo agent board from scratch; running it again resets the board.
  class DemoSeeder
    BOARD_NAME = "Ajan Panosu (Demo)"
    # The card that cannot be finished without a person: its brief leaves out what the text is about.
    MISSING_INFO_TITLE = "Yeni ürün için açıklama metni"

    WORKERS = %w[ Ece Deniz ].freeze
    MENTOR = "Mentor Mert"

    TASKS = [
      { title: "Kablosuz kulaklık açıklaması",
        description: "Ürün: Nova X1 kablosuz kulaklık. Özellikler: 30 saat pil ömrü, aktif gürültü engelleme, 249 TL. " \
                     "Mağazamızdaki bu ürün için kısa bir ürün açıklaması yaz.",
        criteria: [ "Tam olarak 3 madde olsun (her madde ayrı satırda, \"-\" ile başlasın)", "Her madde en fazla 6 kelime olsun",
                    "\"harika\" kelimesi hiç geçmesin", "\"ücretsiz kargo\" ifadesi geçsin" ] },
      { title: "Termos şişe açıklaması",
        description: "Ürün: Kuzey çelik termos, 500 ml. Özellikler: çift cidarlı paslanmaz çelik, sızdırmaz kapak, içeceği 24 saat sıcak tutar. " \
                     "Ürün sayfasına konacak bir metin yaz.",
        criteria: [ "Tam olarak 2 cümle olsun", "Toplam 25 ile 30 kelime arasında olsun",
                    "\"24 saat sıcak\" ifadesi geçsin", "Ünlem işareti kullanılmasın" ] },
      { title: "Kampanya e-postası konu satırı",
        description: "Hafta sonu indirimini duyuran e-posta için bir konu satırı yaz.",
        criteria: [ "En fazla 8 kelime olsun", "Soru işaretiyle bitsin", "Tamamı büyük harfle yazılmasın" ] },
      { title: MISSING_INFO_TITLE,
        description: "Yeni ürünümüz için kısa bir açıklama metni yaz.",
        criteria: [ "Ürün adı ve özellikleri karttaki bilgiye dayanmalı, uydurma bilgi olmamalı", "Ürünün adı geçsin",
                    "En fazla 30 kelime olsun" ] }
    ].freeze

    def self.call
      new.call
    end

    def call
      Board.transaction do
        Board.find_by(name: BOARD_NAME)&.destroy!
        board = Board.create!(name: BOARD_NAME, kind: :agent,
                              description: "İşçi ajanlar havuzdan iş alır, mentor ajan teslimleri inceler.")
        board.ensure_agent_lists!
        create_members(board)
        TASKS.each { |task| create_card(board, task) }
        board
      end
    end

    private
      def create_members(board)
        WORKERS.each { |name| board.members.create!(name: name, kind: :agent, role: :worker, model: Models.worker) }
        board.members.create!(name: MENTOR, kind: :agent, role: :mentor, model: Models.mentor)
      end

      def create_card(board, task)
        pool = board.agent_list(:open)
        card = pool.cards.create!(title: task[:title], description: task[:description],
                                  agent_state: :open, position: pool.cards.maximum(:position).to_i + 1)
        task[:criteria].each { |criterion| card.checklist_items.create!(content: criterion) }
        card.log_event("created", "Kart havuza eklendi.")
      end
  end
end
