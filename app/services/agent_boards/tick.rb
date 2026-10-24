module AgentBoards
  # One round of work on an agent board: every card that needs attention advances by a single step.
  # Reviews go first, then reworks, then new cards from the pool; at most MAX_CARDS cards per round
  # and at most one card per worker.
  class Tick
    MAX_CARDS = 3
    MAX_ATTEMPTS = 2
    STATES = %w[ in_review rework open ].freeze

    # Takes an open card for the worker. Only one of several competing workers gets true.
    def self.claim(card, worker)
      Card.where(id: card.id, agent_state: :open, assignee_id: nil)
        .update_all(assignee_id: worker.id, updated_at: Time.current) == 1
    end

    def initialize(board, llm:)
      raise ArgumentError, "#{board.name} is not an agent board" unless board.agent?

      @board = board
      @llm = llm
    end

    # Returns how many cards moved one step.
    def call
      busy = Set.new
      moved = 0

      candidates.each do |card|
        break if moved >= MAX_CARDS

        moved += 1 if step(card, busy)
      end
      moved
    end

    private
      def candidates
        scope = Card.joins(:list).where(lists: { board_id: @board.id })
        STATES.flat_map { |state| scope.where(agent_state: state).order(:position, :id).to_a }
      end

      def step(card, busy)
        case card.agent_state
        when "in_review" then review(card)
        when "rework" then rework(card, busy)
        when "open" then take_from_pool(card, busy)
        end
      end

      def review(card)
        mentor = @board.members.agent.mentor.first
        return false unless mentor

        prompt = Prompts.review(card)
        result = normalize(@llm.review(card: card, mentor: mentor, prompt: prompt))
        apply_review(card, mentor, result)
        true
      end

      # The card's owner writes it again, with its own feedback and notebook.
      def rework(card, busy)
        worker = card.assignee
        return false if worker.nil? || busy.include?(worker.id)

        busy << worker.id
        write(card, worker)
        true
      end

      def take_from_pool(card, busy)
        worker = @board.members.agent.worker.where.not(id: busy.to_a).detect { |candidate| self.class.claim(card, candidate) }
        return false unless worker

        busy << worker.id
        begin
          write(card.reload, worker)
        rescue StandardError
          card.update_columns(assignee_id: nil)
          raise
        end
        true
      end

      def write(card, worker)
        output = @llm.write(card: card, worker: worker, prompt: Prompts.write(card, worker)).to_s.strip
        attempts = card.attempts + 1

        Card.transaction do
          if card.output.present? && same_text?(card.output, output)
            card.agent_transition!(:needs_human, attempts: attempts)
            card.log_event("loop", "#{worker.name} öncekiyle aynı çıktıyı yeniden teslim etti; insana devredildi.", actor: worker, attempts: attempts)
          else
            card.agent_transition!(:in_review, attempts: attempts, output: output)
            card.log_event("written", "#{worker.name} çıktıyı teslim etti (deneme #{attempts}).", actor: worker, attempts: attempts)
          end
        end
      end

      def apply_review(card, mentor, result)
        worker = card.assignee
        data = { verdict: result[:verdict], criteria: result[:criteria], lesson: result[:lesson] }

        Card.transaction do
          case result[:verdict]
          when "pass"
            card.agent_transition!(:done, feedback: result[:feedback])
            card.log_event("passed", "#{mentor.name} teslimi onayladı.", actor: mentor, **data)
          when "revise"
            worker&.add_lesson!(result[:lesson])
            if card.attempts >= MAX_ATTEMPTS
              card.agent_transition!(:needs_human, feedback: result[:feedback])
              card.log_event("watchdog", "#{card.attempts}. denemede de düzelmedi; insana devredildi.", actor: mentor, **data)
            else
              card.agent_transition!(:rework, feedback: result[:feedback])
              card.log_event("revised", "#{mentor.name} düzeltme istedi.", actor: mentor, **data)
            end
          when "escalate"
            card.agent_transition!(:needs_human, feedback: result[:feedback])
            card.log_event("escalated", "#{mentor.name} kartı insana devretti.", actor: mentor, **data)
          else
            raise ArgumentError, "Unknown verdict: #{result[:verdict].inspect}"
          end
        end
      end

      def normalize(result)
        result = result.to_h.with_indifferent_access
        {
          verdict: result[:verdict].to_s,
          criteria: Array(result[:criteria]).map(&:to_h),
          feedback: result[:feedback].to_s.presence,
          lesson: result[:lesson].to_s.presence
        }
      end

      def same_text?(first, second)
        first.squish.casecmp?(second.squish)
      end
  end
end
