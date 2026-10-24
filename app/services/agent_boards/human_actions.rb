module AgentBoards
  # What a person can do with a card an agent handed over.
  module HumanActions
    module_function

    # Sends the card back to its worker with a hint and a fresh set of attempts.
    def give_hint(card, hint)
      require_needs_human!(card)

      Card.transaction do
        feedback = [ card.feedback.presence, "İnsan ipucu: #{hint.to_s.strip}" ].compact.join("\n\n")
        card.agent_transition!(:rework, feedback: feedback, attempts: 0)
        card.log_event("hint_given", "İnsan ipucu verdi; kart düzeltmeye döndü.", hint: hint.to_s.strip)
      end
    end

    # Accepts the output as it is and finishes the card.
    def approve(card)
      require_needs_human!(card)

      Card.transaction do
        card.agent_transition!(:done)
        card.log_event("approved", "İnsan kartı onayladı.")
      end
    end

    def require_needs_human!(card)
      raise ArgumentError, "Card ##{card.id} is not waiting for a person" unless card.agent_needs_human?
    end
  end
end
