require "test_helper"

class CardDetailsTest < ActionDispatch::IntegrationTest
  test "show renders the board with the card detail open" do
    get card_url(cards(:one))

    assert_response :success
    assert_select "#card_detail input[name='card[title]'][value=?]", cards(:one).title
    assert_select "section#list_#{lists(:todo).id}"
  end

  test "update saves details and only keeps labels and members of the card's board" do
    patch card_url(cards(:one)), params: { card: {
      title: "Güncel başlık", description: "Ayrıntı", due_date: "2026-12-01",
      label_ids: [ labels(:design).id, labels(:foreign).id ],
      member_ids: [ members(:ayse).id, members(:outsider).id ]
    } }

    assert_redirected_to card_url(cards(:one))
    card = cards(:one).reload
    assert_equal [ "Güncel başlık", "Ayrıntı", Date.new(2026, 12, 1) ], [ card.title, card.description, card.due_date.to_date ]
    assert_equal [ labels(:design) ], card.labels.to_a
    assert_equal [ members(:ayse) ], card.members.to_a
  end

  test "update can clear all labels" do
    patch card_url(cards(:one)), params: { card: { label_ids: [ "" ] } }

    assert_empty cards(:one).reload.labels
  end

  test "destroy removes the card and renumbers its list" do
    assert_difference("Card.count", -1) do
      delete card_url(cards(:one))
    end

    assert_redirected_to board_url(boards(:one))
    assert_equal 1, cards(:two).reload.position
  end

  test "checklist items can be added, ticked and removed" do
    assert_difference("cards(:one).checklist_items.count") do
      post card_checklist_items_url(cards(:one)), params: { checklist_item: { content: "Gözden geçir" } }
    end
    assert_equal 2, cards(:one).checklist_items.last.position

    patch card_checklist_item_url(cards(:one), checklist_items(:draft)), params: { checklist_item: { done: true } }
    assert checklist_items(:draft).reload.done

    assert_difference("ChecklistItem.count", -1) do
      delete card_checklist_item_url(cards(:one), checklist_items(:draft))
    end
    assert_redirected_to card_url(cards(:one))
  end
end
