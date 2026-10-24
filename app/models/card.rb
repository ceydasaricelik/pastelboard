class Card < ApplicationRecord
  belongs_to :list
  has_many :card_labels, dependent: :destroy
  has_many :labels, -> { order(:id) }, through: :card_labels
  has_many :card_members, dependent: :destroy
  has_many :members, -> { order(:name) }, through: :card_members
  has_many :checklist_items, -> { order(:position) }, dependent: :destroy
  belongs_to :assignee, class_name: "Member", optional: true
  has_many :agent_events, -> { order(:id) }, dependent: :destroy

  DORMANT_AFTER = 2.days

  enum :status, { normal: 0, escalated: 1, completed: 2 }, default: :normal
  # Only cards on an agent board have one; it decides which of the board's fixed lists the card sits in.
  enum :agent_state, { open: 0, in_review: 1, rework: 2, needs_human: 3, done: 4 }, prefix: :agent

  validates :title, presence: true

  # Finishing a card finishes its checklist too.
  after_save :complete_checklist, if: -> { saved_change_to_status?(to: "completed") }

  def board
    list.board
  end

  # An open card nobody has touched for a while — it fades out on the board until someone works on it.
  def dormant?
    !completed? && updated_at.present? && updated_at < DORMANT_AFTER.ago
  end

  def dormant_days
    ((Time.current - updated_at) / 1.day).floor
  end

  def overdue?
    due_date.present? && !completed? && due_date.to_date < Date.current
  end

  # The status a card takes on when it lands in the given list.
  def status_in(list)
    return "completed" if list.done?
    return "escalated" if list.overdue?

    completed? ? "normal" : status
  end

  # Moves an agent-board card to the list that matches the state, at the end of it.
  def agent_transition!(state, **attributes)
    source = list
    target = board.agent_list(state)
    position = target.cards.maximum(:position).to_i + 1

    update!(attributes.merge(agent_state: state, list: target, position: position, status: status_in(target)))
    source.reorder_cards! unless source == target
  end

  def log_event(kind, message, actor: nil, **data)
    agent_events.create!(kind: kind, message: message, actor: actor, data: data)
  end

  private
    def complete_checklist
      checklist_items.where(done: false).update_all(done: true, updated_at: Time.current)
    end
end
