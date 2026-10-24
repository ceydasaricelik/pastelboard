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
        description: "Mağazamızdaki kablosuz kulaklık için kısa bir ürün açıklaması yaz.",
        criteria: [ "En fazla 40 kelime olsun", "\"ücretsiz kargo\" ifadesi geçsin", "Emoji kullanılmasın" ] },
      { title: "Termos şişe açıklaması",
        description: "Çelik termos şişe için ürün sayfasına konacak bir metin yaz.",
        criteria: [ "En az 20, en fazla 35 kelime olsun", "\"24 saat sıcak\" ifadesi geçsin", "Ünlem işareti kullanılmasın" ] },
      { title: "Kampanya e-postası konu satırı",
        description: "Hafta sonu indirimini duyuran e-posta için bir konu satırı yaz.",
        criteria: [ "En fazla 8 kelime olsun", "Soru işaretiyle bitsin", "Tamamı büyük harfle yazılmasın" ] },
      { title: MISSING_INFO_TITLE,
        description: "Yeni ürünümüz için kısa bir açıklama metni yaz.",
        criteria: [ "Ürünün adı geçsin", "Ürünün fiyatı belirtilsin", "En fazla 30 kelime olsun" ] }
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
