class HintsController < ApplicationController
  # POST /cards/1/hint — a person helps a card the agents handed over and sends it back to its worker.
  def create
    card = Card.find(params.expect(:card_id))
    hint = params[:hint].to_s.strip

    if hint.blank?
      redirect_to card, alert: "İpucu boş olamaz.", status: :see_other
    else
      AgentBoards::HumanActions.give_hint(card, hint)
      redirect_to card, notice: "İpucu eklendi; kart düzeltmeye döndü.", status: :see_other
    end
  rescue ArgumentError => error
    redirect_to card, alert: error.message, status: :see_other
  end
end
