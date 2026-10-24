class AddAgentBoard < ActiveRecord::Migration[8.1]
  def change
    add_column :boards, :kind, :integer, null: false, default: 0

    add_column :members, :kind, :integer, null: false, default: 0
    add_column :members, :role, :integer
    add_column :members, :model, :string
    add_column :members, :lessons, :text

    add_column :cards, :agent_state, :integer
    add_reference :cards, :assignee, foreign_key: { to_table: :members, on_delete: :nullify }
    add_column :cards, :attempts, :integer, null: false, default: 0
    add_column :cards, :output, :text
    add_column :cards, :feedback, :text

    create_table :agent_events do |t|
      t.references :card, null: false, foreign_key: true
      t.references :actor, foreign_key: { to_table: :members, on_delete: :nullify }
      t.string :kind, null: false
      t.text :message
      t.jsonb :data, null: false, default: {}
      t.timestamps
    end
  end
end
