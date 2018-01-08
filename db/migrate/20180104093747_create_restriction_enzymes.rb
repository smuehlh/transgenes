class CreateRestrictionEnzymes < ActiveRecord::Migration
  def change
    create_table :restriction_enzymes do |t|
      t.text :to_keep
      t.text :to_avoid

      t.timestamps null: false
    end
  end
end
