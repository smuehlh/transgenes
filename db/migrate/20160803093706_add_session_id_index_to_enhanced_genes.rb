class AddSessionIdIndexToEnhancedGenes < ActiveRecord::Migration
  def change
    add_index :enhanced_genes, :session_id
  end
end
