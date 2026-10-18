require "test_helper"

class ListsControllerTest < ActionDispatch::IntegrationTest
  test "create adds a list after the existing ones with a color no other list uses" do
    lists(:todo).update_column(:color, "sky")

    assert_difference("boards(:one).lists.count") do
      post board_lists_url(boards(:one)), params: { list: { name: "Review" } }
    end

    assert_redirected_to board_url(boards(:one))
    list = boards(:one).lists.find_by!(name: "Review")
    assert_equal 3, list.position
    assert_includes List::COLORS - [ "sky" ], list.color
  end

  test "update renames a list" do
    patch board_list_url(boards(:one), lists(:todo)), params: { list: { name: "Backlog" } }

    assert_redirected_to board_url(boards(:one))
    assert_equal "Backlog", lists(:todo).reload.name
  end

  test "destroy removes the list with its cards" do
    assert_difference([ "List.count" ], -1) do
      assert_difference("Card.count", -2) do
        delete board_list_url(boards(:one), lists(:todo))
      end
    end

    assert_redirected_to board_url(boards(:one))
  end
end
