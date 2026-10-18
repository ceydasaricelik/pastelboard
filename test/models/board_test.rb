require "test_helper"

class BoardTest < ActiveSupport::TestCase
  test "a new board gets the default labels" do
    board = Board.create!(name: "Yeni pano")

    assert_equal Board::DEFAULT_LABELS.keys, board.labels.map(&:name)
  end
end
