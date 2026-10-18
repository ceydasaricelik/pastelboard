class MembersController < ApplicationController
  before_action :set_board

  # POST /boards/1/members
  def create
    member = @board.members.new(params.expect(member: [ :name ]))

    if member.save
      redirect_to @board, status: :see_other
    else
      redirect_to @board, alert: member.errors.full_messages.to_sentence, status: :see_other
    end
  end

  # DELETE /boards/1/members/1
  def destroy
    @board.members.find(params.expect(:id)).destroy!
    redirect_to @board, status: :see_other
  end

  private
    def set_board
      @board = Board.find(params.expect(:board_id))
    end
end
