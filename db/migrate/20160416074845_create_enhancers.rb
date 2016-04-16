class CreateEnhancers < ActiveRecord::Migration
  def change
    create_table :enhancers do |t|
      t.text :data

      t.timestamps null: false
    end
  end
end
