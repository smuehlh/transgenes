class AddSessionidToEnhancedGenes < ActiveRecord::Migration
  def change
    add_column :enhanced_genes, :session_id, :string
  end
end
