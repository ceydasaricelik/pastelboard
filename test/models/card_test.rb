require "test_helper"

class CardTest < ActiveSupport::TestCase
  test "an open card untouched for more than two days is dormant" do
    cards(:one).update_column(:updated_at, 3.days.ago)

    assert_predicate cards(:one), :dormant?
    assert_equal 3, cards(:one).dormant_days
  end

  test "a recently updated card or a completed one is not dormant" do
    cards(:one).update_column(:updated_at, 1.day.ago)
    assert_not cards(:one).dormant?

    cards(:two).update_columns(updated_at: 5.days.ago, status: Card.statuses[:completed])
    assert_not cards(:two).dormant?
  end

  test "ticking a checklist item wakes the card" do
    cards(:one).update_column(:updated_at, 3.days.ago)

    checklist_items(:draft).update!(done: true)

    assert_not cards(:one).reload.dormant?
  end
end
