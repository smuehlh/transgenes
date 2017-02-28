class AddSelectByToEnhancedGenes < ActiveRecord::Migration
  def change
    add_column :enhanced_genes, :select_by, :string
  end
end
