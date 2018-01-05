class RemoveToKeepAndToAvoidFromRestrictionEnzymes < ActiveRecord::Migration
  def change
    remove_column :restriction_enzymes, :to_keep, :text
    remove_column :restriction_enzymes, :to_avoid, :text
  end
end
