require "test_helper"

class CardsControllerTest < ActionDispatch::IntegrationTest
  test "move reorders cards within the same list" do
    patch move_card_url(cards(:two)), params: { list_id: lists(:todo).id, position: 1 }, as: :json

    assert_response :ok
    assert_equal [ cards(:two), cards(:one) ], lists(:todo).cards.to_a
    assert_equal [ 1, 2 ], lists(:todo).cards.pluck(:position)
  end

  test "reordering a dormant card within its list wakes it" do
    cards(:two).update_column(:updated_at, 3.days.ago)

    patch move_card_url(cards(:two)), params: { list_id: lists(:todo).id, position: 1 }, as: :json

    assert_not cards(:two).reload.dormant?
  end

  test "move puts a card into another list and renumbers the old one" do
    patch move_card_url(cards(:one)), params: { list_id: lists(:done).id, position: 1 }, as: :json

    assert_response :ok
    assert_equal lists(:done), cards(:one).reload.list
    assert_equal 1, cards(:one).position
    assert_equal 1, cards(:two).reload.position
  end

  test "move into Done completes the card and moving out makes it normal again" do
    patch move_card_url(cards(:one)), params: { list_id: lists(:done).id, position: 1 }, as: :json
    assert_response :ok
    assert_predicate cards(:one).reload, :completed?
    assert checklist_items(:draft).reload.done, "moving a card to Done should tick its checklist"

    patch move_card_url(cards(:one)), params: { list_id: lists(:todo).id, position: 1 }, as: :json
    assert_response :ok
    assert_predicate cards(:one).reload, :normal?
    assert checklist_items(:draft).reload.done, "moving back out keeps the ticked items"
  end

  test "move answers 422 when the card cannot be saved" do
    cards(:one).update_column(:title, "")

    patch move_card_url(cards(:one)), params: { list_id: lists(:done).id, position: 1 }, as: :json

    assert_response :unprocessable_content
    assert_equal lists(:todo), cards(:one).reload.list
  end

  test "create adds a card to the bottom of the list" do
    assert_difference("lists(:todo).cards.count") do
      post board_list_cards_url(boards(:one), lists(:todo)), params: { card: { title: "Yeni görev", due_date: "2026-11-01" } }
    end

    assert_redirected_to board_url(boards(:one))
    card = lists(:todo).cards.last
    assert_equal [ "Yeni görev", 3, Date.new(2026, 11, 1) ], [ card.title, card.position, card.due_date.to_date ]
  end

  test "create without a title redirects back with an alert" do
    assert_no_difference("Card.count") do
      post board_list_cards_url(boards(:one), lists(:todo)), params: { card: { title: "" } }
    end

    assert_redirected_to board_url(boards(:one))
    assert_not_nil flash[:alert]
  end

  test "move rejects a list from another board" do
    patch move_card_url(cards(:one)), params: { list_id: lists(:other).id, position: 1 }, as: :json

    assert_response :not_found
    assert_equal lists(:todo), cards(:one).reload.list
  end
end
