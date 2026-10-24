class CardsController < ApplicationController
  before_action :set_card, only: %i[ show update destroy move ]

  # GET /cards/1 — the board with this card's detail panel open
  def show
    @board = @card.board
    @lists = @board.lists.includes(cards: [ :labels, :members, :checklist_items ])
    render(@board.agent? ? "boards/agent_show" : "boards/show")
  end

  # POST /boards/1/lists/1/cards
  def create
    board = Board.find(params.expect(:board_id))
    list = board.lists.find(params.expect(:list_id))
    @card = list.cards.new(params.expect(card: [ :title, :due_date ]))
    @card.position = list.cards.maximum(:position).to_i + 1
    @card.status = @card.status_in(list)

    if @card.save
      redirect_to board, status: :see_other
    else
      redirect_to board, alert: @card.errors.full_messages.to_sentence, status: :see_other
    end
  end

  # PATCH /cards/1
  def update
    attributes = params.expect(card: [ :title, :description, :due_date, label_ids: [], member_ids: [] ])
    board = @card.board
    attributes[:label_ids] = board.labels.where(id: attributes[:label_ids]).ids if attributes.key?(:label_ids)
    attributes[:member_ids] = board.members.where(id: attributes[:member_ids]).ids if attributes.key?(:member_ids)

    if @card.update(attributes)
      @card.touch unless @card.saved_changes? # label/member changes alone don't bump updated_at
      redirect_to @card, status: :see_other
    else
      redirect_to @card, alert: @card.errors.full_messages.to_sentence, status: :see_other
    end
  end

  # DELETE /cards/1
  def destroy
    list = @card.list
    @card.destroy!
    list.reorder_cards!

    redirect_to list.board, notice: "Kart silindi.", status: :see_other
  end

  # PATCH /cards/1/move
  def move
    target_list = @card.list.board.lists.find(params.expect(:list_id))
    source_list = @card.list

    Card.transaction do
      ids = target_list.cards.where.not(id: @card.id).pluck(:id)
      index = (params.expect(:position).to_i - 1).clamp(0, ids.size)
      ids.insert(index, @card.id)

      @card.update!(list: target_list, status: @card.status_in(target_list))
      @card.touch unless @card.saved_changes? # a reorder within the same list still wakes the card
      target_list.reorder_cards!(ids)
      source_list.reorder_cards! unless source_list == target_list
    end

    head :ok
  rescue ActiveRecord::RecordInvalid
    head :unprocessable_content
  end

  private
    def set_card
      @card = Card.find(params.expect(:id))
    end
end
