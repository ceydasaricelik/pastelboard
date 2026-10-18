class CardMember < ApplicationRecord
  belongs_to :card
  belongs_to :member
end
