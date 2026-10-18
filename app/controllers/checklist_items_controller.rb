class ChecklistItemsController < ApplicationController
  before_action :set_card
  before_action :set_item, only: %i[ update destroy ]

  # POST /cards/1/checklist_items
  def create
    item = @card.checklist_items.new(params.expect(checklist_item: [ :content ]))

    if item.save
      redirect_to @card, status: :see_other
    else
      redirect_to @card, alert: item.errors.full_messages.to_sentence, status: :see_other
    end
  end

  # PATCH /cards/1/checklist_items/1
  def update
    @item.update!(params.expect(checklist_item: [ :done ]))
    redirect_to @card, status: :see_other
  end

  # DELETE /cards/1/checklist_items/1
  def destroy
    @item.destroy!
    redirect_to @card, status: :see_other
  end

  private
    def set_card
      @card = Card.find(params.expect(:card_id))
    end

    def set_item
      @item = @card.checklist_items.find(params.expect(:id))
    end
end
