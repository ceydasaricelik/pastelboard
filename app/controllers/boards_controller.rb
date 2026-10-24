class BoardsController < ApplicationController
  before_action :set_board, only: %i[ show edit update destroy ]

  def index
    @boards = Board.all
  end

  def show
    @lists = @board.lists.includes(cards: [ :labels, :members, :checklist_items ])
    render "boards/agent_show" if @board.agent?
  end

  def new
    @board = Board.new
  end

  def edit
  end

  def create
    @board = Board.new(board_params)

    respond_to do |format|
      if @board.save
        format.html { redirect_to @board, notice: "Board was successfully created." }
        format.json { render :show, status: :created, location: @board }
      else
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @board.errors, status: :unprocessable_content }
      end
    end
  end

  def update
    respond_to do |format|
      if @board.update(board_params)
        format.html { redirect_to @board, notice: "Board was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @board }
      else
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @board.errors, status: :unprocessable_content }
      end
    end
  end

  def destroy
    @board.destroy!

    respond_to do |format|
      format.html { redirect_to boards_path, notice: "Board was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    def set_board
      @board = Board.find(params.expect(:id))
    end

    def board_params
      params.expect(board: [ :name, :description ])
    end
end
