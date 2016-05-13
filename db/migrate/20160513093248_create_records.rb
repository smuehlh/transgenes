class CreateRecords < ActiveRecord::Migration
  def change
    create_table :records do |t|
      t.integer :line
      t.string :data
      t.integer :enhancer_id

      t.timestamps null: false
    end
  end
end
