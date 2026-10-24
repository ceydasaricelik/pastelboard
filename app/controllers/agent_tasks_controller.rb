class AgentTasksController < ApplicationController
  # POST /boards/1/agent_tasks — a new task in the pool; every line of the criteria becomes a checklist item.
  def create
    board = Board.agent.find(params.expect(:board_id))
    attributes = params.expect(agent_task: [ :title, :description, :criteria ])
    criteria = attributes[:criteria].to_s.lines.map { |line| line.strip.sub(/\A[-•*]\s+/, "") }.reject(&:blank?)

    if attributes[:title].blank?
      redirect_to board, alert: "Görev başlığı boş olamaz.", status: :see_other
    elsif criteria.empty?
      redirect_to board, alert: "En az bir kabul kriteri yaz (her satır bir kriter).", status: :see_other
    else
      create_card(board, attributes, criteria)
      redirect_to board, notice: "Görev havuza eklendi.", status: :see_other
    end
  end

  private
    def create_card(board, attributes, criteria)
      Card.transaction do
        pool = board.agent_list(:open)
        card = pool.cards.create!(title: attributes[:title].strip, description: attributes[:description].presence,
                                  agent_state: :open, position: pool.cards.maximum(:position).to_i + 1)
        criteria.each { |content| card.checklist_items.create!(content: content) }
        card.log_event("created", "Görev havuza eklendi.")
      end
    end
end
