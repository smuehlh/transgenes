class AddStayInSubboxFor6FoldsToEnhancedGene < ActiveRecord::Migration
  def change
    add_column :enhanced_genes, :stay_in_subbox_for_6folds, :boolean
  end
end
