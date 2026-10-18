class Member < ApplicationRecord
  COLORS = %w[ pink sky emerald amber violet teal ].freeze

  belongs_to :board
  has_many :card_members, dependent: :destroy
  has_many :cards, through: :card_members

  validates :name, presence: true

  before_validation { self.color ||= COLORS.sample }

  def initials
    name.split.map(&:first).first(2).join.upcase
  end
end
