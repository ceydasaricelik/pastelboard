class Card < ApplicationRecord
  belongs_to :list
  has_many :card_labels, dependent: :destroy
  has_many :labels, -> { order(:id) }, through: :card_labels
  has_many :card_members, dependent: :destroy
  has_many :members, -> { order(:name) }, through: :card_members
  has_many :checklist_items, -> { order(:position) }, dependent: :destroy

  DORMANT_AFTER = 2.days

  enum :status, { normal: 0, escalated: 1, completed: 2 }, default: :normal

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

  private
    def complete_checklist
      checklist_items.where(done: false).update_all(done: true, updated_at: Time.current)
    end
end
