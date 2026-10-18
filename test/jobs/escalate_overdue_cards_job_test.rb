require "test_helper"

class EscalateOverdueCardsJobTest < ActiveJob::TestCase
  setup do
    @board = Board.create!(name: "Eskalasyon Panosu")
    @todo = @board.lists.create!(name: "To Do", position: 1)
    @done = @board.lists.create!(name: "Done", position: 3)
  end

  test "moves a card to Gecikenler and escalates it once its due date has passed" do
    card = @todo.cards.create!(title: "Yarın teslim", due_date: 1.day.from_now, position: 1, status: :normal)

    EscalateOverdueCardsJob.perform_now
    assert_equal @todo, card.reload.list
    assert_predicate card, :normal?
    assert_not @board.lists.exists?(name: "Gecikenler"), "list should only be created when a card is overdue"

    travel_to 2.days.from_now do
      EscalateOverdueCardsJob.perform_now
    end

    card.reload
    overdue_list = @board.lists.find_by!(name: "Gecikenler")
    assert_equal overdue_list, card.list
    assert_predicate card, :escalated?
    assert_equal 1, card.position
    assert_equal 0, overdue_list.position
  end

  test "can look ahead in time and be limited to one board" do
    card = @todo.cards.create!(title: "Yarın teslim", due_date: 1.day.from_now, position: 1)
    other_board = Board.create!(name: "Başka pano")
    other_card = other_board.lists.create!(name: "To Do", position: 1).cards.create!(title: "Başka", due_date: 1.day.from_now, position: 1)

    assert_equal 1, EscalateOverdueCardsJob.perform_now(board_id: @board.id, at: 2.days.from_now)

    assert_predicate card.reload, :escalated?
    assert_predicate other_card.reload, :normal?
  end

  test "leaves overdue cards in the Done list untouched" do
    card = @done.cards.create!(title: "Zaten bitti", due_date: 2.days.ago, position: 1, status: :normal)

    EscalateOverdueCardsJob.perform_now

    card.reload
    assert_equal @done, card.list
    assert_predicate card, :normal?
  end
end
