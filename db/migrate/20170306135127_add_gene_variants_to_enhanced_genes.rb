class AddGeneVariantsToEnhancedGenes < ActiveRecord::Migration
  def change
    add_column :enhanced_genes, :gene_variants, :text
  end
end
