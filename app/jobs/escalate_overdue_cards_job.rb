class EscalateOverdueCardsJob < ApplicationJob
  queue_as :default

  # Returns how many cards were escalated. `at` lets a demo look at the board as of a later moment.
  def perform(board_id: nil, at: Time.current)
    boards = (board_id ? Board.where(id: board_id) : Board.all).human
    boards.find_each.sum { |board| escalate_overdue_cards(board, at) }
  end

  private
    def escalate_overdue_cards(board, at)
      Board.transaction do
        cards = overdue_cards(board, at).to_a
        next 0 if cards.empty?

        overdue_list = board.lists.find_or_create_by!(name: List::OVERDUE_NAME) { |list| list.position = 0 }
        source_lists = cards.map(&:list).uniq
        next_position = overdue_list.cards.maximum(:position).to_i

        cards.each do |card|
          next_position += 1
          card.update!(list: overdue_list, status: :escalated, position: next_position)
        end

        source_lists.each(&:reorder_cards!)
        cards.size
      end
    end

    # Normal cards due before the given day that are not already finished or escalated.
    def overdue_cards(board, at)
      Card.normal
        .joins(:list)
        .includes(:list)
        .where(lists: { board_id: board.id })
        .where.not(lists: { name: [ List::OVERDUE_NAME, List::DONE_NAME ] })
        .where(due_date: ...at.beginning_of_day)
        .order("lists.position", :position)
    end
end
