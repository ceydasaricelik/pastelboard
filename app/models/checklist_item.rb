class ChecklistItem < ApplicationRecord
  belongs_to :card, touch: true

  validates :content, presence: true

  before_create { self.position ||= card.checklist_items.maximum(:position).to_i + 1 }
end
