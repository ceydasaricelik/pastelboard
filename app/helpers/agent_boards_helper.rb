module AgentBoardsHelper
  STATE_LABELS = {
    "open" => "Havuzda",
    "in_review" => "İncelemede",
    "rework" => "Düzeltmede",
    "needs_human" => "İnsana devredildi",
    "done" => "Tamam"
  }.freeze

  STATE_TONES = {
    "open" => "bg-sky-100 text-sky-700",
    "in_review" => "bg-violet-100 text-violet-700",
    "rework" => "bg-amber-100 text-amber-700",
    "needs_human" => "bg-rose-100 text-rose-700",
    "done" => "bg-emerald-100 text-emerald-700"
  }.freeze

  ROLE_LABELS = { "worker" => "İşçi", "mentor" => "Mentor" }.freeze

  EVENT_TONES = {
    "llm_error" => "bg-rose-100 text-rose-700",
    "watchdog" => "bg-amber-100 text-amber-700",
    "loop" => "bg-amber-100 text-amber-700",
    "question" => "bg-amber-100 text-amber-700",
    "escalated" => "bg-amber-100 text-amber-700",
    "revised" => "bg-violet-100 text-violet-700",
    "passed" => "bg-emerald-100 text-emerald-700",
    "approved" => "bg-emerald-100 text-emerald-700"
  }.freeze

  REVIEW_EVENT_KINDS = %w[ passed revised watchdog escalated ].freeze

  # "simülasyon modu", or the real models the board's agents run on.
  def agent_mode_label(board)
    return "simülasyon modu" if AgentBoards::LlmFactory.simulated?

    worker = board.members.detect(&:worker?)&.model || AgentBoards::Models.worker
    mentor = board.members.detect(&:mentor?)&.model || AgentBoards::Models.mentor
    "Groq · #{worker} / #{mentor}"
  end

  def agent_state_badge(card)
    state = card.agent_state.to_s
    tag.span STATE_LABELS.fetch(state, "—"),
      class: "#{STATE_TONES.fetch(state, "bg-slate-100 text-slate-500")} inline-block rounded-full px-2 py-0.5 text-[11px] font-semibold"
  end

  def agent_role_label(member)
    ROLE_LABELS.fetch(member.role.to_s, "İnsan")
  end

  def agent_event_tone(event)
    EVENT_TONES.fetch(event.kind, "bg-slate-100 text-slate-500")
  end

  def agent_event_actor(event)
    event.actor&.name || (%w[ hint_given approved ].include?(event.kind) ? "İnsan" : "Sistem")
  end

  # The most recent mentor verdict on the card, which holds the per-criterion results.
  def latest_review_event(card)
    card.agent_events.select { |event| REVIEW_EVENT_KINDS.include?(event.kind) }.last
  end

  # item_id => { "met" => true/false, "reason" => "..." } from the latest review.
  def review_criteria(card)
    (latest_review_event(card)&.data&.dig("criteria") || []).index_by { |criterion| criterion["item_id"] }
  end

  def lesson_lines(member)
    member.lessons.to_s.lines.map { |line| line.strip.delete_prefix("- ") }.reject(&:blank?)
  end

  def guideline_lines(board)
    board.guidelines.to_s.lines.map { |line| line.strip.delete_prefix("- ") }.reject(&:blank?)
  end
end
