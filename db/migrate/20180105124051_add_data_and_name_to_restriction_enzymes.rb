class AddDataAndNameToRestrictionEnzymes < ActiveRecord::Migration
  def change
    add_column :restriction_enzymes, :data, :text
    add_column :restriction_enzymes, :name, :string
  end
end
