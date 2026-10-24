class AddGuidelinesToBoards < ActiveRecord::Migration[8.1]
  def change
    add_column :boards, :guidelines, :text
  end
end
