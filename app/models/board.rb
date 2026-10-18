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

  validates :name, presence: true

  after_create :create_default_labels

  def create_default_labels
    DEFAULT_LABELS.each { |name, color| labels.create!(name: name, color: color) }
  end
end
