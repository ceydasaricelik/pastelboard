module AgentBoards
  # For the terminal: `ruby bin/rails runner "AgentBoards::DemoRun.call"` resets the demo board and runs one round.
  class DemoRun
    # Resets the demo board, runs one round and prints where every card stands.
    def self.call(llm: LlmFactory.build, out: $stdout)
      new(DemoSeeder.call, llm: llm, out: out).call
    end

    # One more round on the existing demo board.
    def self.tick(llm: LlmFactory.build, out: $stdout)
      new(Board.find_by!(name: DemoSeeder::BOARD_NAME), llm: llm, out: out).call
    end

    def initialize(board, llm:, out:)
      @board = board
      @llm = llm
      @out = out
    end

    def call
      @out.puts @llm.simulated? ? "Mod: simülasyon (GROQ_API_KEY yok)" : "Mod: Groq (gerçek LLM)"
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      summary = Tick.new(@board, llm: @llm).call
      elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
      @out.puts "Tur bitti: #{summary}. Süre: #{elapsed.round(1)} sn (kart sınırı: #{Tick.max_cards})."
      report
      summary
    end

    private
      def report
        cards = Card.where(list: @board.lists).includes(:agent_events).order(:id)
        cards.each do |card|
          @out.puts "- #{card.title} [#{card.agent_state}]"
          @out.puts "    son olay: #{card.agent_events.last&.message || '-'}"
        end
      end
  end
end
