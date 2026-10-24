class ApprovalsController < ApplicationController
  # POST /cards/1/approval — a person accepts the card as it is and moves it to Done.
  def create
    card = Card.find(params.expect(:card_id))
    AgentBoards::HumanActions.approve(card)

    redirect_to card, notice: "Kart onaylandı ve Done'a taşındı.", status: :see_other
  rescue ArgumentError => error
    redirect_to card, alert: error.message, status: :see_other
  end
end
