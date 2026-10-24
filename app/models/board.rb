class Board < ApplicationRecord
  DEFAULT_LABELS = {
    "Acil" => "red",
    "Tasarım" => "purple",
    "Geliştirme" => "blue",
    "Pazarlama" => "orange",
    "Test" => "green",
    "Doküman" => "yellow"
  }.freeze

  has_many :lists, -> { order(position: :asc) }, dependent: :destroy
  has_many :labels, -> { order(:id) }, dependent: :destroy
  has_many :members, -> { order(:name) }, dependent: :destroy

  enum :kind, { human: 0, agent: 1 }, default: :human

  validates :name, presence: true

  after_create :create_default_labels

  # Creates the fixed lists of an agent board, leaving the ones that exist alone.
  def ensure_agent_lists!
    List::AGENT_STATE_LISTS.each_value.with_index(1) do |name, position|
      lists.find_or_create_by!(name: name) { |list| list.position = position }
    end
  end

  def agent_list(state)
    lists.find_by!(name: List::AGENT_STATE_LISTS.fetch(state.to_s))
  end

  def create_default_labels
    DEFAULT_LABELS.each { |name, color| labels.create!(name: name, color: color) }
  end
end
