class AgentDemosController < ApplicationController
  # POST /agent_demo — builds the demo agent board, or resets it. Demo mode only: it deletes the old demo board.
  def create
    return head :not_found unless helpers.demo_time_travel?

    board = AgentBoards::DemoSeeder.call
    redirect_to board, notice: "Demo ajan panosu kuruldu.", status: :see_other
  end
end
