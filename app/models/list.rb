class List < ApplicationRecord
  DONE_NAME = "Done"
  OVERDUE_NAME = "Gecikenler"
  COLORS = %w[ sky rose teal lime indigo fuchsia cyan pink ].freeze

  belongs_to :board
  has_many :cards, -> { order(position: :asc) }, dependent: :destroy

  validates :name, presence: true

  before_create { self.color ||= pick_color }

  def done?
    name == DONE_NAME
  end

  def overdue?
    name == OVERDUE_NAME
  end

  # Renumbers this list's cards as 1..n, following the given id order.
  def reorder_cards!(ids = cards.pluck(:id))
    ids.each.with_index(1) { |id, position| cards.where(id: id).update_all(position: position) }
  end

  private
    # A random color that no other list on the board is using yet, when one is left.
    def pick_color
      taken = board.lists.where.not(id: id).pluck(:color)
      (COLORS - taken).sample || COLORS.sample
    end
end
