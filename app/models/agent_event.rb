class AgentEvent < ApplicationRecord
  belongs_to :card
  belongs_to :actor, class_name: "Member", optional: true

  validates :kind, presence: true
end
