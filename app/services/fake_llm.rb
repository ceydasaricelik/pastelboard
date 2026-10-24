# A stand-in for the real model. Without a scenario it plays the demo: a worker's first delivery
# gets "revise" and the second gets "pass"; the worker asks a person ("BİLGİ EKSİK:") on its first try at
# the card titled AgentBoards::DemoSeeder::MISSING_INFO_TITLE. Tests pass their own `writes:` and `reviews:`, answered in order.
class FakeLlm
  class ScenarioExhausted < StandardError; end

  attr_reader :prompts

  # writes: strings; reviews: hashes like { verdict: "pass", criteria: [], feedback: nil, lesson: nil }.
  def initialize(writes: nil, reviews: nil)
    @writes = writes&.dup
    @reviews = reviews&.dup
    @write_counts = Hash.new(0)
    @review_counts = Hash.new(0)
    @prompts = []
  end

  # Lets the board mark its events as simulation.
  def simulated?
    true
  end

  def write(card:, worker:, prompt:)
    @prompts << { kind: :write, card_id: card.id, worker_id: worker.id, prompt: prompt }
    return next_of(@writes, "writes") if @writes

    count = @write_counts[card.id] += 1
    if card.title == AgentBoards::DemoSeeder::MISSING_INFO_TITLE && count == 1
      "BİLGİ EKSİK: Ürünün adı ve özellikleri nedir?"
    elsif count == 1
      "#{card.title}: harika bir ürün! 🎉 Hemen keşfedin."
    else
      "#{card.title}: dayanıklı ve şık. Siparişlerde ücretsiz kargo sizi bekliyor. (sürüm #{count})"
    end
  end

  def review(card:, mentor:, prompt:)
    @prompts << { kind: :review, card_id: card.id, mentor_id: mentor.id, prompt: prompt }
    return next_of(@reviews, "reviews") if @reviews

    count = @review_counts[card.id] += 1
    items = card.checklist_items.to_a

    if count == 1 && card.board.guidelines.present?
      { verdict: "revise", criteria: criteria(items, unmet: []),
        feedback: "Ekip rehberine aykırı: her metin \"PastelShop\" kelimesiyle bitmeli.",
        lesson: "Her metni \"PastelShop\" kelimesiyle bitir.",
        guideline_violations: [ "Her metin \"PastelShop\" kelimesiyle bitsin" ] }
    elsif count == 1
      { verdict: "revise", criteria: criteria(items, unmet: items.first(1)),
        feedback: "Kriterlerden biri karşılanmıyor; metni kriterlere göre düzelt.",
        lesson: "Teslim etmeden önce her kabul kriterini tek tek kontrol et." }
    else
      { verdict: "pass", criteria: criteria(items, unmet: []), feedback: "Tüm kriterler karşılandı." }
    end
  end

  private
    def next_of(scenario, name)
      raise ScenarioExhausted, "FakeLlm has no more #{name} in its scenario" if scenario.empty?

      scenario.shift
    end

    def criteria(items, unmet:)
      items.map do |item|
        met = unmet.exclude?(item)
        { item_id: item.id, met: met, reason: met ? "Karşılandı." : "Karşılanmadı." }
      end
    end
end
