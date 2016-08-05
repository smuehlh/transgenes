class CreateEses < ActiveRecord::Migration
  def change
    create_table :eses do |t|
      t.text :data
      t.string :session_id

      t.timestamps null: false
    end
    add_index :eses, :session_id
  end
end
