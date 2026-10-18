class Label < ApplicationRecord
  COLORS = %w[ red purple blue orange green yellow ].freeze

  belongs_to :board
  has_many :card_labels, dependent: :destroy
  has_many :cards, through: :card_labels

  validates :name, presence: true
  validates :color, inclusion: { in: COLORS }
end
