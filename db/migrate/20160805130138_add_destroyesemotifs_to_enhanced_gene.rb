class AddDestroyesemotifsToEnhancedGene < ActiveRecord::Migration
  def change
    add_column :enhanced_genes, :destroy_ese_motifs, :boolean
  end
end
