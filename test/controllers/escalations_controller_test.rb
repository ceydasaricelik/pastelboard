require "test_helper"

class EscalationsControllerTest < ActionDispatch::IntegrationTest
  test "runs the SLA rule for the board right away" do
    cards(:one).update!(due_date: 1.day.ago)

    post board_escalation_url(boards(:one))

    assert_redirected_to board_url(boards(:one))
    assert_equal "SLA kontrolü: 1 kart Gecikenler listesine taşındı.", flash[:notice]
    assert_predicate cards(:one).reload, :escalated?
  end

  test "ignores time travel outside development and demo mode" do
    post board_escalation_url(boards(:one), days: 30)

    assert_equal "SLA kontrolü: geciken kart yok.", flash[:notice]
    assert_predicate cards(:one).reload, :normal?
  end
end
