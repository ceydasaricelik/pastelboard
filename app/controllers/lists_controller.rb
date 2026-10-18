class ListsController < ApplicationController
  before_action :set_board
  before_action :set_list, only: %i[ update destroy ]

  # POST /boards/1/lists
  def create
    @list = @board.lists.new(list_params)
    @list.position = @board.lists.maximum(:position).to_i + 1

    if @list.save
      redirect_to @board, status: :see_other
    else
      redirect_to @board, alert: @list.errors.full_messages.to_sentence, status: :see_other
    end
  end

  # PATCH /boards/1/lists/1
  def update
    if @list.update(list_params)
      redirect_to @board, status: :see_other
    else
      redirect_to @board, alert: @list.errors.full_messages.to_sentence, status: :see_other
    end
  end

  # DELETE /boards/1/lists/1
  def destroy
    @list.destroy!
    redirect_to @board, notice: "\"#{@list.name}\" listesi silindi.", status: :see_other
  end

  private
    def set_board
      @board = Board.find(params.expect(:board_id))
    end

    def set_list
      @list = @board.lists.find(params.expect(:id))
    end

    def list_params
      params.expect(list: [ :name ])
    end
end
