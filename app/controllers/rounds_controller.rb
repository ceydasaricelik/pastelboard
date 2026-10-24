class RoundsController < ApplicationController
  # POST /boards/1/round — runs one round of the agent board now, with the real model when a key is set.
  def create
    board = Board.agent.find(params.expect(:board_id))
    summary = AgentBoards::Tick.new(board, llm: AgentBoards::LlmFactory.build).call

    redirect_to board, notice: "Tur bitti: #{summary}.", status: :see_other
  end
end
