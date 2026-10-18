require "test_helper"

class MembersControllerTest < ActionDispatch::IntegrationTest
  test "create adds a member with initials and a color" do
    assert_difference("boards(:one).members.count") do
      post board_members_url(boards(:one)), params: { member: { name: "Mehmet Kaya" } }
    end

    member = boards(:one).members.find_by!(name: "Mehmet Kaya")
    assert_equal "MK", member.initials
    assert_includes Member::COLORS, member.color
  end

  test "destroy removes the member from the board and its cards" do
    assert_difference([ "Member.count", "CardMember.count" ], -1) do
      delete board_member_url(boards(:one), members(:ayse))
    end

    assert_redirected_to board_url(boards(:one))
  end
end
