class EscalationsController < ApplicationController
  MAX_DEMO_DAYS = 30

  # POST /boards/1/escalation — runs the SLA rule for this board now, or (demo mode only) some days ahead.
  def create
    board = Board.find(params.expect(:board_id))
    days = helpers.demo_time_travel? ? params[:days].to_i.clamp(0, MAX_DEMO_DAYS) : 0
    escalated = EscalateOverdueCardsJob.perform_now(board_id: board.id, at: days.days.from_now)

    redirect_to board, notice: escalation_notice(escalated, days), status: :see_other
  end

  private
    def escalation_notice(escalated, days)
      moment = days.zero? ? "SLA kontrolü" : "#{days} gün sonrası için SLA kontrolü"
      escalated.zero? ? "#{moment}: geciken kart yok." : "#{moment}: #{escalated} kart Gecikenler listesine taşındı."
    end
end
