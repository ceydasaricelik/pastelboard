class CreateCards < ActiveRecord::Migration[8.1]
  def change
    create_table :cards do |t|
      t.string :title
      t.text :description
      t.datetime :due_date
      t.integer :position
      t.integer :status, default: 0, null: false
      t.references :list, null: false, foreign_key: true

      t.timestamps
    end
  end
end
