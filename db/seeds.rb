board = Board.find_or_create_by!(name: "PastelBoard Lansmanı") do |b|
  b.description = "PastelBoard ürün lansmanı için görev panosu"
end

todo = board.lists.find_or_create_by!(name: "To Do") do |list|
  list.position = 1
end
todo.update!(position: 1)

doing = board.lists.find_or_create_by!(name: "Doing") do |list|
  list.position = 2
end
doing.update!(position: 2)

done = board.lists.find_or_create_by!(name: "Done") do |list|
  list.position = 3
end
done.update!(position: 3)

members = [ "Ayşe Yılmaz", "Mehmet Kaya", "Zeynep Demir" ].index_with do |name|
  board.members.find_or_create_by!(name: name)
end
labels = board.labels.index_by(&:name)

cards = [
  { list: todo, title: "Lansman duyurusunu yaz", description: "Blog ve sosyal medya metinleri", due_date: 1.day.ago, position: 1, status: :normal,
    labels: [ "Pazarlama", "Acil" ], members: [ "Ayşe Yılmaz" ], checklist: { "Blog taslağı" => true, "LinkedIn gönderisi" => false, "Basın bülteni" => false } },
  { list: todo, title: "Renk paletini sonlandır", description: "Pastel tonları ve kontrast kontrolü", due_date: 3.days.from_now, position: 2, status: :normal,
    labels: [ "Tasarım" ], members: [ "Zeynep Demir" ], checklist: {} },
  { list: doing, title: "Kanban arayüzünü tamamla", description: "Listeler ve kartlar Tailwind ile", due_date: 2.days.from_now, position: 1, status: :escalated,
    labels: [ "Geliştirme" ], members: [ "Mehmet Kaya", "Zeynep Demir" ], checklist: { "Sürükle-bırak" => true, "Kart detayı" => true, "Etiketler" => false } },
  { list: doing, title: "Örnek verileri hazırla", description: "Seed dosyasını doldur", due_date: 1.week.from_now, position: 2, status: :normal,
    labels: [ "Test" ], members: [ "Mehmet Kaya" ], checklist: {} },
  { list: done, title: "Veritabanı şemasını kur", description: "Board, List ve Card modelleri", due_date: 2.days.ago, position: 1, status: :completed,
    labels: [ "Geliştirme", "Doküman" ], members: [ "Mehmet Kaya" ], checklist: { "Migration'lar" => true, "İlişkiler" => true } }
]

cards.each do |attrs|
  # Cards may have been dragged around since the last seed, so look them up board-wide
  # and only place new ones; existing cards keep their list, position and status.
  card = Card.joins(:list).where(lists: { board_id: board.id }).find_or_initialize_by(title: attrs[:title])
  card.assign_attributes(attrs.slice(:list, :position, :status)) if card.new_record?
  card.assign_attributes(attrs.slice(:description, :due_date))
  card.labels = labels.values_at(*attrs[:labels]).compact
  card.members = members.values_at(*attrs[:members])
  card.save!

  attrs[:checklist].each do |content, done_flag|
    card.checklist_items.find_or_create_by!(content: content) { |item| item.done = done_flag || card.completed? }
  end
end
