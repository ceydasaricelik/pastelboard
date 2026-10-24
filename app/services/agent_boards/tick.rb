module AgentBoards
  # One round of work on an agent board: every card that needs attention advances by a single step.
  # Reviews go first, then reworks, then new cards from the pool; at most MAX_CARDS cards per round
  # and at most one card per worker.
  #
  # Each card moves under a row lock (the LLM call included) and its state is checked again once the
  # lock is held, so two rounds running at once never work the same card twice. When the model fails,
  # the card's changes are rolled back, an "llm_error" event is written and the round goes on.
  class Tick
    MAX_CARDS = 3
    MAX_ATTEMPTS = 2
    STATES = %w[ in_review rework open ].freeze
    VERDICTS = %w[ pass revise escalate ].freeze
    # Tolerates case, ASCII "I", a stray combining dot and leading punctuation.
    MISSING_INFO = /\A[^[:alnum:]]*B[İIiı]̇?LG[İIiı]̇?\s+EKS[İIiı]̇?K\s*:\s*(.*)\z/mi

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

    # The cards that need a step right now, in the order a round takes them.
    def candidates
      scope = Card.joins(:list).where(lists: { board_id: @board.id })
      STATES.flat_map { |state| scope.where(agent_state: state).order(:position, :id).to_a }
    end

    # What a round did: cards that moved a step, and cards whose model call failed.
    Summary = Struct.new(:advanced, :errors) do
      def to_s
        [ "#{advanced} kart ilerledi", ("#{errors} LLM hatası" if errors > 0) ].compact.join(", ")
      end
    end

    # `cards` is the snapshot to work through. A failed model call counts toward MAX_CARDS but not
    # as progress; a card someone else already moved counts for neither.
    def call(cards = candidates)
      busy = Set.new
      summary = Summary.new(0, 0)

      cards.each do |card|
        break if summary.advanced + summary.errors >= MAX_CARDS

        case step(card, busy)
        when :advanced then summary.advanced += 1
        when :error then summary.errors += 1
        end
      end
      summary
    end

    private
      def step(card, busy)
        expected = card.agent_state

        moved = card.with_lock do
          next false unless card.agent_state == expected

          case expected
          when "in_review" then review(card)
          when "rework" then rework(card, busy)
          when "open" then take_from_pool(card, busy)
          else false
          end
        end
        moved ? :advanced : :skipped
      rescue LlmError => error
        stage = expected == "in_review" ? "review" : "write"
        log(card.reload, "llm_error", "LLM hatası (#{stage}): #{error.message.truncate(300)}", stage: stage)
        :error
      end

      def review(card)
        mentor = @board.members.agent.mentor.first
        return false unless mentor

        result = normalize(@llm.review(card: card, mentor: mentor, prompt: Prompts.review(card)), card)
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
        write(card.reload, worker)
        true
      end

      def write(card, worker)
        output = @llm.write(card: card, worker: worker, prompt: Prompts.write(card, worker)).to_s.strip
        attempts = card.attempts + 1

        if (question = missing_info_question(output))
          card.agent_transition!(:needs_human, attempts: attempts, output: output, feedback: question)
          log(card, "question", "Ajan insana soru sordu: #{question}", actor: worker, attempts: attempts, question: question)
        elsif card.output.present? && same_text?(card.output, output)
          card.agent_transition!(:needs_human, attempts: attempts)
          log(card, "loop", "#{worker.name} öncekiyle aynı çıktıyı yeniden teslim etti; insana devredildi.", actor: worker, attempts: attempts)
        else
          card.agent_transition!(:in_review, attempts: attempts, output: output)
          log(card, "written", "#{worker.name} çıktıyı teslim etti (deneme #{attempts}).", actor: worker, attempts: attempts)
        end
      end

      def apply_review(card, mentor, result)
        worker = card.assignee
        data = { verdict: result[:verdict], criteria: result[:criteria], lesson: result[:lesson],
                 guideline_violations: result[:guideline_violations] }
        data[:overridden_from] = result[:overridden_from] if result[:overridden_from]

        case result[:verdict]
        when "pass"
          card.agent_transition!(:done, feedback: result[:feedback])
          log(card, "passed", "#{mentor.name} teslimi onayladı.", actor: mentor, **data)
        when "revise"
          worker&.add_lesson!(result[:lesson])
          if card.attempts >= MAX_ATTEMPTS
            card.agent_transition!(:needs_human, feedback: result[:feedback])
            log(card, "watchdog", "#{card.attempts}. denemede de düzelmedi; insana devredildi.", actor: mentor, **data)
          else
            card.agent_transition!(:rework, feedback: result[:feedback])
            log(card, "revised", revise_message(mentor, result), actor: mentor, **data)
          end
        when "escalate"
          card.agent_transition!(:needs_human, feedback: result[:feedback])
          log(card, "escalated", "#{mentor.name} kartı insana devretti.", actor: mentor, **data)
        end
      end

      # Checks the mentor's answer: an unknown verdict is an LLM error; criteria that point at items
      # the card does not have are dropped.
      def normalize(result, card)
        raise LlmError, "mentor cevabı bir nesne değil" unless result.is_a?(Hash)

        result = result.with_indifferent_access
        verdict = result[:verdict].to_s
        raise LlmError, "geçersiz verdict: #{verdict.truncate(40).inspect}" unless VERDICTS.include?(verdict)

        item_ids = card.checklist_items.map(&:id)
        criteria = result[:criteria].is_a?(Array) ? result[:criteria] : []
        criteria = criteria.grep(Hash).map(&:with_indifferent_access).select { |criterion| item_ids.include?(criterion[:item_id].to_i) }

        criteria = criteria.map { |c| { item_id: c[:item_id].to_i, met: c[:met] == true, reason: c[:reason].to_s } }
        violations = Array(result[:guideline_violations]).map { |violation| violation.to_s.squish }.reject(&:blank?)
        normalized = { verdict: verdict, criteria: criteria, feedback: result[:feedback].to_s.presence,
                       lesson: result[:lesson].to_s.presence, guideline_violations: violations }
        enforce_pass_rules(normalized, card)
      end

      # A pass is only a pass when no criterion was marked unmet and no team guideline was broken.
      def enforce_pass_rules(result, card)
        unmet = result[:criteria].reject { |criterion| criterion[:met] }
        violations = result[:guideline_violations]
        return result unless result[:verdict] == "pass" && (unmet.any? || violations.any?)

        contents = card.checklist_items.index_by(&:id)
        reasons = []
        reasons << "Karşılanmayan kriterler: #{unmet.map { |criterion| contents[criterion[:item_id]].content }.join('; ')}" if unmet.any?
        reasons << "Ekip rehberi ihlali: #{violations.join('; ')}" if violations.any?
        result.merge(verdict: "revise", overridden_from: "pass", feedback: result[:feedback] || reasons.join(". "))
      end

      def revise_message(mentor, result)
        return "#{mentor.name} düzeltme istedi." unless result[:overridden_from]

        unmet = result[:criteria].any? { |criterion| !criterion[:met] }
        "#{mentor.name} pass dedi ama " + (unmet ? "karşılanmayan kriter var" : "ekip rehberine aykırılık var") + "; düzeltme istendi."
      end

      # "BİLGİ EKSİK: <question>" at the very start of a delivery means the worker is asking a person.
      def missing_info_question(output)
        match = output.match(MISSING_INFO)
        match && (match[1].squish.presence || "Eksik bilgi belirtilmedi.")
      end

      def log(card, kind, message, actor: nil, **data)
        if @llm.simulated?
          message = "#{message} (simülasyon modu)"
          data[:simulation] = true
        end
        card.log_event(kind, message, actor: actor, **data)
      end

      def same_text?(first, second)
        first.squish.casecmp?(second.squish)
      end
  end
end
