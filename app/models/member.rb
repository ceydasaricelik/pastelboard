class Member < ApplicationRecord
  COLORS = %w[ pink sky emerald amber violet teal ].freeze

  belongs_to :board
  has_many :card_members, dependent: :destroy
  has_many :cards, through: :card_members

  enum :kind, { human: 0, agent: 1 }, default: :human
  enum :role, { worker: 0, mentor: 1 }

  validates :name, presence: true

  before_validation { self.color ||= COLORS.sample }

  def initials
    name.split.map(&:first).first(2).join.upcase
  end

  # An agent's notebook: each lesson a mentor taught it ends up in its next prompt.
  def add_lesson!(lesson)
    lesson = lesson.to_s.strip
    return if lesson.blank? || lessons.to_s.lines.map(&:strip).include?("- #{lesson}")

    update!(lessons: [ lessons.presence, "- #{lesson}" ].compact.join("\n"))
  end
end
