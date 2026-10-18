class AddCollaborationFeatures < ActiveRecord::Migration[8.1]
  def change
    add_column :lists, :color, :string

    create_table :labels do |t|
      t.references :board, null: false, foreign_key: true
      t.string :name, null: false
      t.string :color, null: false
      t.timestamps
    end

    create_table :card_labels do |t|
      t.references :card, null: false, foreign_key: true
      t.references :label, null: false, foreign_key: true
      t.timestamps
      t.index [ :card_id, :label_id ], unique: true
    end

    create_table :members do |t|
      t.references :board, null: false, foreign_key: true
      t.string :name, null: false
      t.string :color, null: false
      t.timestamps
    end

    create_table :card_members do |t|
      t.references :card, null: false, foreign_key: true
      t.references :member, null: false, foreign_key: true
      t.timestamps
      t.index [ :card_id, :member_id ], unique: true
    end

    create_table :checklist_items do |t|
      t.references :card, null: false, foreign_key: true
      t.string :content, null: false
      t.boolean :done, null: false, default: false
      t.integer :position
      t.timestamps
    end

    reversible do |direction|
      direction.up { backfill_existing_boards }
    end
  end

  private
    # Gives boards created before this migration their default labels and lists a color.
    def backfill_existing_boards
      List.reset_column_information
      Label.reset_column_information

      Board.find_each do |board|
        board.create_default_labels if board.labels.none?
        board.lists.where(color: nil).find_each { |list| list.update_columns(color: list.send(:pick_color)) }
      end
    end
end
