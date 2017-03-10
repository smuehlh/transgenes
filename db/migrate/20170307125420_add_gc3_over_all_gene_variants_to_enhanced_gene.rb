class AddGc3OverAllGeneVariantsToEnhancedGene < ActiveRecord::Migration
  def change
    add_column :enhanced_genes, :gc3_over_all_gene_variants, :text
  end
end
