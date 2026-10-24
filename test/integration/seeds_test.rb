require "test_helper"

# db:seed runs on every deploy, so running it again must not pile up boards, members or cards.
class SeedsTest < ActiveSupport::TestCase
  def seed
    capture_io { load Rails.root.join("db/seeds.rb") }
  end

  test "seeding twice creates no duplicate boards, members, cards or agent boards" do
    seed
    counts = -> { [ Board, List, Card, Member, Label, ChecklistItem, AgentEvent ].map(&:count) }
    before = counts.call
    agent_boards = Board.agent.count

    seed

    assert_equal before, counts.call
    assert_equal agent_boards, Board.agent.count
    assert_equal 1, Board.where(name: "PastelBoard Lansmanı").count
  end
end
